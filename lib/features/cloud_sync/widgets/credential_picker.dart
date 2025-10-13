import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/cloud_sync/models/credential_app.dart';
import 'package:hoplixi/features/cloud_sync/providers/credential_provider.dart';
import 'package:hoplixi/shared/widgets/text_field.dart';

/// Текстовое поле, позволяющее выбрать credential из списка.
class CredentialPicker extends ConsumerStatefulWidget {
  /// Выбранный credential.
  final CredentialApp? selected;

  /// Колбэк при выборе credential.
  final ValueChanged<CredentialApp> onSelect;

  /// Текст подсказки в поле.
  final String? hintText;

  /// Лейбл поля.
  final String? labelText;

  /// Флаг активности поля.
  final bool enabled;

  /// Показывать только активные credentials.
  final bool onlyActive;

  const CredentialPicker({
    super.key,
    required this.onSelect,
    this.selected,
    this.hintText,
    this.labelText,
    this.enabled = true,
    this.onlyActive = false,
  });

  @override
  ConsumerState<CredentialPicker> createState() => _CredentialPickerState();
}

class _CredentialPickerState extends ConsumerState<CredentialPicker> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _currentValueText);
  }

  @override
  void didUpdateWidget(covariant CredentialPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected?.id != widget.selected?.id) {
      _controller.text = _currentValueText;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _currentValueText => widget.selected?.type.name ?? '';

  Future<void> _openPicker() async {
    if (!widget.enabled) return;

    final selected = await showModalBottomSheet<CredentialApp>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) => _CredentialSelectionSheet(
        selectedId: widget.selected?.id,
        onlyActive: widget.onlyActive,
      ),
    );

    if (selected != null) {
      widget.onSelect(selected);
      _controller.text = selected.type.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PrimaryTextField(
      controller: _controller,
      label: widget.labelText ?? 'OAuth Credential',
      hintText: widget.hintText ?? 'Выберите Credential',
      readOnly: true,
      enabled: widget.enabled,
      onTap: _openPicker,
      suffixIcon: const Icon(Icons.arrow_drop_down),
    );
  }
}

class _CredentialSelectionSheet extends ConsumerWidget {
  final String? selectedId;
  final bool onlyActive;

  const _CredentialSelectionSheet({
    required this.selectedId,
    required this.onlyActive,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final credentials = onlyActive
        ? ref.watch(activeCredentialsProvider)
        : ref.watch(credentialListProvider);

    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Выбор Credential',
                style: theme.textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: credentials.when(
                data: (items) {
                  if (items.isEmpty) {
                    return const Center(child: Text('Credentials отсутствуют'));
                  }

                  return ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final credential = items[index];
                      final isSelected = credential.id == selectedId;

                      return ListTile(
                        title: Text(credential.type.name),
                        subtitle: Text(
                          credential.clientId,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: isSelected
                            ? Icon(
                                Icons.check_circle,
                                color: theme.colorScheme.primary,
                              )
                            : null,
                        onTap: () => Navigator.of(context).pop(credential),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Text(
                    'Не удалось загрузить credentials',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
