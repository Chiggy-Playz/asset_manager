class StorageDeviceModel {
  final String? size;
  final String? type;

  const StorageDeviceModel({
    this.size,
    this.type,
  });

  factory StorageDeviceModel.fromJson(Map<String, dynamic> json) {
    return StorageDeviceModel(
      size: json['size'] as String?,
      type: json['type'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (size != null) 'size': size,
      if (type != null) 'type': type,
    };
  }

  StorageDeviceModel copyWith({
    String? size,
    String? type,
  }) {
    return StorageDeviceModel(
      size: size ?? this.size,
      type: type ?? this.type,
    );
  }

  String get displayText {
    final parts = <String>[];
    if (size != null) parts.add(size!);
    if (type != null) parts.add(type!.toUpperCase());
    return parts.isEmpty ? 'Empty' : parts.join(' - ');
  }

  bool get isEmpty => size == null && type == null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StorageDeviceModel &&
        other.size == size &&
        other.type == type;
  }

  @override
  int get hashCode => Object.hash(size, type);
}
