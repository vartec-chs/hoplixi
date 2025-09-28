/// Режимы установки WebRTC соединения
enum ConnectionMode {
  /// Инициатор соединения - отправляет offer
  initiator,

  /// Получатель соединения - ждет offer и отправляет answer
  receiver,
}

/// Расширения для удобства работы с ConnectionMode
extension ConnectionModeExtension on ConnectionMode {
  /// Название режима для отображения
  String get displayName {
    switch (this) {
      case ConnectionMode.initiator:
        return 'Создать подключение';
      case ConnectionMode.receiver:
        return 'Ждать подключения';
    }
  }

  /// Описание режима
  String get description {
    switch (this) {
      case ConnectionMode.initiator:
        return 'Ваше устройство инициирует подключение к выбранному устройству';
      case ConnectionMode.receiver:
        return 'Ваше устройство будет ждать входящее подключение от выбранного устройства';
    }
  }

  /// Иконка для режима
  String get icon {
    switch (this) {
      case ConnectionMode.initiator:
        return '🚀';
      case ConnectionMode.receiver:
        return '📡';
    }
  }
}
