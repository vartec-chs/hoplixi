import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:math';
import 'package:pointycastle/export.dart';

/// Алгоритмы AEAD шифрования
enum Algorithm {
  aesGcm(0x01, 'AES-GCM'),
  chacha20Poly1305(0x02, 'ChaCha20-Poly1305');

  final int value;
  final String name;

  const Algorithm(this.value, this.name);

  static Algorithm fromValue(int value) {
    return Algorithm.values.firstWhere(
      (a) => a.value == value,
      orElse: () => throw FormatException('Неизвестный алгоритм: $value'),
    );
  }
}

/// Класс для потокового шифрования/дешифрования файлов с AEAD
class AeadFileEncryptor {
  // Константы формата
  static const int _magicNumber = 0x41454144; // 'AEAD' в ASCII
  static const int _version = 0x01;
  static const int _nonceLength = 12; // 12 байт для GCM и ChaCha20-Poly1305
  static const int _tagLength = 16; // 16 байт MAC tag
  static const int _keyLength = 32; // 256 бит

  final Uint8List _key;
  final Algorithm _algorithm;

  /// Приватный конструктор
  AeadFileEncryptor._(this._key, this._algorithm) {
    if (_key.length != _keyLength) {
      throw ArgumentError('Ключ должен быть $_keyLength байт');
    }
  }

  /// Создание экземпляра из существующего ключа
  factory AeadFileEncryptor.fromKey(Uint8List key, Algorithm algorithm) {
    return AeadFileEncryptor._(Uint8List.fromList(key), algorithm);
  }

  /// Генерация нового случайного ключа
  static Uint8List generateKey() {
    final secureRandom = FortunaRandom();
    final seedSource = Random.secure();
    final seeds = <int>[];
    for (int i = 0; i < 32; i++) {
      seeds.add(seedSource.nextInt(256));
    }
    secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));

    final key = secureRandom.nextBytes(_keyLength);
    return key;
  }

  /// Шифрование файла
  ///
  /// [input] - входной файл для шифрования
  /// [output] - выходной зашифрованный файл
  /// [fileId] - идентификатор файла (будет включен в заголовок)
  /// [fileExtension] - расширение файла (опционально)
  /// [chunkSize] - размер чанка для обработки (по умолчанию 64KB)
  Future<void> encryptFile({
    required File input,
    required File output,
    required String fileId,
    String? fileExtension,
    int chunkSize = 64 * 1024,
  }) async {
    if (!await input.exists()) {
      throw ArgumentError('Входной файл не существует: ${input.path}');
    }

    final outputSink = output.openWrite();

    try {
      // Генерация nonce
      final nonce = _generateNonce();

      // Подготовка данных заголовка
      final fileIdBytes = utf8.encode(fileId);
      final fileExtBytes = utf8.encode(fileExtension ?? '');

      if (fileIdBytes.length > 255) {
        throw ArgumentError('fileId слишком длинный (макс 255 байт)');
      }
      if (fileExtBytes.length > 255) {
        throw ArgumentError('fileExtension слишком длинное (макс 255 байт)');
      }

      // Формирование заголовка (AAD)
      final header = _buildHeader(nonce, fileIdBytes, fileExtBytes);

      // Запись заголовка в файл
      outputSink.add(header);

      // Инициализация шифра
      final cipher = _createCipher(
        forEncryption: true,
        nonce: nonce,
        aad: header,
      );

      // Чтение всего файла для шифрования
      // Для AEAD нужно шифровать все данные сразу чтобы получить правильный тег
      final inputBytes = await input.readAsBytes();

      // Шифрование с автоматическим добавлением тега
      final encryptedWithTag = _encryptData(cipher, inputBytes);

      // Запись зашифрованных данных + тега
      outputSink.add(encryptedWithTag);

      await outputSink.flush();
    } catch (e) {
      // При ошибке удаляем частично записанный файл
      await outputSink.close();
      if (await output.exists()) {
        await output.delete();
      }
      rethrow;
    } finally {
      await outputSink.close();
    }
  }

  /// Дешифрование файла
  ///
  /// [input] - зашифрованный файл
  /// [output] - выходной дешифрованный файл или директория
  /// [expectedFileId] - ожидаемый ID файла (для проверки)
  /// [useOriginalExtension] - использовать оригинальное расширение из заголовка
  /// [chunkSize] - размер чанка для обработки (по умолчанию 64KB)
  ///
  /// Возвращает расширение файла из заголовка (или пустую строку)
  Future<String> decryptFile({
    required File input,
    required File output,
    String? expectedFileId,
    bool useOriginalExtension = false,
    int chunkSize = 64 * 1024,
  }) async {
    if (!await input.exists()) {
      throw ArgumentError('Входной файл не существует: ${input.path}');
    }

    RandomAccessFile? inputFile;
    IOSink? outputSink;
    File? actualOutputFile = output;

    try {
      inputFile = await input.open(mode: FileMode.read);

      // Чтение и парсинг заголовка
      final headerData = await _readHeader(inputFile);
      final header = headerData['header'] as Uint8List;
      final nonce = headerData['nonce'] as Uint8List;
      final fileId = headerData['fileId'] as String;
      final fileExt = headerData['fileExt'] as String;
      final algorithm = headerData['algorithm'] as Algorithm;

      // Проверка алгоритма
      if (algorithm != _algorithm) {
        throw FormatException(
          'Несоответствие алгоритма: ожидался $_algorithm, получен $algorithm',
        );
      }

      // Проверка fileId если указан
      if (expectedFileId != null && fileId != expectedFileId) {
        throw FormatException(
          'Несоответствие fileId: ожидался $expectedFileId, получен $fileId',
        );
      }

      // Определение выходного файла
      if (useOriginalExtension &&
          await FileSystemEntity.isDirectory(output.path)) {
        final fileName = fileExt.isNotEmpty ? '$fileId.$fileExt' : fileId;
        actualOutputFile = File(
          '${output.path}${Platform.pathSeparator}$fileName',
        );
      } else if (useOriginalExtension && fileExt.isNotEmpty) {
        // Добавляем расширение к файлу
        actualOutputFile = File('${output.path}.$fileExt');
      }

      outputSink = actualOutputFile.openWrite();

      // Инициализация шифра
      final cipher = _createCipher(
        forEncryption: false,
        nonce: nonce,
        aad: header,
      );

      // Получение размера файла и позиции
      final fileSize = await inputFile.length();
      final currentPosition = await inputFile.position();
      final encryptedDataSize = fileSize - currentPosition;

      if (encryptedDataSize < _tagLength) {
        throw FormatException(
          'Файл слишком мал, отсутствует тег аутентификации',
        );
      }

      // Чтение всех зашифрованных данных включая тег
      // Для AEAD нужно передать весь зашифрованный блок + тег
      var bytesProcessed = 0;
      final buffer = Uint8List(chunkSize);
      final List<Uint8List> encryptedChunks = [];

      // Читаем все данные (data + tag)
      while (bytesProcessed < encryptedDataSize) {
        final toRead = (encryptedDataSize - bytesProcessed).clamp(0, chunkSize);
        final bytesRead = await inputFile.readInto(buffer, 0, toRead);
        if (bytesRead == 0) break;

        final chunk = Uint8List.fromList(
          Uint8List.sublistView(buffer, 0, bytesRead),
        );
        encryptedChunks.add(chunk);
        bytesProcessed += bytesRead;
      }

      // Объединяем все чанки
      final allEncrypted = Uint8List(bytesProcessed);
      var offset = 0;
      for (final chunk in encryptedChunks) {
        allEncrypted.setRange(offset, offset + chunk.length, chunk);
        offset += chunk.length;
      }

      // Обрабатываем зашифрованные данные + тег
      final decrypted = _decryptWithTag(cipher, allEncrypted);

      // Записываем дешифрованные данные
      outputSink.add(decrypted);

      await outputSink.flush();
      return fileExt;
    } catch (e) {
      // При ошибке удаляем частично записанный файл
      await outputSink?.close();
      if (actualOutputFile != null && await actualOutputFile.exists()) {
        await actualOutputFile.delete();
      }
      rethrow;
    } finally {
      await inputFile?.close();
      await outputSink?.close();
    }
  }

  /// Генерация случайного nonce
  Uint8List _generateNonce() {
    final secureRandom = FortunaRandom();
    final seedSource = Random.secure();
    final seeds = <int>[];
    for (int i = 0; i < 32; i++) {
      seeds.add(seedSource.nextInt(256));
    }
    secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));

    return secureRandom.nextBytes(_nonceLength);
  }

  /// Построение заголовка файла
  Uint8List _buildHeader(
    Uint8List nonce,
    Uint8List fileIdBytes,
    Uint8List fileExtBytes,
  ) {
    final buffer = BytesBuilder();

    // Magic number (4 байта)
    buffer.add([
      (_magicNumber >> 24) & 0xFF,
      (_magicNumber >> 16) & 0xFF,
      (_magicNumber >> 8) & 0xFF,
      _magicNumber & 0xFF,
    ]);

    // Version (1 байт)
    buffer.addByte(_version);

    // Algorithm (1 байт)
    buffer.addByte(_algorithm.value);

    // Nonce length (1 байт)
    buffer.addByte(nonce.length);

    // Nonce
    buffer.add(nonce);

    // File ID length (1 байт)
    buffer.addByte(fileIdBytes.length);

    // File ID
    buffer.add(fileIdBytes);

    // File extension length (1 байт)
    buffer.addByte(fileExtBytes.length);

    // File extension
    buffer.add(fileExtBytes);

    return buffer.toBytes();
  }

  /// Чтение и парсинг заголовка
  Future<Map<String, dynamic>> _readHeader(RandomAccessFile file) async {
    // Magic number (4 байта)
    final magicBytes = Uint8List(4);
    await file.readInto(magicBytes);
    final magic =
        (magicBytes[0] << 24) |
        (magicBytes[1] << 16) |
        (magicBytes[2] << 8) |
        magicBytes[3];

    if (magic != _magicNumber) {
      throw FormatException(
        'Неверный magic number: 0x${magic.toRadixString(16)}',
      );
    }

    // Version (1 байт)
    final version = (await file.readByte());
    if (version != _version) {
      throw FormatException('Неподдерживаемая версия: $version');
    }

    // Algorithm (1 байт)
    final algorithmValue = (await file.readByte());
    final algorithm = Algorithm.fromValue(algorithmValue);

    // Nonce length (1 байт)
    final nonceLen = (await file.readByte());
    if (nonceLen != _nonceLength) {
      throw FormatException('Неверная длина nonce: $nonceLen');
    }

    // Nonce
    final nonce = Uint8List(nonceLen);
    await file.readInto(nonce);

    // File ID length (1 байт)
    final fileIdLen = (await file.readByte());

    // File ID
    final fileIdBytes = Uint8List(fileIdLen);
    await file.readInto(fileIdBytes);
    final fileId = utf8.decode(fileIdBytes);

    // File extension length (1 байт)
    final fileExtLen = (await file.readByte());

    // File extension
    final fileExtBytes = Uint8List(fileExtLen);
    await file.readInto(fileExtBytes);
    final fileExt = utf8.decode(fileExtBytes);

    // Восстанавливаем полный заголовок для AAD
    final headerBytes = _buildHeader(nonce, fileIdBytes, fileExtBytes);

    return {
      'header': headerBytes,
      'nonce': nonce,
      'fileId': fileId,
      'fileExt': fileExt,
      'algorithm': algorithm,
    };
  }

  /// Создание и инициализация шифра
  dynamic _createCipher({
    required bool forEncryption,
    required Uint8List nonce,
    required Uint8List aad,
  }) {
    final keyParam = KeyParameter(_key);
    final params = AEADParameters(keyParam, _tagLength * 8, nonce, aad);

    switch (_algorithm) {
      case Algorithm.aesGcm:
        final cipher = GCMBlockCipher(AESEngine());
        cipher.init(forEncryption, params);
        return cipher;

      case Algorithm.chacha20Poly1305:
        final cipher = ChaCha20Poly1305(ChaCha7539Engine(), Poly1305());
        cipher.init(forEncryption, params);
        return cipher;
    }
  }

  /// Шифрование данных (возвращает зашифрованные данные + тег)
  Uint8List _encryptData(dynamic cipher, Uint8List plaintext) {
    if (cipher is GCMBlockCipher) {
      // GCM поддерживает метод process
      return cipher.process(plaintext);
    } else if (cipher is ChaCha20Poly1305) {
      // ChaCha20Poly1305 требует использования processBytes + doFinal
      final output = Uint8List(plaintext.length + _tagLength);

      // Обрабатываем данные
      final bytesProcessed = cipher.processBytes(
        plaintext,
        0,
        plaintext.length,
        output,
        0,
      );

      // Финализируем и получаем тег
      final bytesFinalized = cipher.doFinal(output, bytesProcessed);

      // Возвращаем данные + тег
      return Uint8List.sublistView(output, 0, bytesProcessed + bytesFinalized);
    } else {
      throw StateError('Неизвестный тип шифра');
    }
  }

  /// Дешифрование с тегом (для AEAD)
  Uint8List _decryptWithTag(dynamic cipher, Uint8List encryptedWithTag) {
    // encryptedWithTag содержит: зашифрованные данные + тег (тег в конце)
    // AEAD шифры автоматически проверяют тег при дешифровании

    try {
      if (cipher is GCMBlockCipher) {
        // GCM поддерживает метод process
        return cipher.process(encryptedWithTag);
      } else if (cipher is ChaCha20Poly1305) {
        // ChaCha20Poly1305 требует использования processBytes + doFinal
        final dataLength = encryptedWithTag.length - _tagLength;
        final output = Uint8List(dataLength);

        // Обрабатываем зашифрованные данные
        final bytesProcessed = cipher.processBytes(
          encryptedWithTag,
          0,
          encryptedWithTag.length,
          output,
          0,
        );

        // Финализируем с проверкой тега
        final outputFinal = Uint8List(64); // буфер для финальных байт
        final bytesFinalized = cipher.doFinal(outputFinal, 0);

        // Возвращаем только дешифрованные данные
        if (bytesFinalized > 0) {
          return Uint8List.fromList([
            ...output.sublist(0, bytesProcessed),
            ...outputFinal.sublist(0, bytesFinalized),
          ]);
        }
        return Uint8List.sublistView(output, 0, bytesProcessed);
      } else {
        throw StateError('Неизвестный тип шифра');
      }
    } on ArgumentError catch (e) {
      throw FormatException('Ошибка дешифрования: ${e.message}');
    } catch (e) {
      if (e.toString().contains('mac check') ||
          e.toString().contains('InvalidCipherTextException')) {
        throw FormatException(
          'Проверка MAC тега не удалась - данные могли быть изменены',
        );
      }
      rethrow;
    }
  }
}
