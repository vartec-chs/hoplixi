# LocalSend Feature Development Plan

## Текущее состояние (Production Readiness: 45%)

### ✅ Готовые компоненты

1. **Архитектура и структура** - 100%
   - ✅ Модели данных (DeviceInfo, FileTransfer, LocalSendMessage, WebRTCConnection)
   - ✅ Сервисы (WebRTC, Discovery, Signaling, File)
   - ✅ Провайдеры Riverpod v3 (состояние управления)
   - ✅ Контроллер для координации операций
   - ✅ UI экраны и виджеты (основной экран с вкладками)

2. **Пользовательский интерфейс** - 90%
   - ✅ Главный экран с табами (устройства, передачи, сообщения)
   - ✅ Список устройств с карточками
   - ✅ Интерфейс передач файлов с прогресс-барами
   - ✅ История сообщений
   - ✅ Диалог отправки сообщений
   - ✅ Интеграция с роутингом приложения

3. **Модели и типизация** - 100%
   - ✅ Freezed модели с JSON сериализацией
   - ✅ Enums для состояний и типов
   - ✅ Правильная типизация всех компонентов

### ❌ Критические недоработки (требуют реализации)

1. **Реальная функциональность WebRTC** - 0%
   - ❌ Отсутствует реальная инициация WebRTC соединений
   - ❌ Нет обработки SDP offer/answer обмена
   - ❌ ICE candidates не обрабатываются
   - ❌ DataChannel передача данных не работает
   - ❌ Нет интеграции с сигналинг сервисом

2. **mDNS/DNS-SD Discovery** - 10%
   - ❌ Только заглушки в DiscoveryService
   - ❌ Bonsoir интеграция не реализована
   - ❌ Нет реального обнаружения устройств в сети
   - ❌ Отсутствует broadcast собственного устройства

3. **Реальная передача файлов** - 20%
   - ❌ Только симуляция передачи файлов
   - ❌ Нет чанкования файлов
   - ❌ Отсутствует проверка целостности (SHA-256)
   - ❌ Нет resume возможности при обрыве

4. **HTTP Signaling** - 30%
   - ✅ HTTP сервер создан, но не интегрирован
   - ❌ Нет endpoint'ов для обмена SDP/ICE
   - ❌ Отсутствует CORS для кросс-платформенности
   - ❌ Нет обработки signaling сообщений

5. **Безопасность и стабильность** - 10%
   - ❌ Нет шифрования данных
   - ❌ Отсутствует аутентификация устройств
   - ❌ Нет таймаутов и retry логики
   - ❌ Отсутствует обработка network errors

---

## 🚀 План доработки до Production Ready

### Фаза 1: Базовая функциональность (Приоритет: ВЫСОКИЙ)

#### 1.1 Реализация mDNS Discovery (Время: 2-3 дня)
```dart
// В DiscoveryService
- Интеграция Bonsoir для mDNS
- Broadcast сервиса "_localsend._tcp"
- Обнаружение устройств в локальной сети
- Парсинг TXT записей с метаданными устройства
```

#### 1.2 HTTP Signaling Endpoints (Время: 1-2 дня)
```dart
// В SignalingService
- POST /signal - обмен SDP offer/answer
- POST /ice - обмен ICE candidates  
- GET /ping - проверка доступности
- WebSocket для real-time обмена (опционально)
```

#### 1.3 WebRTC P2P Connection (Время: 3-4 дня)
```dart
// В WebRTCService
- Реальная инициация PeerConnection
- Обработка SDP offer/answer через signaling
- Exchange ICE candidates
- Установка DataChannel соединения
- Обработка connection states
```

#### 1.4 Базовая передача текста (Время: 1 день)
```dart
// Тестирование end-to-end
- Отправка текстовых сообщений через DataChannel
- Статусы доставки
- UI обновления в реальном времени
```

### Фаза 2: Передача файлов (Приоритет: ВЫСОКИЙ)

#### 2.1 Chunked File Transfer (Время: 3-4 дня)
```dart
// В FileService
- Разбиение файлов на чанки (64KB)
- Отправка через DataChannel
- Сборка файлов на приемнике
- Progress tracking для UI
```

#### 2.2 Integrity & Resume (Время: 2-3 дня)
```dart
// Дополнительная надежность
- SHA-256 хеширование файлов
- Проверка целостности чанков
- Resume при обрыве соединения
- Retry механизм для failed transfers
```

### Фаза 3: Безопасность и стабильность (Приоритет: СРЕДНИЙ)

#### 3.1 Security Layer (Время: 4-5 дней)
```dart
// Безопасность данных
- Device authentication через certificates
- End-to-end encryption для файлов
- Whitelist/blacklist устройств
- Security warnings для unknown devices
```

#### 3.2 Error Handling & Recovery (Время: 2-3 дня)
```dart
// Устойчивость к сбоям
- Connection timeouts и reconnection
- Network change handling
- Memory management для больших файлов
- Background transfer support
```

### Фаза 4: UI/UX улучшения (Приоритет: НИЗКИЙ)

#### 4.1 Advanced UI Features (Время: 2-3 дня)
```dart
// Пользовательский опыт
- Drag & drop файлов
- Multiple file selection с preview
- Transfer queue management
- Dark/light theme поддержка
- Настройки (порт, auto-accept и т.д.)
```

#### 4.2 Cross-platform Optimization (Время: 3-4 дня)
```dart
// Платформенные особенности
- Desktop: системные уведомления
- Mobile: background processing
- Adaptive UI для разных screen sizes
- Platform-specific file pickers
```

### Фаза 5: Testing & Polish (Приоритет: ВЫСОКИЙ)

#### 5.1 Unit & Integration Tests (Время: 3-4 дня)
```dart
// Тестирование
- WebRTC connection tests
- File transfer integrity tests
- Discovery service tests
- UI widget tests
- Error scenarios coverage
```

#### 5.2 Performance & Optimization (Время: 2-3 дня)
```dart
// Производительность
- Memory usage optimization
- Transfer speed optimization
- Battery usage на mobile
- Network usage metrics
```

---

## 📋 Техническая детализация

### Критические зависимости для реализации:

1. **flutter_webrtc: ^1.2.0** ✅ (уже добавлена)
2. **bonsoir: ^6.0.1** ✅ (уже добавлена) 
3. **file_picker: ^6.1.1** ✅ (уже в проекте)
4. **path_provider: ^2.1.2** ✅ (уже в проекте)
5. **crypto: ^3.0.3** ✅ (уже в проекте)

### Дополнительные зависимости:

```yaml
dependencies:
  mime: ^1.0.4                    # MIME type detection
  permission_handler: ^11.1.0     # File access permissions  
  network_info_plus: ^4.1.0       # Network interface info
  connectivity_plus: ^5.0.2       # Network connectivity state
```

### Конфигурационные требования:

#### Android (android/app/src/main/AndroidManifest.xml):
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:name="android.permission.CHANGE_WIFI_MULTICAST_STATE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

#### iOS (ios/Runner/Info.plist):
```xml
<key>NSLocalNetworkUsageDescription</key>
<string>LocalSend needs access to discover devices on local network</string>
<key>NSMicrophoneUsageDescription</key>
<string>LocalSend uses WebRTC for P2P connection</string>
```

---

## ⚡ Quick Win Задачи (можно реализовать прямо сейчас)

### 1. Добавить WebRTCConfig constants (30 мин)
```dart
class WebRTCConfig {
  static const List<Map<String, String>> iceServers = [
    {'urls': 'stun:stun.l.google.com:19302'},
    {'urls': 'stun:stun1.l.google.com:19302'},
  ];
  
  static const RTCDataChannelInit dataChannelConfig = RTCDataChannelInit(
    ordered: true,
    maxRetransmitTime: -1,
    maxRetransmits: -1,
  );
}
```

### 2. Реализовать базовый mDNS discovery (2 часа)
```dart
// В DiscoveryService - заменить заглушки на реальный Bonsoir код
```

### 3. Добавить HTTP signaling endpoints (1 час)
```dart
// В SignalingService - реальные /signal и /ice endpoints
```

### 4. Интеграция контроллера с реальными сервисами (1 час)
```dart
// В LocalSendController - убрать симуляции, добавить реальные вызовы
```

---

## 🎯 Итоговая оценка

**Текущая готовность: 45%**
**Время до Production Ready: 20-25 рабочих дней**
**Критический путь: WebRTC + mDNS + File Transfer**

### Рекомендуемая последовательность:
1. **Week 1**: mDNS Discovery + HTTP Signaling 
2. **Week 2**: WebRTC P2P Connection + Text Messages
3. **Week 3**: File Transfer Implementation  
4. **Week 4**: Security + Error Handling + Testing

### Риски и митигация:
- **WebRTC сложность**: Начать с простого text transfer
- **Cross-platform различия**: Тестировать на всех платформах рано
- **Performance на больших файлах**: Chunking и memory management
- **Network issues**: Robust error handling и reconnection logic