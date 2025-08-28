// import 'package:hive_flutter/hive_flutter.dart';
// import 'package:hoplixi/core/hive_service.dart';
// import 'package:hoplixi/main_db/db_registry_model.dart';



// class DatabaseRegistryService {
//   static const String _boxName = 'database_registry';
//   Box<DatabaseRegistryModel>? _box;

//   // Initialize service
//   Future<void> initialize() async {
//     try {
//       HiveService.registerAdapter(DatabaseRegistryModelAdapter());
//       _box = await HiveService.openBox<DatabaseRegistryModel>(_boxName);
//     } catch (e) {
//       throw HiveServiceException(
//         'Failed to initialize DatabaseRegistryService',
//         boxName: _boxName,
//         originalException: e is Exception ? e : Exception(e.toString()),
//       );
//     }
//   }

//   // Ensure box is initialized
//   Future<void> _ensureInitialized() async {
//     if (_box == null) await initialize();
//   }

//   // Add database to registry
//   Future<void> registerDatabase({
//     required String name,
//     required String path,
//     String? description,
//   }) async {
//     await _ensureInitialized();

//     final registry = DatabaseRegistryModel(
//       name: name,
//       path: path,
//       description: description,
//       createdAt: DateTime.now(),
//     );

//     await _box!.put(path, registry);
//   }

//   // Get all registered databases
//   Future<List<DatabaseRegistryModel>> getAllDatabases() async {
//     await _ensureInitialized();

//     return _box!.values.where((db) => db.isActive).toList()..sort(
//       (a, b) =>
//           b.lastAccessedAt?.compareTo(a.lastAccessedAt ?? a.createdAt) ??
//           b.createdAt.compareTo(a.createdAt),
//     );
//   }

//   // Update last accessed time
//   Future<void> updateLastAccessed(String path) async {
//     await _ensureInitialized();

//     final registry = _box!.get(path);
//     if (registry != null) {
//       registry.lastAccessedAt = DateTime.now();
//       await registry.save();
//     }
//   }

//   // Remove database from registry
//   Future<void> removeDatabaseFromRegistry(String path) async {
//     await _ensureInitialized();

//     final registry = _box!.get(path);
//     if (registry != null) {
//       registry.isActive = false;
//       await registry.save();
//     }
//   }

//   // Permanently delete from registry
//   Future<void> deleteDatabaseFromRegistry(String path) async {
//     await _ensureInitialized();
//     await _box!.delete(path);
//   }

//   // Get database by path
//   Future<DatabaseRegistryModel?> getDatabaseByPath(String path) async {
//     await _ensureInitialized();

//     final registry = _box!.get(path);
//     return registry?.isActive == true ? registry : null;
//   }

//   // Get database by name
//   Future<DatabaseRegistryModel?> getDatabaseByName(String name) async {
//     await _ensureInitialized();

//     final databases = await getAllDatabases();
//     try {
//       return databases.firstWhere((db) => db.name == name);
//     } catch (e) {
//       return null;
//     }
//   }

//   // Update database info
//   Future<void> updateDatabase(
//     String path, {
//     String? name,
//     String? description,
//   }) async {
//     await _ensureInitialized();

//     final registry = _box!.get(path);
//     if (registry != null) {
//       if (name != null) registry.name = name;
//       if (description != null) registry.description = description;
//       await registry.save();
//     }
//   }

//   // Clear all registry data
//   Future<void> clearRegistry() async {
//     await _ensureInitialized();
//     await _box!.clear();
//   }

//   // Get registry statistics
//   Future<Map<String, dynamic>> getStatistics() async {
//     await _ensureInitialized();

//     final allDbs = _box!.values.toList();
//     final activeDbs = allDbs.where((db) => db.isActive).toList();

//     return {
//       'total': allDbs.length,
//       'active': activeDbs.length,
//       'inactive': allDbs.length - activeDbs.length,
//       'oldest': allDbs.isEmpty
//           ? null
//           : allDbs
//                 .reduce((a, b) => a.createdAt.isBefore(b.createdAt) ? a : b)
//                 .createdAt,
//       'newest': allDbs.isEmpty
//           ? null
//           : allDbs
//                 .reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b)
//                 .createdAt,
//     };
//   }

//   // Close service
//   Future<void> close() async {
//     _box = null;
//   }
// }
