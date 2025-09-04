/// Location of a record within a segment.
class SegmentLocation {
  final String segmentName;
  final int offset;
  final int length;
  final bool isDeleted;

  const SegmentLocation({
    required this.segmentName,
    required this.offset,
    required this.length,
    this.isDeleted = false,
  });

  @override
  String toString() =>
      'SegmentLocation(segment: $segmentName, offset: $offset, length: $length, deleted: $isDeleted)';
}

/// Metadata about a segment file.
class SegmentMeta {
  final String name;
  final int size;
  final String created;
  final bool finalized;
  final String? checksum;

  const SegmentMeta({
    required this.name,
    required this.size,
    required this.created,
    required this.finalized,
    this.checksum,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'size': size,
    'created': created,
    'finalized': finalized,
    if (checksum != null) 'checksum': checksum,
  };

  factory SegmentMeta.fromJson(Map<String, dynamic> json) => SegmentMeta(
    name: json['name'] as String,
    size: json['size'] as int,
    created: json['created'] as String,
    finalized: json['finalized'] as bool,
    checksum: json['checksum'] as String?,
  );
}

/// Manifest structure for a box.
class BoxManifest {
  final int version;
  final String boxName;
  final List<SegmentMeta> segments;
  final Map<String, dynamic> meta;

  const BoxManifest({
    required this.version,
    required this.boxName,
    required this.segments,
    this.meta = const {},
  });

  Map<String, dynamic> toJson() => {
    'version': version,
    'box': boxName,
    'segments': segments.map((s) => s.toJson()).toList(),
    '__meta': meta,
  };

  factory BoxManifest.fromJson(Map<String, dynamic> json) => BoxManifest(
    version: json['version'] as int,
    boxName: json['box'] as String,
    segments: (json['segments'] as List)
        .map((s) => SegmentMeta.fromJson(s as Map<String, dynamic>))
        .toList(),
    meta: json['__meta'] as Map<String, dynamic>? ?? {},
  );

  /// Create a new manifest with incremented version and new segments.
  BoxManifest copyWith({
    int? version,
    String? boxName,
    List<SegmentMeta>? segments,
    Map<String, dynamic>? meta,
  }) => BoxManifest(
    version: version ?? this.version + 1,
    boxName: boxName ?? this.boxName,
    segments: segments ?? this.segments,
    meta: meta ?? this.meta,
  );
}

/// Type definitions for serialization.
typedef FromMapFn<T> = T Function(Map<String, dynamic> map);
typedef ToMapFn<T> = Map<String, dynamic> Function(T object);
