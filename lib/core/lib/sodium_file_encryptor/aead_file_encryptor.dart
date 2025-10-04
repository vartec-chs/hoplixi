import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';
import 'package:sodium/sodium.dart';

/// Custom exception for cryptographic errors
class CryptoException implements Exception {
  final String message;
  const CryptoException(this.message);

  @override
  String toString() => 'CryptoException: $message';
}

/// Progress information for encryption/decryption operations
class CryptoProgress {
  /// Total bytes to process
  final int totalBytes;

  /// Bytes processed so far
  final int processedBytes;

  /// Progress as a percentage (0.0 to 1.0)
  double get progress => totalBytes > 0 ? processedBytes / totalBytes : 0.0;

  /// Progress as a percentage (0 to 100)
  int get progressPercent => (progress * 100).round();

  const CryptoProgress({
    required this.totalBytes,
    required this.processedBytes,
  });

  @override
  String toString() =>
      'CryptoProgress(${progressPercent}% - $processedBytes/$totalBytes bytes)';
}

/// AEAD file encryptor using libsodium's XChaCha20-Poly1305 secretstream.
///
/// This class provides streaming authenticated encryption for files of any size
/// using ChaCha20-Poly1305 AEAD cipher in secretstream mode.
///
/// **IMPORTANT**: Before using this class, you MUST initialize libsodium:
/// ```dart
/// final sodium = await SodiumInit.init();
/// ```
///
/// **Security Note**: The encryption key must be stored securely. Consider using
/// secure storage mechanisms provided by your platform. Never hardcode keys or
/// store them in plaintext.
///
/// Features:
/// - Streaming encryption/decryption (does not load entire file into memory)
/// - Authenticated encryption with XChaCha20-Poly1305
/// - Custom header with file metadata (fileId, extension)
/// - Automatic cleanup on errors (removes partial files)
/// - Configurable chunk size for performance tuning
class AeadFileEncryptor {
  // Magic bytes to identify encrypted files (4 bytes)
  static const int _magicValue = 0x53434146; // "SCAF" in hex

  // Protocol version (1 byte)
  static const int _version = 1;

  // Algorithm identifier (1 byte) - 1 = ChaCha20-Poly1305
  static const int _algorithmId = 1;

  // KDF context for header authentication (exactly 8 bytes required by libsodium)
  static const String _kdfContext = 'HEADAUTH';

  // Maximum metadata size (fileId + fileExt + length bytes)
  // Must be less than minimum chunk size to avoid splitting
  static const int _maxMetadataSize =
      512; // fileIdLen(1) + fileId(255) + extLen(1) + ext(255) = 512

  final Sodium _sodium;
  final SecureKey _key;

  /// Creates an instance with an existing key.
  ///
  /// The [key] must be exactly 32 bytes (256 bits).
  /// The [sodium] instance must be initialized before creating the encryptor.
  ///
  /// Throws [ArgumentError] if key size is invalid.
  AeadFileEncryptor.fromKey(this._sodium, SecureKey key) : _key = key {
    if (_key.length != _sodium.crypto.secretStream.keyBytes) {
      throw ArgumentError(
        'Key must be ${_sodium.crypto.secretStream.keyBytes} bytes, got ${_key.length}',
      );
    }
  }

  /// Generates a new random encryption key.
  ///
  /// Returns a [SecureKey] of 32 bytes suitable for ChaCha20-Poly1305.
  ///
  /// **Security Note**: Store this key securely! Loss of the key means
  /// encrypted data cannot be recovered.
  static SecureKey generateKey(Sodium sodium) {
    return sodium.crypto.secretStream.keygen();
  }

  /// Encrypts a file using streaming ChaCha20-Poly1305 AEAD.
  ///
  /// Parameters:
  /// - [input]: Source file to encrypt
  /// - [output]: Destination file for encrypted data
  /// - [fileId]: Identifier for the file (stored in header, authenticated)
  /// - [fileExtension]: Optional file extension (e.g., "txt", "pdf")
  /// - [chunkSize]: Size of chunks for streaming (default: 64KB)
  /// - [onProgress]: Optional callback for progress updates
  ///
  /// The output file format:
  /// ```
  /// [Custom Header (6 bytes)] [MAC Tag (32 bytes)] [SecretStream Header (24 bytes)] [Encrypted Metadata Chunk] [Encrypted Data Chunks]
  /// ```
  ///
  /// Custom Header format (6 bytes):
  /// ```
  /// magic(4) | version(1) | algorithm(1)
  /// ```
  ///
  /// The custom header is authenticated with HMAC-SHA512-256 using a derived key.
  /// This ensures header integrity before attempting decryption.
  ///
  /// The fileId and fileExtension are encrypted as the first message chunk,
  /// ensuring they are authenticated by the AEAD scheme.
  ///
  /// The [onProgress] callback receives [CryptoProgress] updates during encryption.
  ///
  /// Throws [CryptoException] on encryption errors.
  /// Throws [FileSystemException] on I/O errors.
  Future<void> encryptFile({
    required File input,
    required File output,
    required String fileId,
    String? fileExtension,
    int chunkSize = 64 * 1024,
    void Function(CryptoProgress progress)? onProgress,
  }) async {
    if (!await input.exists()) {
      throw CryptoException('Input file does not exist: ${input.path}');
    }

    if (chunkSize <= 0) {
      throw ArgumentError('chunkSize must be positive');
    }

    // Ensure chunk size is large enough to fit metadata in a single chunk
    if (chunkSize < _maxMetadataSize + 256) {
      throw ArgumentError(
        'chunkSize must be at least ${_maxMetadataSize + 256} bytes '
        'to ensure metadata fits in a single chunk',
      );
    }

    IOSink? outputSink;

    try {
      // Get file size for progress tracking
      final fileSize = await input.length();
      int processedBytes = 0;

      // Report initial progress
      onProgress?.call(CryptoProgress(totalBytes: fileSize, processedBytes: 0));

      // Prepare file metadata
      final fileIdBytes = utf8.encode(fileId);
      final fileExtBytes = utf8.encode(fileExtension ?? '');

      if (fileIdBytes.length > 255) {
        throw CryptoException('fileId too long (max 255 bytes)');
      }
      if (fileExtBytes.length > 255) {
        throw CryptoException('fileExtension too long (max 255 bytes)');
      }

      // Create output file
      outputSink = output.openWrite();

      // Write custom header (plaintext, will be authenticated with MAC)
      final customHeader = _buildCustomHeader();

      // Derive a sub-key for header authentication (context must be exactly 8 bytes)
      final macKey = _sodium.crypto.kdf.deriveFromKey(
        masterKey: _key,
        context: _kdfContext, // Exactly 8 bytes: 'HEADAUTH'
        subkeyId: BigInt.from(1),
        subkeyLen: _sodium.crypto.auth.keyBytes,
      );

      // Compute MAC tag for header authentication
      final tag = _sodium.crypto.auth.call(message: customHeader, key: macKey);

      // Write header and its MAC tag
      outputSink.add(customHeader);
      outputSink.add(tag); // Protects header integrity

      // Build metadata chunk (to be encrypted as first message)
      final metadataChunk = _buildMetadataChunk(fileIdBytes, fileExtBytes);

      // Create combined stream: metadata first, then file content
      final inputStream = input.openRead();

      // Combine metadata and file content using async* generator
      Stream<List<int>> combinedStream() async* {
        yield metadataChunk;
        processedBytes += metadataChunk.length;

        await for (final chunk in inputStream) {
          yield chunk;
          processedBytes += chunk.length;

          // Report progress during reading
          onProgress?.call(
            CryptoProgress(
              totalBytes: fileSize,
              processedBytes: processedBytes,
            ),
          );
        }
      }

      final encryptedStream = _sodium.crypto.secretStream.pushChunked(
        messageStream: combinedStream(),
        key: _key,
        chunkSize: chunkSize,
      );

      // Write encrypted chunks to output (includes secretstream header + encrypted data)
      await for (final chunk in encryptedStream) {
        outputSink.add(chunk);
      }

      // Report final progress
      onProgress?.call(
        CryptoProgress(totalBytes: fileSize, processedBytes: fileSize),
      );

      await outputSink.flush();
      await outputSink.close();
    } catch (e) {
      // Clean up partial file on error
      await outputSink?.close();
      if (await output.exists()) {
        await output.delete();
      }

      if (e is CryptoException) {
        rethrow;
      }
      throw CryptoException('Encryption failed: $e');
    }
  }

  /// Decrypts a file encrypted with [encryptFile].
  ///
  /// Parameters:
  /// - [input]: Encrypted source file
  /// - [output]: Destination file or directory for decrypted data
  /// - [expectedFileId]: Optional file ID to verify (throws if mismatch)
  /// - [useOriginalExtension]: If true, append original extension to output
  /// - [chunkSize]: Size of chunks for streaming (default: 64KB)
  /// - [onProgress]: Optional callback for progress updates
  ///
  /// Returns the file extension stored in the encrypted file (or empty string).
  ///
  /// If [useOriginalExtension] is true:
  /// - If [output] is a directory: creates `<output>/<fileId>.<ext>`
  /// - If [output] is a file: writes to `<output>.<ext>`
  ///
  /// The [onProgress] callback receives [CryptoProgress] updates during decryption.
  ///
  /// Throws [CryptoException] on decryption/verification errors.
  /// Throws [FileSystemException] on I/O errors.
  /// Throws [FormatException] on invalid file format.
  Future<String> decryptFile({
    required File input,
    required File output,
    String? expectedFileId,
    bool useOriginalExtension = false,
    int chunkSize = 64 * 1024,
    void Function(CryptoProgress progress)? onProgress,
  }) async {
    if (!await input.exists()) {
      throw CryptoException('Input file does not exist: ${input.path}');
    }

    if (chunkSize <= 0) {
      throw ArgumentError('chunkSize must be positive');
    }

    // Ensure chunk size is large enough to fit metadata in a single chunk
    if (chunkSize < _maxMetadataSize + 256) {
      throw ArgumentError(
        'chunkSize must be at least ${_maxMetadataSize + 256} bytes '
        'to ensure metadata fits in a single chunk',
      );
    }

    File? actualOutputFile;
    IOSink? outputSink;
    String? fileId;
    String? fileExtension;

    try {
      // Get encrypted file size for progress tracking
      final encryptedFileSize = await input.length();
      int processedBytes = 0;

      // Report initial progress
      onProgress?.call(
        CryptoProgress(totalBytes: encryptedFileSize, processedBytes: 0),
      );

      // Read and verify custom header
      final inputFile = await input.open();
      final customHeaderSize = await _readAndVerifyCustomHeader(inputFile);
      await inputFile.close();

      // Read encrypted stream starting after custom header
      // The secretstream will automatically read its 24-byte header
      final encryptedStream = input.openRead(customHeaderSize);

      // Decrypt using secretstream
      final decryptedStream = _sodium.crypto.secretStream.pullChunked(
        cipherStream: encryptedStream,
        key: _key,
        chunkSize: chunkSize,
      );

      // First chunk contains metadata - read it separately
      bool isFirstChunk = true;

      await for (final chunk in decryptedStream) {
        processedBytes += chunk.length;

        if (isFirstChunk) {
          // Parse metadata from first decrypted chunk
          final metadata = _parseMetadataChunk(chunk);
          fileId = metadata['fileId'] as String;
          fileExtension = metadata['fileExt'] as String;
          final contentStartOffset = metadata['contentStartOffset'] as int;

          // Verify expected file ID if provided
          if (expectedFileId != null && fileId != expectedFileId) {
            throw CryptoException(
              'File ID mismatch: expected "$expectedFileId", got "$fileId"',
            );
          }

          // Determine actual output file path
          actualOutputFile = await _resolveOutputFile(
            output,
            fileId,
            fileExtension,
            useOriginalExtension,
          );

          // Create output file
          outputSink = actualOutputFile.openWrite();

          // Write any remaining data from first chunk (after metadata)
          if (contentStartOffset < chunk.length) {
            outputSink.add(chunk.sublist(contentStartOffset));
          }

          isFirstChunk = false;
        } else {
          // Write subsequent chunks directly
          outputSink!.add(chunk);
        }

        // Report progress
        onProgress?.call(
          CryptoProgress(
            totalBytes: encryptedFileSize,
            processedBytes: processedBytes,
          ),
        );
      }

      if (isFirstChunk) {
        throw CryptoException('Empty encrypted stream - no data found');
      }

      // Report final progress
      onProgress?.call(
        CryptoProgress(
          totalBytes: encryptedFileSize,
          processedBytes: encryptedFileSize,
        ),
      );

      await outputSink!.flush();
      await outputSink.close();

      return fileExtension ?? '';
    } on InvalidHeaderException catch (e) {
      // Clean up partial file on error
      await outputSink?.close();
      if (actualOutputFile != null && await actualOutputFile.exists()) {
        await actualOutputFile.delete();
      }
      throw CryptoException('Invalid secretstream header: $e');
    } on StreamClosedEarlyException catch (e) {
      // Clean up partial file on error
      await outputSink?.close();
      if (actualOutputFile != null && await actualOutputFile.exists()) {
        await actualOutputFile.delete();
      }
      throw CryptoException('Stream ended prematurely (corrupted data): $e');
    } on SodiumException catch (e) {
      // Clean up partial file on error
      await outputSink?.close();
      if (actualOutputFile != null && await actualOutputFile.exists()) {
        await actualOutputFile.delete();
      }
      throw CryptoException('Decryption verification failed: $e');
    } catch (e) {
      // Clean up partial file on any error
      await outputSink?.close();
      if (actualOutputFile != null && await actualOutputFile.exists()) {
        await actualOutputFile.delete();
      }

      if (e is CryptoException || e is FormatException) {
        rethrow;
      }
      throw CryptoException('Decryption failed: $e');
    }
  }

  /// Builds the minimal custom header (plaintext, will be MAC-authenticated).
  ///
  /// Custom header format: magic(4) | version(1) | algorithm(1)
  /// Total: 6 bytes
  ///
  /// The header is protected by HMAC-SHA512-256 to ensure integrity.
  Uint8List _buildCustomHeader() {
    final header = Uint8List(6);
    var offset = 0;

    // Magic number (4 bytes)
    header.buffer.asByteData().setUint32(offset, _magicValue, Endian.big);
    offset += 4;

    // Version (1 byte)
    header[offset++] = _version;

    // Algorithm (1 byte)
    header[offset++] = _algorithmId;

    return header;
  }

  /// Builds the metadata chunk to be encrypted as the first message.
  ///
  /// Metadata format: fileIdLen(1) | fileId | fileExtLen(1) | fileExt
  Uint8List _buildMetadataChunk(List<int> fileIdBytes, List<int> fileExtBytes) {
    final metadataSize = 1 + fileIdBytes.length + 1 + fileExtBytes.length;
    final metadata = Uint8List(metadataSize);
    var offset = 0;

    // File ID length and data
    metadata[offset++] = fileIdBytes.length;
    metadata.setRange(offset, offset + fileIdBytes.length, fileIdBytes);
    offset += fileIdBytes.length;

    // File extension length and data
    metadata[offset++] = fileExtBytes.length;
    metadata.setRange(offset, offset + fileExtBytes.length, fileExtBytes);

    return metadata;
  }

  /// Reads and verifies the custom header, returns its size (including MAC).
  ///
  /// Verifies the MAC of the header before proceeding with decryption.
  /// This prevents processing of tampered or corrupted files early.
  Future<int> _readAndVerifyCustomHeader(RandomAccessFile file) async {
    try {
      // Read magic number
      var magicBytes = await file.read(4);
      if (magicBytes.length < 4) {
        throw FormatException('File too short to contain valid header');
      }

      final magic = Uint8List.fromList(
        magicBytes,
      ).buffer.asByteData().getUint32(0, Endian.big);

      if (magic != _magicValue) {
        throw FormatException(
          'Invalid magic number: expected 0x${_magicValue.toRadixString(16)}, '
          'got 0x${magic.toRadixString(16)}',
        );
      }

      // Read version
      final versionBytes = await file.read(1);
      if (versionBytes.isEmpty) {
        throw FormatException('Unexpected end of file reading version');
      }
      final version = versionBytes[0];

      if (version != _version) {
        throw FormatException('Unsupported version: $version');
      }

      // Read algorithm
      final algBytes = await file.read(1);
      if (algBytes.isEmpty) {
        throw FormatException('Unexpected end of file reading algorithm');
      }
      final algorithm = algBytes[0];

      if (algorithm != _algorithmId) {
        throw FormatException('Unsupported algorithm: $algorithm');
      }

      // Build the header for MAC verification
      final customHeader = Uint8List(6);
      customHeader.buffer.asByteData().setUint32(0, magic, Endian.big);
      customHeader[4] = version;
      customHeader[5] = algorithm;

      // Read MAC tag (32 bytes for HMAC-SHA512-256)
      final macTagBytes = await file.read(_sodium.crypto.auth.bytes);
      if (macTagBytes.length < _sodium.crypto.auth.bytes) {
        throw FormatException('File too short to contain MAC tag');
      }
      final macTag = Uint8List.fromList(macTagBytes);

      // Derive the same MAC key used during encryption (context must be exactly 8 bytes)
      final macKey = _sodium.crypto.kdf.deriveFromKey(
        masterKey: _key,
        context: _kdfContext, // Exactly 8 bytes: 'HEADAUTH'
        subkeyId: BigInt.from(1),
        subkeyLen: _sodium.crypto.auth.keyBytes,
      );

      // Verify MAC
      final isValid = _sodium.crypto.auth.verify(
        tag: macTag,
        message: customHeader,
        key: macKey,
      );

      if (!isValid) {
        throw FormatException(
          'MAC verification failed: header has been tampered with or file is corrupted',
        );
      }

      // Custom header (6 bytes) + MAC tag (32 bytes) = 38 bytes total
      return 6 + _sodium.crypto.auth.bytes;
    } on FormatException {
      rethrow;
    } catch (e) {
      throw FormatException('Failed to read custom header: $e');
    }
  }

  /// Parses the metadata from the first decrypted chunk.
  ///
  /// Note: We validate during encryption that chunkSize > _maxMetadataSize,
  /// ensuring metadata always arrives in a single chunk.
  Map<String, dynamic> _parseMetadataChunk(List<int> chunk) {
    if (chunk.length < 2) {
      throw FormatException('Metadata chunk too short');
    }

    var offset = 0;

    // Read file ID length and data
    final fileIdLen = chunk[offset++];
    if (offset + fileIdLen > chunk.length) {
      throw FormatException('Invalid fileId length in metadata');
    }

    final fileIdBytes = chunk.sublist(offset, offset + fileIdLen);
    offset += fileIdLen;
    final fileId = utf8.decode(fileIdBytes);

    // Read file extension length and data
    if (offset >= chunk.length) {
      throw FormatException('Metadata chunk truncated at fileExt length');
    }
    final fileExtLen = chunk[offset++];

    if (offset + fileExtLen > chunk.length) {
      throw FormatException('Invalid fileExt length in metadata');
    }

    final fileExtBytes = chunk.sublist(offset, offset + fileExtLen);
    offset += fileExtLen;
    final fileExt = utf8.decode(fileExtBytes);

    return {
      'fileId': fileId,
      'fileExt': fileExt,
      'contentStartOffset':
          offset, // Where actual file content begins in this chunk
    };
  }

  /// Resolves the actual output file based on useOriginalExtension setting.
  Future<File> _resolveOutputFile(
    File output,
    String fileId,
    String fileExtension,
    bool useOriginalExtension,
  ) async {
    if (!useOriginalExtension) {
      return output;
    }

    final outputStat = await output.stat();

    if (outputStat.type == FileSystemEntityType.directory) {
      // Output is a directory, create file inside it
      final fileName = fileExtension.isNotEmpty
          ? '$fileId.$fileExtension'
          : fileId;
      return File('${output.path}${Platform.pathSeparator}$fileName');
    } else {
      // Output is a file, append extension
      if (fileExtension.isNotEmpty) {
        return File('${output.path}.$fileExtension');
      }
      return output;
    }
  }
}
