import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import 'crypto_keys.dart';

/// Главный класс для шифрования и дешифрования файлов
/// Использует AES-256-CTR + HMAC-SHA256 для безопасного шифрования
class FileEncryptor {
  // Константы формата
  static const String _magicString = 'ENCR'; // 4 байта
  static const int _formatVersion = 1; // 1 байт
  static const int _ivSize = 16; // 16 байт для AES-CTR
  static const int _hmacSize = 32; // 32 байта для HMAC-SHA256
  static const int _headerSize =
      4 + 1 + _ivSize; // magic + version + iv = 21 байт

  /// Глобальный криптографически стойкий генератор случайных чисел
  static final SecureRandom _secureRandom = _createSecureRandom();

  /// Криптографические ключи
  final CryptoKeys keys;

  /// Размер чанка для потоковой обработки (по умолчанию 64 КБ)
  final int chunkSize;

  /// Конструктор
  FileEncryptor({required this.keys, this.chunkSize = 64 * 1024});

  /// Фабричный конструктор с генерацией новых ключей
  factory FileEncryptor.generateKeys({int chunkSize = 64 * 1024}) {
    final keys = CryptoKeys.fromBytes(
      aesKey: _generateAes256Key(),
      hmacKey: _generateHmacKey(),
    );
    return FileEncryptor(keys: keys, chunkSize: chunkSize);
  }

  /// Фабричный конструктор с заданным AES ключом и автогенерацией HMAC ключа
  factory FileEncryptor.fromAesKey({
    required String aesKeyBase64,
    int chunkSize = 64 * 1024,
  }) {
    final keys = CryptoKeys.fromBase64(
      aesKeyBase64: aesKeyBase64,
      hmacKeyBase64: generateHmacKey(), // автогенерация HMAC
    );
    return FileEncryptor(keys: keys, chunkSize: chunkSize);
  }

  /// Фабричный конструктор из base64 ключей
  factory FileEncryptor.fromBase64({
    required String aesKeyBase64,
    required String hmacKeyBase64,
    int chunkSize = 64 * 1024,
  }) {
    final keys = CryptoKeys.fromBase64(
      aesKeyBase64: aesKeyBase64,
      hmacKeyBase64: hmacKeyBase64,
    );
    return FileEncryptor(keys: keys, chunkSize: chunkSize);
  }

  /// Фабричный конструктор из JSON
  factory FileEncryptor.fromJson(
    Map<String, dynamic> json, {
    int chunkSize = 64 * 1024,
  }) {
    final keys = CryptoKeys.fromJson(json);
    return FileEncryptor(keys: keys, chunkSize: chunkSize);
  }

  /// Создание и инициализация Fortuna PRNG
  static SecureRandom _createSecureRandom() {
    final secureRandom = FortunaRandom();

    // Инициализируем Fortuna с помощью Random.secure()
    final random = Random.secure();
    final seeds = <int>[];
    for (int i = 0; i < 32; i++) {
      seeds.add(random.nextInt(256));
    }
    secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));

    return secureRandom;
  }

  /// Генерация AES-256 ключа (приватный метод)
  static Uint8List _generateAes256Key() {
    return _secureRandom.nextBytes(32);
  }

  /// Генерация AES-256 ключа в формате base64 (публичный метод)
  static String generateAes256Key() {
    final keyBytes = _generateAes256Key();
    return base64.encode(keyBytes);
  }

  Uint8List get aesKey => keys.aesKey;

  /// Генерация HMAC ключа (32 байта) - приватный метод
  static Uint8List _generateHmacKey() {
    return _secureRandom.nextBytes(32);
  }

  /// Генерация HMAC ключа в формате base64 (публичный метод)
  static String generateHmacKey() {
    final keyBytes = _generateHmacKey();
    return base64.encode(keyBytes);
  }

  Uint8List get hmacKey => keys.hmacKey;

  /// Генерация IV (16 байт для CTR режима)
  static Uint8List _generateIV() {
    return _secureRandom.nextBytes(_ivSize);
  }

  /// Constant-time сравнение двух массивов байт
  static bool _constantTimeCompare(Uint8List a, Uint8List b) {
    if (a.length != b.length) {
      return false;
    }

    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }

    return result == 0;
  }

  /// Шифрование файла с AES-CTR + HMAC-SHA256 (поддерживает потоковую обработку)
  /// IV генерируется автоматически и сохраняется в заголовке файла
  Future<void> encryptFile({required File input, required File output}) async {
    // Генерируем случайный IV для этого файла
    final iv = _generateIV();

    // Формируем заголовок: magic (4) + version (1) + iv (16) = 21 байт
    final header = BytesBuilder();
    header.add(utf8.encode(_magicString)); // 'ENCR' - 4 байта
    header.add([_formatVersion]); // версия формата - 1 байт
    header.add(iv); // IV - 16 байт

    final headerBytes = header.toBytes();

    // CTR режим поддерживает потоковую обработку
    final cipher = CTRStreamCipher(AESEngine())
      ..init(true, ParametersWithIV(KeyParameter(keys.aesKey), iv));

    // HMAC для аутентификации (покрывает заголовок + зашифрованные данные)
    final hmac = HMac(SHA256Digest(), 64)..init(KeyParameter(keys.hmacKey));

    final outputSink = output.openWrite();

    try {
      // Записываем заголовок в файл
      outputSink.add(headerBytes);

      // Обновляем HMAC заголовком
      hmac.update(headerBytes, 0, headerBytes.length);

      // Читаем и шифруем данные
      final inputStream = input.openRead();

      await for (final chunk in inputStream) {
        final inputChunk = Uint8List.fromList(chunk);
        final outputChunk = Uint8List(inputChunk.length);

        // Шифруем чанк
        cipher.processBytes(inputChunk, 0, inputChunk.length, outputChunk, 0);

        // Обновляем HMAC зашифрованными данными
        hmac.update(outputChunk, 0, outputChunk.length);

        // Записываем зашифрованный чанк
        outputSink.add(outputChunk);
      }

      // Вычисляем финальный HMAC
      final mac = Uint8List(hmac.macSize);
      hmac.doFinal(mac, 0);

      // Записываем HMAC в конец файла
      outputSink.add(mac);

      await outputSink.flush();
    } finally {
      await outputSink.close();
    }
  }

  /// Дешифрование файла с AES-CTR + HMAC-SHA256 (поддерживает потоковую обработку)
  /// IV извлекается из заголовка файла
  /// Оптимизировано: одна проходная операция (одновременно HMAC и дешифрование)
  Future<void> decryptFile({required File input, required File output}) async {
    // Читаем файл для проверки формата и извлечения метаданных
    final fileSize = await input.length();

    if (fileSize < _headerSize + _hmacSize) {
      throw Exception('Файл слишком мал или поврежден');
    }

    // Читаем заголовок
    final raf = await input.open();
    final headerBytes = Uint8List(_headerSize);
    await raf.readInto(headerBytes);

    // Проверяем magic string
    final magic = utf8.decode(headerBytes.sublist(0, 4));
    if (magic != _magicString) {
      await raf.close();
      throw Exception('Неверный формат файла (magic string не совпадает)');
    }

    // Проверяем версию формата
    final version = headerBytes[4];
    if (version != _formatVersion) {
      await raf.close();
      throw Exception('Неподдерживаемая версия формата: $version');
    }

    // Извлекаем IV из заголовка
    final iv = headerBytes.sublist(5, 5 + _ivSize);

    // Вычисляем размер зашифрованных данных
    final encryptedDataSize = fileSize - _headerSize - _hmacSize;

    // Читаем сохраненный HMAC из конца файла
    final savedMac = Uint8List(_hmacSize);
    await raf.setPosition(fileSize - _hmacSize);
    await raf.readInto(savedMac);
    await raf.close();

    // Создаем временный файл для расшифрованных данных
    final tempOutput = File('${output.path}.tmp');

    // Вычисляем HMAC заголовка и зашифрованных данных
    final hmac = HMac(SHA256Digest(), 64)..init(KeyParameter(keys.hmacKey));

    // Обновляем HMAC заголовком
    hmac.update(headerBytes, 0, headerBytes.length);

    // Инициализируем шифр для дешифрования
    final cipher = CTRStreamCipher(AESEngine())
      ..init(false, ParametersWithIV(KeyParameter(keys.aesKey), iv));

    // Одна проходная операция: читаем, обновляем HMAC и дешифруем
    final inputStream = input.openRead(
      _headerSize,
      _headerSize + encryptedDataSize,
    );
    final tempSink = tempOutput.openWrite();

    try {
      await for (final chunk in inputStream) {
        final inputChunk = Uint8List.fromList(chunk);

        // Обновляем HMAC зашифрованными данными
        hmac.update(inputChunk, 0, inputChunk.length);

        // Одновременно дешифруем чанк
        final outputChunk = Uint8List(inputChunk.length);
        cipher.processBytes(inputChunk, 0, inputChunk.length, outputChunk, 0);

        // Записываем расшифрованные данные во временный файл
        tempSink.add(outputChunk);
      }

      await tempSink.flush();
      await tempSink.close();

      // Вычисляем финальный HMAC
      final computedMac = Uint8List(hmac.macSize);
      hmac.doFinal(computedMac, 0);

      // Проверяем HMAC (constant-time сравнение)
      if (!_constantTimeCompare(computedMac, savedMac)) {
        // HMAC не совпал - удаляем временный файл
        if (await tempOutput.exists()) {
          await tempOutput.delete();
        }
        throw Exception(
          'HMAC проверка не пройдена! Данные были изменены или используется неверный ключ.',
        );
      }

      // HMAC проверен успешно - переименовываем временный файл в финальный
      if (await output.exists()) {
        await output.delete();
      }
      await tempOutput.rename(output.path);
    } catch (e) {
      // В случае любой ошибки удаляем временный файл
      if (await tempOutput.exists()) {
        await tempOutput.delete();
      }
      rethrow;
    }
  }

  /// Получить ключи в виде JSON для сохранения
  Map<String, String> toJson() => keys.toJson();

  /// Получить информацию о ключах
  @override
  String toString() => 'FileEncryptor(chunkSize: $chunkSize, keys: $keys)';
}
