/// Экран импорта OTP токенов из QR-кодов
///
/// Поддерживает:
/// - Импорт из изображения (галерея)
/// - Сканирование QR-кода камерой
/// - Парсинг otpauth-migration:// ссылок (Google Authenticator формат)
/// - Множественный выбор токенов для импорта
/// - Предпросмотр импортируемых данных
/// - Пакетное сохранение в БД через TOTPService
///
/// Автоматически конвертирует алгоритмы и типы OTP в формат БД.
/// MD5 не поддерживается и заменяется на SHA1.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/index.dart';
import 'package:hoplixi/core/utils/otp_extractor.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/data_refresh_trigger_provider.dart';
import 'package:hoplixi/hoplixi_store/dto/db_dto.dart';
import 'package:hoplixi/hoplixi_store/providers/service_providers.dart';
import 'package:hoplixi/hoplixi_store/enums/entity_types.dart';

import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:zxing2/qrcode.dart';
import 'package:hoplixi/shared/widgets/button.dart';
import 'package:hoplixi/features/global/screens/image_crop_screen.dart';
import 'package:hoplixi/app/router/routes_path.dart';
import 'package:otp/otp.dart';
import 'dart:async';
import 'package:flutter/services.dart';

class ImportOtpScreen extends ConsumerStatefulWidget {
  const ImportOtpScreen({super.key});

  @override
  ConsumerState<ImportOtpScreen> createState() => _ImportOtpScreenState();
}

class _ImportOtpScreenState extends ConsumerState<ImportOtpScreen> {
  final TextEditingController _controller = TextEditingController();

  List<OtpData> importedOtps = [];
  Set<int> selectedIndices = {};
  Set<int> expandedIndices = {};
  bool isSaving = false;

  // Таймер для обновления TOTP кодов
  Timer? _totpTimer;
  final Map<int, String> _currentCodes = {};
  int _remainingSeconds = 30;

  @override
  void dispose() {
    _controller.dispose();
    _totpTimer?.cancel();
    super.dispose();
  }

  void _startTotpTimer() {
    _totpTimer?.cancel();
    _updateTotpCodes();
    _totpTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateTotpCodes();
    });
  }

  void _updateTotpCodes() {
    if (importedOtps.isEmpty) return;

    final now = DateTime.now();
    final currentSecond = now.second;
    final newRemainingSeconds = 30 - (currentSecond % 30);

    setState(() {
      _remainingSeconds = newRemainingSeconds;

      for (int i = 0; i < importedOtps.length; i++) {
        final otp = importedOtps[i];
        if (otp.type.toUpperCase() == 'TOTP') {
          final timestamp = now.millisecondsSinceEpoch;

          // Определяем алгоритм для генерации
          Algorithm algorithm;
          switch (otp.algorithm.toUpperCase()) {
            case 'SHA256':
              algorithm = Algorithm.SHA256;
              break;
            case 'SHA512':
              algorithm = Algorithm.SHA512;
              break;
            default:
              algorithm = Algorithm.SHA1;
          }

          try {
            // Генерируем TOTP код
            final code = OTP.generateTOTPCodeString(
              otp.secretBase32,
              timestamp,
              interval: 30,
              length: otp.digits,
              algorithm: algorithm,
              isGoogle: true, // Используем формат Google по умолчанию
            );
            _currentCodes[i] = code;
          } catch (e) {
            _currentCodes[i] = '------';
          }
        }
      }
    });
  }

  Future<void> _pickImageAndDecode() async {
    // Шаг 1: Выбираем изображение из галереи
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null && mounted) {
      final bytes = await pickedFile.readAsBytes();

      // Шаг 2: Даём пользователю обрезать изображение
      final cropResult = await context.push(
        AppRoutes.imageCrop,
        extra: ImageCropData(
          imageBytes: bytes,
          sourceName: 'QR-код для импорта OTP',
        ),
      );

      if (cropResult != null && cropResult is CroppedImageResult && mounted) {
        // Шаг 3: Декодируем QR из обрезанного изображения
        final image = img.decodeImage(cropResult.croppedImageBytes);

        if (image != null) {
          final source = RGBLuminanceSource(
            image.width,
            image.height,
            image
                .convert(numChannels: 4)
                .getBytes(order: img.ChannelOrder.abgr)
                .buffer
                .asInt32List(),
          );
          final bitmap = BinaryBitmap(GlobalHistogramBinarizer(source));
          final reader = QRCodeReader();

          try {
            final result = reader.decode(bitmap);
            _importOtp(
              Uint8List.fromList(Uint8List.fromList(result.text.codeUnits)),
            );
            setState(() {
              _controller.text = result.text;
            });
          } catch (e) {
            ToastHelper.error(
              title: 'Не удалось декодировать QR-код',
              description:
                  'Попробуйте обрезать изображение точнее вокруг QR-кода',
            );
          }
        }
      }
    }
  }

  Future<void> _scanQr() async {
    final result = await context.push(AppRoutes.qrScanner);
    if (result != null && result is String) {
      _importOtp(Uint8List.fromList(result.codeUnits));
      setState(() {
        _controller.text = result;
      });
    }
  }

  Future<void> _importOtp(Uint8List decodedBytes) async {
    try {
      final input = utf8.decode(decodedBytes);
      final otpList = parseMigrationUri(input);
      setState(() {
        importedOtps = otpList;
        // Автоматически выбираем все импортированные OTP
        selectedIndices = Set.from(List.generate(otpList.length, (i) => i));
      });

      // Запускаем таймер для TOTP кодов
      _startTotpTimer();

      ToastHelper.success(title: 'Найдено ${otpList.length} OTP записей');
    } catch (e) {
      ToastHelper.error(title: 'Ошибка при импорте', description: '$e');
    }
  }

  void _toggleExpanded(int index) {
    setState(() {
      if (expandedIndices.contains(index)) {
        expandedIndices.remove(index);
      } else {
        expandedIndices.add(index);
      }
    });
  }

  void _toggleSelection(int index) {
    setState(() {
      if (selectedIndices.contains(index)) {
        selectedIndices.remove(index);
      } else {
        selectedIndices.add(index);
      }
    });
  }

  void _selectAll() {
    setState(() {
      selectedIndices = Set.from(List.generate(importedOtps.length, (i) => i));
    });
  }

  void _deselectAll() {
    setState(() {
      selectedIndices.clear();
    });
  }

  Future<void> _copyCodeToClipboard(String code, String issuer) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (mounted) {
      ToastHelper.success(
        title: 'Код скопирован',
        description: 'TOTP код для $issuer скопирован в буфер обмена',
      );
    }
  }

  Future<void> _saveSelectedOtps() async {
    if (selectedIndices.isEmpty) {
      ToastHelper.warning(title: 'Выберите хотя бы один OTP для сохранения');
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final totpService = ref.read(totpServiceProvider);
      int successCount = 0;
      int failCount = 0;

      for (final index in selectedIndices) {
        final otp = importedOtps[index];

        // Конвертируем тип алгоритма
        AlgorithmOtp algorithm;
        switch (otp.algorithm.toUpperCase()) {
          case 'SHA256':
            algorithm = AlgorithmOtp.SHA256;
            break;
          case 'SHA512':
            algorithm = AlgorithmOtp.SHA512;
            break;
          case 'MD5':
            // MD5 не поддерживается, используем SHA1 как fallback
            algorithm = AlgorithmOtp.SHA1;
            break;
          default:
            algorithm = AlgorithmOtp.SHA1;
        }

        // Конвертируем тип OTP
        OtpType type;
        if (otp.type.toUpperCase() == 'HOTP') {
          type = OtpType.hotp;
        } else {
          type = OtpType.totp;
        }

        final createDto = CreateTotpDto(
          issuer: otp.issuer.isNotEmpty ? otp.issuer : null,
          accountName: otp.name.isNotEmpty ? otp.name : null,
          secret: otp.secretBase32,
          algorithm: algorithm,
          digits: otp.digits,
          period: 30, // Стандартный период
          counter: otp.counter > 0 ? otp.counter : null,
          type: type,
        );

        final result = await totpService.createTotp(createDto);
        if (result.success) {
          successCount++;
        } else {
          failCount++;
        }
      }

      if (successCount > 0) {
        ToastHelper.success(
          title: 'Импорт завершён',
          description:
              'Успешно: $successCount${failCount > 0 ? ', Ошибок: $failCount' : ''}',
        );

        // Очищаем список после успешного импорта
        if (failCount == 0 && mounted) {
          setState(() {
            importedOtps.clear();
            selectedIndices.clear();
            _controller.clear();
          });

          // Возвращаемся назад
          if (mounted) {
            DataRefreshHelper.refreshOtp(ref);
            context.pop();
          }
        }
      } else {
        ToastHelper.error(
          title: 'Не удалось импортировать OTP',
          description: 'Все попытки завершились ошибкой',
        );
      }
    } catch (e) {
      ToastHelper.error(title: 'Ошибка при сохранении', description: '$e');
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Импорт OTP'),
        actions: importedOtps.isNotEmpty
            ? [
                if (selectedIndices.length < importedOtps.length)
                  TextButton(
                    onPressed: _selectAll,
                    child: const Text('Выбрать все'),
                  )
                else
                  TextButton(
                    onPressed: _deselectAll,
                    child: const Text('Снять все'),
                  ),
                const SizedBox(width: 8),
              ]
            : null,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(
                4.0,
              ).copyWith(bottom: 80), // Отступ для кнопки
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Кнопки импорта
                  Card(
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Выберите способ импорта',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Builder(
                            builder: (context) {
                              final screenWidth = MediaQuery.of(
                                context,
                              ).size.width;
                              final isMobile = screenWidth <= 450;
                              return isMobile
                                  ? Column(
                                      children: [
                                        SmoothButton(
                                          isFullWidth: true,
                                          label: 'Из изображения',
                                          onPressed: _pickImageAndDecode,
                                          type: SmoothButtonType.outlined,
                                          icon: const Icon(
                                            Icons.image,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        SmoothButton(
                                          isFullWidth: true,
                                          label: 'Сканировать QR',
                                          onPressed: _scanQr,
                                          type: SmoothButtonType.filled,
                                          icon: const Icon(
                                            Icons.qr_code_scanner,
                                            size: 20,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      children: [
                                        Expanded(
                                          child: SmoothButton(
                                            label: 'Из изображения',
                                            onPressed: _pickImageAndDecode,
                                            type: SmoothButtonType.outlined,
                                            icon: const Icon(
                                              Icons.image,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: SmoothButton(
                                            label: 'Сканировать QR',
                                            onPressed: _scanQr,
                                            type: SmoothButtonType.filled,
                                            icon: const Icon(
                                              Icons.qr_code_scanner,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                            },
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.secondaryContainer.withOpacity(
                                0.5,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: colorScheme.secondary.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 20,
                                  color: Colors.redAccent,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Протестировано только с Google Authenticator. Другие приложения могут использовать несовместимые форматы.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSecondaryContainer,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Статистика
                  if (importedOtps.isNotEmpty)
                    Card(
                      elevation: 0,
                      // color: colorScheme.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Найдено записей',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSecondaryContainer,
                                  ),
                                ),
                                Text(
                                  '${importedOtps.length}',
                                  style: theme.textTheme.headlineMedium
                                      ?.copyWith(
                                        color: colorScheme.onSecondaryContainer,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Выбрано',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSecondaryContainer,
                                  ),
                                ),
                                Text(
                                  '${selectedIndices.length}',
                                  style: theme.textTheme.headlineMedium
                                      ?.copyWith(
                                        color: colorScheme.onSecondaryContainer,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 4),

                  // Список OTP
                  if (importedOtps.isEmpty)
                    SizedBox(
                      height: 300, // Фиксированная высота для пустого состояния
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.qr_code_2,
                              size: 80,
                              color: colorScheme.outline.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Нет импортированных OTP',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: colorScheme.outline,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Выберите способ импорта выше',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.outline.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Column(
                      children: List.generate(importedOtps.length, (index) {
                        final otp = importedOtps[index];
                        final isSelected = selectedIndices.contains(index);
                        final isExpanded = expandedIndices.contains(index);

                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.outline.withOpacity(0.3),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              CheckboxListTile(
                                checkboxShape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                value: isSelected,
                                onChanged: (value) => _toggleSelection(index),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        otp.issuer.isNotEmpty
                                            ? otp.issuer
                                            : 'Без эмитента',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        isExpanded
                                            ? Icons.expand_less
                                            : Icons.expand_more,
                                        size: 20,
                                      ),
                                      onPressed: () => _toggleExpanded(index),
                                      tooltip: isExpanded
                                          ? 'Свернуть'
                                          : 'Развернуть',
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (otp.name.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text('Аккаунт: ${otp.name}'),
                                    ],
                                    const SizedBox(height: 8),

                                    // TOTP код с таймером
                                    if (otp.type.toUpperCase() == 'TOTP' &&
                                        _currentCodes.containsKey(index)) ...[
                                      InkWell(
                                        onTap: () => _copyCodeToClipboard(
                                          _currentCodes[index] ?? '',
                                          otp.issuer.isNotEmpty
                                              ? otp.issuer
                                              : 'OTP',
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: colorScheme.primaryContainer,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: colorScheme.primary
                                                  .withOpacity(0.3),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.lock_clock,
                                                size: 20,
                                                color: colorScheme
                                                    .onPrimaryContainer,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                _currentCodes[index] ??
                                                    '------',
                                                style: theme
                                                    .textTheme
                                                    .headlineSmall
                                                    ?.copyWith(
                                                      fontFamily: 'monospace',
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: colorScheme
                                                          .onPrimaryContainer,
                                                      letterSpacing: 4,
                                                    ),
                                                softWrap: true,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(width: 8),
                                              Icon(
                                                Icons.copy,
                                                size: 16,
                                                color: colorScheme
                                                    .onPrimaryContainer
                                                    .withOpacity(0.7),
                                              ),
                                              const Spacer(),
                                              SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: CircularProgressIndicator(
                                                  value: _remainingSeconds / 30,
                                                  strokeWidth: 3,
                                                  color: colorScheme
                                                      .onPrimaryContainer,
                                                  backgroundColor: colorScheme
                                                      .onPrimaryContainer
                                                      .withOpacity(0.3),
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '$_remainingSecondsс',
                                                style: theme
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      color: colorScheme
                                                          .onPrimaryContainer,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                    ],

                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        _buildChip(
                                          context,
                                          otp.type,
                                          Icons.security,
                                        ),
                                        _buildChip(
                                          context,
                                          otp.algorithm,
                                          Icons.lock,
                                        ),
                                        _buildChip(
                                          context,
                                          '${otp.digits} цифр',
                                          Icons.pin,
                                        ),
                                        if (otp.counter > 0)
                                          _buildChip(
                                            context,
                                            'Счётчик: ${otp.counter}',
                                            Icons.numbers,
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                                secondary: Icon(
                                  Icons.vpn_key,
                                  color: colorScheme.primary,
                                ),
                              ),
                              if (isExpanded)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16.0),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest,
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(12),
                                      bottomRight: Radius.circular(12),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Детали токена',
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      _buildDetailRow(
                                        context,
                                        'Эмитент',
                                        otp.issuer.isNotEmpty
                                            ? otp.issuer
                                            : 'Не указан',
                                      ),
                                      _buildDetailRow(
                                        context,
                                        'Аккаунт',
                                        otp.name.isNotEmpty
                                            ? otp.name
                                            : 'Не указан',
                                      ),
                                      _buildDetailRow(context, 'Тип', otp.type),
                                      _buildDetailRow(
                                        context,
                                        'Алгоритм',
                                        otp.algorithm,
                                      ),
                                      _buildDetailRow(
                                        context,
                                        'Цифр',
                                        '${otp.digits}',
                                      ),
                                      if (otp.counter > 0)
                                        _buildDetailRow(
                                          context,
                                          'Счётчик',
                                          '${otp.counter}',
                                        ),
                                      const Divider(),
                                      _buildDetailRow(
                                        context,
                                        'Секрет (Base32)',
                                        otp.secretBase32,
                                        monospace: true,
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                    ),
                ],
              ),
            ),
            if (importedOtps.isNotEmpty)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  color: colorScheme.surface, // Фон для кнопки
                  child: SmoothButton(
                    label: selectedIndices.isEmpty
                        ? 'Выберите OTP для сохранения'
                        : 'Сохранить выбранные (${selectedIndices.length})',
                    onPressed: selectedIndices.isEmpty
                        ? null
                        : _saveSelectedOtps,
                    type: SmoothButtonType.filled,
                    loading: isSaving,
                    icon: const Icon(Icons.save, size: 20),
                    size: SmoothButtonSize.medium,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(BuildContext context, String label, IconData icon) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Chip(
      label: Text(label),
      avatar: Icon(icon, size: 16),
      visualDensity: VisualDensity.compact,
      backgroundColor: colorScheme.secondaryContainer,
      labelStyle: TextStyle(
        fontSize: 12,
        color: colorScheme.onSecondaryContainer,
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    bool monospace = false,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: monospace ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
