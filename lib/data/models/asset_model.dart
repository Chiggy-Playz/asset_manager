import 'ram_module_model.dart';
import 'storage_device_model.dart';

class AssetModel {
  final String id;
  final String tagId;
  final String? cpu;
  final String? generation;
  final List<RamModuleModel> ramModules;
  final List<StorageDeviceModel> storageDevices;
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
    this.ramModules = const [],
    this.storageDevices = const [],
    this.serialNumber,
    this.modelNumber,
    this.currentLocationId,
    required this.createdAt,
    required this.updatedAt,
    this.locationName,
  });

  String get ramSummary {
    if (ramModules.isEmpty) return 'No RAM';
    return ramModules.map((m) => m.displayText).join(', ');
  }

  String get storageSummary {
    if (storageDevices.isEmpty) return 'No Storage';
    return storageDevices.map((d) => d.displayText).join(', ');
  }

  factory AssetModel.fromJson(Map<String, dynamic> json) {
    // Handle nested location object from joined query
    final location = json['locations'] as Map<String, dynamic>?;

    // Parse RAM modules from JSONB array
    final ramJson = json['ram'] as List<dynamic>? ?? [];
    final ramModules = ramJson
        .map((e) => RamModuleModel.fromJson(e as Map<String, dynamic>))
        .toList();

    // Parse storage devices from JSONB array
    final storageJson = json['storage'] as List<dynamic>? ?? [];
    final storageDevices = storageJson
        .map((e) => StorageDeviceModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return AssetModel(
      id: json['id'] as String,
      tagId: json['tag_id'] as String,
      cpu: json['cpu'] as String?,
      generation: json['generation'] as String?,
      ramModules: ramModules,
      storageDevices: storageDevices,
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
      'ram': ramModules.map((m) => m.toJson()).toList(),
      'storage': storageDevices.map((d) => d.toJson()).toList(),
      'serial_number': serialNumber,
      'model_number': modelNumber,
      'current_location_id': currentLocationId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  AssetModel copyWith({
    String? id,
    String? tagId,
    String? cpu,
    String? generation,
    List<RamModuleModel>? ramModules,
    List<StorageDeviceModel>? storageDevices,
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
      ramModules: ramModules ?? this.ramModules,
      storageDevices: storageDevices ?? this.storageDevices,
      serialNumber: serialNumber ?? this.serialNumber,
      modelNumber: modelNumber ?? this.modelNumber,
      currentLocationId: currentLocationId ?? this.currentLocationId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      locationName: locationName ?? this.locationName,
    );
  }
}
