/// Экспорт всех компонентов для работы с зашифрованной базой данных
library encrypted_database;

// === LEGACY EXPORTS (для обратной совместимости) ===
export 'crypto_utils.dart';
export 'database_connection_manager.dart';
export 'database_validators.dart';
export 'encrypted_database_manager.dart';
export 'encrypted_database_providers.dart';
export 'database_history_service.dart' hide DatabaseHistoryService;

// === НОВЫЕ КОМПОНЕНТЫ (рекомендуется для новых проектов) ===
export 'encrypted_database_manager_v2.dart';
export 'encrypted_database_providers_v2.dart';

// === ИНТЕРФЕЙСЫ И СЕРВИСЫ ===
export 'interfaces/database_interfaces.dart';
export 'services/crypto_service.dart';
export 'services/database_validation_service.dart';
export 'services/database_connection_service.dart';
export 'services/database_history_service.dart';

// === ОБЩИЕ КОМПОНЕНТЫ ===
export 'encrypted_database.dart';
export 'db_state.dart';
export 'dto/db_dto.dart';
