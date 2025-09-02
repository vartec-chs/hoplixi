/// Информация о файле базы данных
class DatabaseFileInfo {
  final String path;
  final String name;
  final String displayName;
  final DateTime lastModified;
  final int sizeBytes;
  final String? description;

  const DatabaseFileInfo({
    required this.path,
    required this.name,
    required this.displayName,
    required this.lastModified,
    required this.sizeBytes,
    this.description,
  });

  @override
  String toString() {
    return 'DatabaseFileInfo(path: $path, name: $name, lastModified: $lastModified)';
  }
}

/// Результат поиска файлов базы данных
class DatabaseFilesResult {
  final List<DatabaseFileInfo> files;
  final DatabaseFileInfo? mostRecent;
  final String searchPath;

  const DatabaseFilesResult({
    required this.files,
    this.mostRecent,
    required this.searchPath,
  });

  @override
  String toString() {
    return 'DatabaseFilesResult(files: ${files.length}, mostRecent: ${mostRecent?.name}, searchPath: $searchPath)';
  }
}
