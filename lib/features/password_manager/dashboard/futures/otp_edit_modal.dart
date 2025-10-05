import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/index.dart';
import 'package:hoplixi/features/global/widgets/button.dart';
import 'package:hoplixi/features/global/widgets/text_field.dart';
import 'package:hoplixi/features/password_manager/categories_manager/categories_picker/categories_picker.dart';
import 'package:hoplixi/features/password_manager/tags_manager/tags_picker/tags_picker.dart';
import 'package:hoplixi/hoplixi_store/dto/db_dto.dart';
import 'package:hoplixi/hoplixi_store/enums/entity_types.dart';
import 'package:hoplixi/hoplixi_store/providers/service_providers.dart';

/// Модальное окно для редактирования базовых полей OTP кода
class OtpEditModal extends ConsumerStatefulWidget {
  final CardOtpDto otp;

  const OtpEditModal({super.key, required this.otp});

  @override
  ConsumerState<OtpEditModal> createState() => _OtpEditModalState();
}

class _OtpEditModalState extends ConsumerState<OtpEditModal> {
  late final TextEditingController _issuerController;
  late final TextEditingController _accountNameController;

  String? _selectedCategoryId;
  List<String> _selectedTagIds = [];
  bool _isFavorite = false;
  bool _isLoading = false;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    // Инициализация контроллеров с текущими значениями
    _issuerController = TextEditingController(text: widget.otp.issuer ?? '');
    _accountNameController = TextEditingController(
      text: widget.otp.accountName ?? '',
    );

    // Загрузка текущих значений
    _selectedCategoryId = widget.otp.categories?.isNotEmpty == true
        ? widget.otp.categories!.first.name
        : null;
    _selectedTagIds = widget.otp.tags?.map((t) => t.name).toList() ?? [];
    _isFavorite = widget.otp.isFavorite;

    // Загрузка реальных ID категории и тегов
    _loadCurrentCategoryAndTags();
  }

  @override
  void dispose() {
    _issuerController.dispose();
    _accountNameController.dispose();
    super.dispose();
  }

  /// Загрузка реальных ID категории и тегов из БД
  Future<void> _loadCurrentCategoryAndTags() async {
    try {
      final otpService = ref.read(totpServiceProvider);
      final result = await otpService.getTotpById(widget.otp.id);

      if (result.success && result.data != null && mounted) {
        setState(() {
          _selectedCategoryId = result.data!.categoryId;
        });

        // Загружаем теги
        await _loadOtpTags();
      }
    } catch (e) {
      logError('Ошибка загрузки данных OTP', error: e);
    }
  }

  /// Загрузка тегов OTP
  Future<void> _loadOtpTags() async {
    try {
      final otpService = ref.read(totpServiceProvider);
      final result = await otpService.getOtpTagIds(widget.otp.id);

      if (result.success && result.data != null && mounted) {
        setState(() {
          _selectedTagIds = result.data!;
        });
      }
    } catch (e) {
      logError('Ошибка загрузки тегов OTP', error: e);
    }
  }

  /// Валидация формы
  bool _validateForm() {
    if (_issuerController.text.trim().isEmpty) {
      ToastHelper.error(
        title: 'Ошибка валидации',
        description: 'Укажите издателя (Issuer)',
      );
      return false;
    }
    return true;
  }

  /// Сохранение изменений
  Future<void> _saveChanges() async {
    if (!_validateForm()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final otpService = ref.read(totpServiceProvider);

      // Используем новый метод для обновления базовых полей
      final result = await otpService.updateTotpBasic(
        id: widget.otp.id,
        issuer: _issuerController.text.trim(),
        accountName: _accountNameController.text.trim().isEmpty
            ? null
            : _accountNameController.text.trim(),
        categoryId: _selectedCategoryId,
        tagIds: _selectedTagIds,
        isFavorite: _isFavorite,
      );

      if (mounted) {
        if (result.success) {
          ToastHelper.success(
            title: 'Успешно',
            description: 'OTP код обновлен',
          );
          Navigator.of(context).pop(true); // Возвращаем true при успехе
        } else {
          ToastHelper.error(
            title: 'Ошибка',
            description: result.message ?? 'Не удалось обновить OTP код',
          );
        }
      }
    } catch (e, s) {
      logError('Ошибка сохранения OTP', error: e, stackTrace: s);
      if (mounted) {
        ToastHelper.error(
          title: 'Ошибка',
          description: 'Произошла ошибка при сохранении',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Отмена изменений
  void _cancel() {
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок
              Row(
                children: [
                  Icon(Icons.edit, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Редактировать OTP',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _isLoading ? null : _cancel,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Содержимое с прокруткой
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Issuer (Издатель)
                      PrimaryTextField(
                        controller: _issuerController,
                        label: 'Издатель *',
                        hintText: 'Например: Google, GitHub',
                        prefixIcon: const Icon(Icons.business),
                        enabled: !_isLoading,
                      ),

                      const SizedBox(height: 16),

                      // Account Name (Имя аккаунта)
                      PrimaryTextField(
                        controller: _accountNameController,
                        label: 'Имя аккаунта',
                        hintText: 'user@example.com',
                        prefixIcon: const Icon(Icons.account_circle),
                        enabled: !_isLoading,
                      ),

                      const SizedBox(height: 16),

                      // Категория
                      CategoriesPicker(
                        categoryType: CategoryType.totp,
                        selectedCategoryIds: _selectedCategoryId != null
                            ? [_selectedCategoryId!]
                            : [],
                        onSelect: (selectedIds) {
                          setState(() {
                            _selectedCategoryId = selectedIds.isNotEmpty
                                ? selectedIds.first
                                : null;
                          });
                        },
                        onClear: () {
                          setState(() {
                            _selectedCategoryId = null;
                          });
                        },
                        enabled: !_isLoading,
                        maxSelection: 1,
                        labelText: 'Категория',
                        hintText: 'Выберите категорию',
                      ),

                      const SizedBox(height: 16),

                      // Теги
                      TagsPicker(
                        tagType: TagType.totp,
                        selectedTagIds: _selectedTagIds,
                        onSelect: (selectedIds) {
                          setState(() {
                            _selectedTagIds = selectedIds;
                          });
                        },
                        onClear: () {
                          setState(() {
                            _selectedTagIds = [];
                          });
                        },
                        enabled: !_isLoading,
                        maxSelection: 5,
                        labelText: 'Теги',
                        hintText: 'Выберите теги',
                      ),

                      const SizedBox(height: 16),

                      // Избранное
                      SwitchListTile(
                        value: _isFavorite,
                        onChanged: _isLoading
                            ? null
                            : (value) {
                                setState(() {
                                  _isFavorite = value;
                                });
                              },
                        title: const Text('Добавить в избранное'),
                        secondary: Icon(
                          _isFavorite ? Icons.star : Icons.star_border,
                          color: _isFavorite
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Кнопки действий
              Row(
                spacing: 12,
                children: [
                  Expanded(
                    child: SmoothButton(
                      onPressed: _isLoading ? null : _cancel,
                      type: SmoothButtonType.outlined,
                      label: 'Отмена',
                    ),
                  ),
                  Expanded(
                    child: SmoothButton(
                      onPressed: _isLoading ? null : _saveChanges,
                      type: SmoothButtonType.filled,
                      label: _isLoading ? 'Сохранение...' : 'Сохранить',
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Хелпер для показа модального окна редактирования OTP
class OtpEditModalHelper {
  /// Показывает модальное окно редактирования OTP
  /// Возвращает true если изменения были сохранены, false если отменены
  static Future<bool?> show(BuildContext context, CardOtpDto otp) {
    return showDialog<bool>(
      useSafeArea: true,
      context: context,
      barrierDismissible: false,
      builder: (context) => OtpEditModal(otp: otp),
    );
  }
}
