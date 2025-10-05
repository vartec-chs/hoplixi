import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/index.dart';
import 'package:hoplixi/core/utils/parse_hex_color.dart';
import 'package:hoplixi/hoplixi_store/dto/db_dto.dart';
import 'package:hoplixi/hoplixi_store/enums/entity_types.dart';
import 'package:hoplixi/hoplixi_store/providers/service_providers.dart';
import 'package:otp/otp.dart';

bool isBase64(String input) {
  // Пустая строка не считается Base64
  if (input.trim().isEmpty) return false;

  try {
    base64.decode(input);
    return true;
  } catch (_) {
    return false;
  }
}

bool isBase32(String input) {
  final base32Regex = RegExp(r'^[A-Z2-7]+=*$');
  return base32Regex.hasMatch(input.replaceAll(' ', '').toUpperCase());
}

class TotpCard extends ConsumerStatefulWidget {
  final CardOtpDto totp;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onLongPress;

  const TotpCard({
    super.key,
    required this.totp,
    required this.onFavoriteToggle,
    required this.onEdit,
    required this.onDelete,
    this.onLongPress,
  });

  @override
  ConsumerState<TotpCard> createState() => _TotpCardState();
}

class _TotpCardState extends ConsumerState<TotpCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late final AnimationController _animationController;
  late final Animation<double> _expandAnimation;

  late Timer _timer;
  late String _currentCode;
  late int _remainingSeconds;

  String? _secret;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _updateCode();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateCode();
      _updateRemaining();
    });

    // Убрано: Получить секрет асинхронно - теперь только при раскрытии
  }

  @override
  void dispose() {
    _animationController.dispose();
    _timer.cancel();
    super.dispose();
  }

  Future<void> _loadSecret() async {
    final service = ref.read(totpServiceProvider);
    final result = await service.getDecryptedSecret(widget.totp.id);
    if (result.success && mounted) {
      setState(() {
        _secret = result.data;
      });
      // Обновить код с новым секретом
      _updateCode();
    }
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
        if (_secret == null) {
          _loadSecret();
        }
      } else {
        _animationController.reverse();
        setState(() {
          _secret = null; // Очистить секрет при сворачивании
        });
      }
    });
  }

  void _updateCode() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    setState(() {
      _currentCode = OTP.generateTOTPCodeString(
        _secret ?? '',
        timestamp,
        interval: widget.totp.period,
        length: widget.totp.digits,
        algorithm: widget.totp.algorithm == AlgorithmOtp.SHA1
            ? Algorithm.SHA1
            : widget.totp.algorithm == AlgorithmOtp.SHA256
            ? Algorithm.SHA256
            : Algorithm.SHA512,
        isGoogle: isBase64(_secret ?? '') || isBase32(_secret ?? ''),
      );
    });
  }

  void _updateRemaining() {
    final now = DateTime.now();
    final currentSecond = now.second;
    setState(() {
      _remainingSeconds =
          widget.totp.period - (currentSecond % widget.totp.period);
    });
  }

  Future<void> _copyCodeToClipboard() async {
    try {
      await Clipboard.setData(ClipboardData(text: _currentCode));
      ToastHelper.success(title: 'Код скопирован в буфер');
    } catch (e, s) {
      logError('Ошибка копирования кода в буфер', error: e, stackTrace: s);
      ToastHelper.error(title: 'Ошибка копирования', description: e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _toggleExpanded,
          onLongPress: widget.onLongPress,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Main Card Content
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with category chips and favorite
                    Row(
                      children: [
                        // Categories
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: (widget.totp.categories ?? [])
                                .map<Widget>(
                                  (category) => _CategoryChip(
                                    name: category.name,
                                    colorHex: category.color,
                                  ),
                                )
                                .toList(),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Favorite Button
                        IconButton(
                          onPressed: widget.onFavoriteToggle,
                          icon: Icon(
                            widget.totp.isFavorite
                                ? Icons.star
                                : Icons.star_border,
                            size: 20,
                          ),
                          color: widget.totp.isFavorite
                              ? Colors.amber
                              : theme.colorScheme.onSurface.withOpacity(0.5),
                          tooltip: widget.totp.isFavorite
                              ? 'Убрано из избранного'
                              : 'В избранное',
                          splashRadius: 20,
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Title
                    Text(
                      widget.totp.issuer ?? 'Unknown Issuer',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    if (widget.totp.accountName != null &&
                        widget.totp.accountName!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        widget.totp.accountName!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    if (widget.totp.tags != null &&
                        widget.totp.tags!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: (widget.totp.tags ?? [])
                            .map<Widget>(
                              (tag) =>
                                  _TagChip(name: tag.name, colorHex: tag.color),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),

              // Expanded Content
              SizeTransition(
                sizeFactor: _expandAnimation,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withOpacity(0.3),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  padding: const EdgeInsets.all(16.0),
                  child: Consumer(
                    builder: (context, ref, child) {
                      return Column(
                        children: [
                          // OTP Code Display
                          InkWell(
                            onTap: _copyCodeToClipboard,
                            onHover: (hovering) {
                              setState(() {
                                _isHovered = hovering;
                              });
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 10,
                              ),
                              decoration: BoxDecoration(
                                color: _isHovered
                                    ? theme.colorScheme.secondaryContainer
                                    : theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                spacing: 8,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.copy,
                                    size: 20,
                                    color: theme
                                        .colorScheme
                                        .onSecondaryContainer
                                        .withOpacity(0.7),
                                  ),
                                  Text(
                                    _currentCode,
                                    style: theme.textTheme.headlineMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: theme
                                              .colorScheme
                                              .onSecondaryContainer,
                                          fontFamily: 'monospace',
                                        ),
                                  ),
                                  const SizedBox(width: 16),
                                  SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: CircularProgressIndicator(
                                      value:
                                          _remainingSeconds /
                                          widget.totp.period,
                                      strokeWidth: 4,
                                      backgroundColor: theme
                                          .colorScheme
                                          .onSecondaryContainer
                                          .withOpacity(0.2),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String name;
  final String? colorHex;

  const _CategoryChip({required this.name, this.colorHex});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = parseHexColor(colorHex, theme.colorScheme.primary);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: baseColor.withAlpha(0x1A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder, size: 16, color: baseColor),
          const SizedBox(width: 4),
          Text(
            name,
            style: theme.textTheme.labelSmall?.copyWith(
              color: baseColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String name;
  final String? colorHex;

  const _TagChip({required this.name, this.colorHex});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = parseHexColor(colorHex, theme.colorScheme.primary);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: baseColor.withAlpha(0x1A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.tag, size: 16, color: baseColor),
          const SizedBox(width: 4),
          Text(
            name,
            style: theme.textTheme.labelSmall?.copyWith(
              color: baseColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
