
/// Модель записи истории базы данных
class DatabaseEntry {
  final String path;
  
  final String name;
  final String? description;
  final String? masterPassword;
  final bool saveMasterPassword;
  final DateTime? lastAccessed;
  final DateTime? createdAt;

  const DatabaseEntry({
    required this.path,
    required this.name,
    this.description,
    this.masterPassword,
    this.saveMasterPassword = false,
    this.lastAccessed,
    this.createdAt,
  });

  /// Создание копии с измененными полями
  DatabaseEntry copyWith({
    String? path,
    String? name,
    String? description,
    String? masterPassword,
    bool? saveMasterPassword,
    DateTime? lastAccessed,
    DateTime? createdAt,
  }) {
    return DatabaseEntry(
      path: path ?? this.path,
      name: name ?? this.name,
      description: description ?? this.description,
      masterPassword: masterPassword ?? this.masterPassword,
      saveMasterPassword: saveMasterPassword ?? this.saveMasterPassword,
      lastAccessed: lastAccessed ?? this.lastAccessed,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Преобразование в JSON
  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'name': name,
      'description': description,
      'masterPassword': masterPassword,
      'saveMasterPassword': saveMasterPassword,
      'lastAccessed': lastAccessed?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  /// Создание из JSON
  factory DatabaseEntry.fromJson(Map<String, dynamic> json) {
    return DatabaseEntry(
      path: json['path'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      masterPassword: json['masterPassword'] as String?,
      saveMasterPassword: json['saveMasterPassword'] as bool? ?? false,
      lastAccessed: json['lastAccessed'] != null
          ? DateTime.parse(json['lastAccessed'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  @override
  String toString() {
    return 'DatabaseEntry(path: $path, name: $name, description: $description, '
        'saveMasterPassword: $saveMasterPassword, lastAccessed: $lastAccessed, '
        'createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DatabaseEntry &&
        other.path == path &&
        other.name == name &&
        other.description == description &&
        other.masterPassword == masterPassword &&
        other.saveMasterPassword == saveMasterPassword &&
        other.lastAccessed == lastAccessed &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return path.hashCode ^
        name.hashCode ^
        description.hashCode ^
        masterPassword.hashCode ^
        saveMasterPassword.hashCode ^
        lastAccessed.hashCode ^
        createdAt.hashCode;
  }
}


