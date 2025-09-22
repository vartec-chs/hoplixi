import 'package:hoplixi/core/logger/app_logger.dart';

enum EntityType {
  password('password', 'Пароли'),
  note('note', 'Заметки'),
  otp('otp', 'OTP/2FA');

  const EntityType(this.id, this.label);

  final String id;
  final String label;

  /// Получить тип по идентификатору
  static EntityType? fromId(String id) {
    try {
      return EntityType.values.firstWhere((type) => type.id == id);
    } catch (e) {
      logError('Неизвестный тип сущности', error: e, data: {'id': id});
      return null;
    }
  }
}
