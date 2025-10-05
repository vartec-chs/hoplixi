import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/global/widgets/text_field.dart';
import 'package:hoplixi/features/global/widgets/button.dart';
import 'package:hoplixi/features/password_manager/dashboard/futures/otp_form/utils.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/data_refresh_trigger_provider.dart';
import 'package:hoplixi/hoplixi_store/dto/db_dto.dart';
import 'package:hoplixi/hoplixi_store/enums/entity_types.dart';
import 'package:hoplixi/hoplixi_store/providers/service_providers.dart';
import 'package:hoplixi/router/routes_path.dart';
import 'package:hoplixi/features/password_manager/categories_manager/categories_picker/categories_picker.dart';
import 'package:otp/otp.dart';

class OtpForm extends ConsumerStatefulWidget {
  const OtpForm({super.key});

  @override
  ConsumerState<OtpForm> createState() => _OtpFormState();
}

class _OtpFormState extends ConsumerState<OtpForm>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late List<Tab> tabWidgets;
  late List<bool> tabDisabled;

  final _formKey = GlobalKey<FormState>();

  String? _resultScanned;

  // TextEditingControllers для формы TOTP
  final issuerController = TextEditingController();
  final accountNameController = TextEditingController();
  final secretController = TextEditingController();
  final digitsController = TextEditingController(text: '6');
  final periodController = TextEditingController(text: '30');

  // Состояние формы
  AlgorithmOtp selectedAlgorithm = AlgorithmOtp.SHA1;
  bool isFavorite = false;
  String? selectedCategoryId;

  bool buttonEnabled = false;

  // Определение вкладок и их состояния (включена/отключена)
  final List<Map<Tab, bool>> tabs = <Map<Tab, bool>>[
    {
      const Tab(
        text: 'TOTP',
        icon: Icon(Icons.access_time, size: 18),
        height: 42,
      ): false,
    },

    {
      const Tab(text: 'HOTP', icon: Icon(Icons.lock, size: 18), height: 42):
          true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
    tabDisabled = tabs.map((tabMap) => tabMap.values.first).toList();
    tabWidgets = tabs.map((tabMap) => tabMap.keys.first).toList();
  }

  // Обработчик изменения вкладок не отображать в ui с false

  @override
  void dispose() {
    _tabController.dispose();
    issuerController.dispose();
    accountNameController.dispose();
    secretController.dispose();
    digitsController.dispose();
    periodController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OTP'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.pop();
          },
        ),
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(58.0),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: SizedBox(
              height: 52,

              child: TabBar(
                tabs: List<Widget>.generate(
                  tabWidgets.length,
                  (index) => Opacity(
                    opacity: tabDisabled[index] ? 0.5 : 1.0,
                    child: tabWidgets[index],
                  ),
                ),
                controller: _tabController,
                indicatorColor: Theme.of(context).colorScheme.secondary,
                indicatorWeight: 3,
                labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                indicatorSize: TabBarIndicatorSize.tab,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                indicator: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                splashBorderRadius: BorderRadius.circular(16),
                labelColor: Theme.of(context).colorScheme.onSecondaryContainer,
                unselectedLabelColor: Theme.of(context).colorScheme.onSurface,
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                overlayColor: WidgetStateProperty.resolveWith<Color?>((
                  Set<WidgetState> states,
                ) {
                  if (states.contains(WidgetState.pressed)) {
                    return Theme.of(
                      context,
                    ).colorScheme.onPrimaryContainer.withOpacity(0.12);
                  }
                  return null; // Defer to the widget's default.
                }),
                onTap: (value) {
                  if (tabDisabled[value]) {
                    // Если вкладка отключена, вернуться к предыдущей
                    _tabController.index = _tabController.previousIndex;
                    ToastHelper.info(
                      title: 'Вкладка отключена',
                      description: 'Эта функция возможно появится позже.',
                    );
                  }
                },
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildTotpForm(),
            Center(child: Text('HOTP Form Content Here')),
          ],
        ),
      ),
    );
  }

  Widget _buildTotpForm() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(8.0),
            child: Form(
              autovalidateMode:
                  AutovalidateMode.onUserInteraction, // <-- важный параметр
              onChanged: () => {
                setState(() {
                  buttonEnabled = _formKey.currentState?.validate() ?? false;
                }),
              },
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  TextFormField(
                    controller: issuerController,
                    decoration: primaryInputDecoration(
                      context,
                      labelText: 'Issuer',
                      hintText: 'Например: Google, GitHub',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Issuer обязателен';
                      }

                      return null;
                    },
                  ),

                  TextFormField(
                    controller: accountNameController,
                    decoration: primaryInputDecoration(
                      context,
                      labelText: 'Account Name',
                      hintText: 'Например: user@example.com',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Account Name обязателен';
                      }
                      return null;
                    },
                  ),

                  TextFormField(
                    controller: secretController,
                    decoration: primaryInputDecoration(
                      context,
                      labelText: 'Secret',
                      hintText: 'Base32 encoded secret',
                    ),
                    // obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Secret обязателен';
                      }
                      return null;
                    },
                  ),

                  DropdownButtonFormField<AlgorithmOtp>(
                    initialValue: selectedAlgorithm,
                    decoration: primaryInputDecoration(
                      context,
                      labelText: 'Algorithm',
                    ),

                    items: AlgorithmOtp.values.map((algorithm) {
                      return DropdownMenuItem(
                        value: algorithm,
                        child: Text(algorithm.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedAlgorithm = value;
                        });
                      }
                    },
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    spacing: 8,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: digitsController,
                          decoration: primaryInputDecoration(
                            context,
                            labelText: 'Digits',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Digits обязателен';
                            }
                            final intValue = int.tryParse(value);
                            if (intValue == null || intValue <= 0) {
                              return 'Digits должен быть положительным числом';
                            }
                            return null;
                          },
                        ),
                      ),

                      Expanded(
                        child: TextFormField(
                          controller: periodController,
                          decoration: primaryInputDecoration(
                            context,
                            labelText: 'Period (seconds)',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Period обязателен';
                            }
                            final intValue = int.tryParse(value);
                            if (intValue == null || intValue <= 0) {
                              return 'Period должен быть положительным числом';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),

                  SmoothButton(
                    isFullWidth: true,
                    type: SmoothButtonType.outlined,
                    label: 'Заполнить через QR-код',
                    onPressed: () async {
                      String? result = await context.push<String?>(
                        AppRoutes.qrScanner,
                      );
                      if (result != null) {
                        final uri = Uri.tryParse(result);
                        if (uri != null) {
                          final otpUri = parseOtpUri(uri.toString());
                          issuerController.text = otpUri.issuer;
                          accountNameController.text = otpUri.account;
                          secretController.text = otpUri.secret;
                          digitsController.text = '6';
                          periodController.text = '30';

                          setState(() {});
                        }
                      }
                    },
                  ),

                  SwitchListTile(
                    title: const Text('Как избранное'),
                    value: isFavorite,
                    onChanged: (value) {
                      setState(() {
                        isFavorite = value;
                      });
                    },
                  ),

                  CategoriesPicker(
                    categoryType: CategoryType.totp,
                    selectedCategoryIds: selectedCategoryId != null
                        ? [selectedCategoryId!]
                        : [],
                    onSelect: (selectedIds) {
                      setState(() {
                        selectedCategoryId = selectedIds.isNotEmpty
                            ? selectedIds.first
                            : null;
                      });
                    },
                    hintText: 'Выберите категорию для TOTP',
                    labelText: 'Категория',
                  ),

                  _resultScanned != null
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'Scanned Result: $_resultScanned',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: SmoothButton(
            label: 'Создать TOTP',
            onPressed: buttonEnabled ? _createTotp : null,
            type: SmoothButtonType.filled,
            isFullWidth: true,
          ),
        ),
      ],
    );
  }

  Future<void> _createTotp() async {
    if (secretController.text.isEmpty) {
      ToastHelper.error(title: 'Ошибка', description: 'Secret обязателен');
      return;
    }

    // Показать модалку для подтверждения
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => OtpVerificationDialog(
        secret: secretController.text,
        period: int.tryParse(periodController.text) ?? 30,
        digits: int.tryParse(digitsController.text) ?? 6,
        algorithm: selectedAlgorithm == AlgorithmOtp.SHA1
            ? Algorithm.SHA1
            : selectedAlgorithm == AlgorithmOtp.SHA256
            ? Algorithm.SHA256
            : Algorithm.SHA512,
        isGoogle: issuerController.text.toLowerCase().contains('google'),
      ),
    );

    if (confirmed != true) {
      return;
    }

    final dto = CreateTotpDto(
      issuer: issuerController.text.isNotEmpty ? issuerController.text : null,
      accountName: accountNameController.text.isNotEmpty
          ? accountNameController.text
          : null,
      secret: secretController.text,
      algorithm: selectedAlgorithm,
      digits: int.tryParse(digitsController.text) ?? 6,
      period: int.tryParse(periodController.text) ?? 30,
      categoryId: selectedCategoryId,
      isFavorite: isFavorite,
    );

    final totpService = ref.read(totpServiceProvider);
    final result = await totpService.createTotp(dto);

    if (result.success) {
      ToastHelper.success(
        title: 'Успех',
        description: result.message ?? 'TOTP создан',
      );
      // Очистить форму
      issuerController.clear();
      accountNameController.clear();
      secretController.clear();
      digitsController.text = '6';
      periodController.text = '30';
      setState(() {
        selectedAlgorithm = AlgorithmOtp.SHA1;
        isFavorite = false;
        selectedCategoryId = null;
      });
      if (mounted) {
        DataRefreshHelper.refreshOtp(ref);
        context.pop();
      }
    } else {
      ToastHelper.error(
        title: 'Ошибка',
        description: result.message ?? 'Не удалось создать TOTP',
      );
    }
  }
}

class OtpVerificationDialog extends StatefulWidget {
  final String secret;
  final int period;
  final int digits;
  final Algorithm algorithm;
  final bool isGoogle;

  const OtpVerificationDialog({
    super.key,
    required this.secret,
    required this.period,
    this.digits = 6,
    this.algorithm = Algorithm.SHA1,
    this.isGoogle = true,
  });

  @override
  State<OtpVerificationDialog> createState() => _OtpVerificationDialogState();
}

class _OtpVerificationDialogState extends State<OtpVerificationDialog> {
  late Timer _timer;
  late String _currentCode;
  late int _remainingSeconds;

  final TextEditingController _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _updateCode();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateCode();
      _updateRemaining();
    });
  }

  void _updateCode() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    setState(() {
      _currentCode = OTP.generateTOTPCodeString(
        widget.secret,
        timestamp,
        interval: widget.period,
        length: widget.digits,
        algorithm: widget.algorithm,
        isGoogle: widget.isGoogle,
      );
    });
  }

  void _updateRemaining() {
    final now = DateTime.now();
    final currentSecond = now.second;
    setState(() {
      _remainingSeconds = widget.period - (currentSecond % widget.period);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.all(8.0),
      constraints: BoxConstraints(maxWidth: 400),
      title: const Text('Подтверждение TOTP'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Текущий код: $_currentCode'),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            verticalDirection: VerticalDirection.down,
            spacing: 8,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _codeController,
                  decoration:
                      primaryInputDecoration(
                        context,
                        labelText: 'Введите код',
                      ).copyWith(
                        suffixIcon: Container(
                          padding: const EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(
                            constraints: BoxConstraints(
                              maxWidth: 40,
                              maxHeight: 40,
                            ),
                            value: _remainingSeconds / widget.period,
                            strokeWidth: 4,
                          ),
                        ),
                      ),
                  keyboardType: TextInputType.number,
                ),
              ),

              // SizedBox(
              //   width: 40,
              //   height: 40,
              //   child: CircularProgressIndicator(
              //     value: _remainingSeconds / widget.period,
              //     strokeWidth: 4,
              //   ),
              // ),

              // Text('$_remainingSeconds сек'),
            ],
          ),

          const SizedBox(height: 8),
          Text('Секрет: ${widget.secret}'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: () {
            if (_codeController.text == _currentCode) {
              Navigator.of(context).pop(true);
            } else {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Неверный код')));
            }
          },
          child: const Text('Подтвердить'),
        ),
      ],
    );
  }
}
