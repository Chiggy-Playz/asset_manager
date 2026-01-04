sealed class AssetsEvent {}

class AssetsFetchRequested extends AssetsEvent {}

class AssetCreateRequested extends AssetsEvent {
  final String tagId;
  final String? cpu;
  final String? generation;
  final String? ram;
  final String? storage;
  final String? serialNumber;
  final String? modelNumber;
  final String? currentLocationId;

  AssetCreateRequested({
    required this.tagId,
    this.cpu,
    this.generation,
    this.ram,
    this.storage,
    this.serialNumber,
    this.modelNumber,
    this.currentLocationId,
  });
}

class AssetUpdateRequested extends AssetsEvent {
  final String id;
  final String? cpu;
  final String? generation;
  final String? ram;
  final String? storage;
  final String? serialNumber;
  final String? modelNumber;
  final String? currentLocationId;

  AssetUpdateRequested({
    required this.id,
    this.cpu,
    this.generation,
    this.ram,
    this.storage,
    this.serialNumber,
    this.modelNumber,
    this.currentLocationId,
  });
}

class AssetDeleteRequested extends AssetsEvent {
  final String id;
  AssetDeleteRequested(this.id);
}

class AssetTransferRequested extends AssetsEvent {
  final String id;
  final String toLocationId;
  AssetTransferRequested({required this.id, required this.toLocationId});
}
