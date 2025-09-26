import 'package:flutter_webrtc/flutter_webrtc.dart';

/// Конфигурация для WebRTC соединений LocalSend
class WebRTCConfig {
  /// STUN серверы для ICE candidates discovery
  static const List<Map<String, String>> iceServers = [
    {'urls': 'stun:stun.l.google.com:19302'},
    {'urls': 'stun:stun1.l.google.com:19302'},
    {'urls': 'stun:stun2.l.google.com:19302'},
  ];

  /// Конфигурация для DataChannel
  static RTCDataChannelInit get dataChannelConfig => RTCDataChannelInit()
    ..ordered = true
    ..maxRetransmitTime = -1
    ..maxRetransmits = -1
    ..protocol = 'localsend'
    ..negotiated = false;

  /// Конфигурация для PeerConnection
  static const Map<String, dynamic> pcConfig = {
    'iceServers': iceServers,
    'iceCandidatePoolSize': 10,
  };

  /// Максимальный размер чанка для передачи файлов (64KB)
  static const int maxChunkSize = 64 * 1024;

  /// Таймауты для соединений
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration iceGatheringTimeout = Duration(seconds: 10);
  static const Duration dataChannelTimeout = Duration(seconds: 15);

  /// Порт по умолчанию для HTTP signaling
  static const int defaultSignalingPort = 53317;

  /// Имя DataChannel для передачи сообщений
  static const String messageChannelLabel = 'localsend-messages';

  /// Имя DataChannel для передачи файлов
  static const String fileChannelLabel = 'localsend-files';

  /// Максимальное количество одновременных соединений
  static const int maxConcurrentConnections = 5;

  /// Ограничения для медиа (отключаем аудио/видео)
  static const Map<String, dynamic> mediaConstraints = {
    'audio': false,
    'video': false,
  };
}
