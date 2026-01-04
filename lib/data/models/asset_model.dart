class AssetModel {
  final String id;
  final int tagId;
  final String? cpu;
  final String? generation;
  final String? ram;
  final String? storage;
  final String? serialNumber;
  final String? modelNumber;
  final String? currentLocationId;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Populated from joined query
  final String? locationName;

  const AssetModel({
    required this.id,
    required this.tagId,
    this.cpu,
    this.generation,
    this.ram,
    this.storage,
    this.serialNumber,
    this.modelNumber,
    this.currentLocationId,
    required this.createdAt,
    required this.updatedAt,
    this.locationName,
  });

  factory AssetModel.fromJson(Map<String, dynamic> json) {
    // Handle nested location object from joined query
    final location = json['locations'] as Map<String, dynamic>?;

    return AssetModel(
      id: json['id'] as String,
      tagId: json['tag_id'] as int,
      cpu: json['cpu'] as String?,
      generation: json['generation'] as String?,
      ram: json['ram'] as String?,
      storage: json['storage'] as String?,
      serialNumber: json['serial_number'] as String?,
      modelNumber: json['model_number'] as String?,
      currentLocationId: json['current_location_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      locationName: location?['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tag_id': tagId,
      'cpu': cpu,
      'generation': generation,
      'ram': ram,
      'storage': storage,
      'serial_number': serialNumber,
      'model_number': modelNumber,
      'current_location_id': currentLocationId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  AssetModel copyWith({
    String? id,
    int? tagId,
    String? cpu,
    String? generation,
    String? ram,
    String? storage,
    String? serialNumber,
    String? modelNumber,
    String? currentLocationId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? locationName,
  }) {
    return AssetModel(
      id: id ?? this.id,
      tagId: tagId ?? this.tagId,
      cpu: cpu ?? this.cpu,
      generation: generation ?? this.generation,
      ram: ram ?? this.ram,
      storage: storage ?? this.storage,
      serialNumber: serialNumber ?? this.serialNumber,
      modelNumber: modelNumber ?? this.modelNumber,
      currentLocationId: currentLocationId ?? this.currentLocationId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      locationName: locationName ?? this.locationName,
    );
  }
}
