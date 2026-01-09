import 'package:equatable/equatable.dart';

/// Represents the search/filter criteria for assets.
class AssetSearchFilter extends Equatable {
  // Text filters (partial search)
  final String? tagId;
  final String? serialNumber;
  final String? modelNumber;

  // Multi-select filters
  final List<String> assetTypes;
  final List<String> cpus;
  final List<String> generations;

  // RAM filters
  final int? ramTotalSize; // in GB
  final String? ramSizeOperator; // '>', '<', '>=', '<=', '='
  final List<String> ramTypes; // DDR3, DDR4, DDR5
  final List<String> ramFormFactors; // Desktop, Laptop

  // Storage filters
  final int? storageTotalSize; // in GB
  final String? storageSizeOperator;
  final List<String> storageTypes; // NVMe, SATA, SAS

  // Location filter
  final List<String> locationIds;

  const AssetSearchFilter({
    this.tagId,
    this.serialNumber,
    this.modelNumber,
    this.assetTypes = const [],
    this.cpus = const [],
    this.generations = const [],
    this.ramTotalSize,
    this.ramSizeOperator,
    this.ramTypes = const [],
    this.ramFormFactors = const [],
    this.storageTotalSize,
    this.storageSizeOperator,
    this.storageTypes = const [],
    this.locationIds = const [],
  });

  /// Creates an empty filter with no criteria.
  const AssetSearchFilter.empty()
      : tagId = null,
        serialNumber = null,
        modelNumber = null,
        assetTypes = const [],
        cpus = const [],
        generations = const [],
        ramTotalSize = null,
        ramSizeOperator = null,
        ramTypes = const [],
        ramFormFactors = const [],
        storageTotalSize = null,
        storageSizeOperator = null,
        storageTypes = const [],
        locationIds = const [];

  /// Returns true if no filter criteria are set.
  bool get isEmpty =>
      (tagId == null || tagId!.isEmpty) &&
      (serialNumber == null || serialNumber!.isEmpty) &&
      (modelNumber == null || modelNumber!.isEmpty) &&
      assetTypes.isEmpty &&
      cpus.isEmpty &&
      generations.isEmpty &&
      ramTotalSize == null &&
      ramTypes.isEmpty &&
      ramFormFactors.isEmpty &&
      storageTotalSize == null &&
      storageTypes.isEmpty &&
      locationIds.isEmpty;

  /// Returns true if any filter criteria are set.
  bool get isNotEmpty => !isEmpty;

  /// Converts the filter to JSON for the RPC call.
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};

    if (tagId != null && tagId!.isNotEmpty) {
      json['tag_id'] = tagId;
    }
    if (serialNumber != null && serialNumber!.isNotEmpty) {
      json['serial_number'] = serialNumber;
    }
    if (modelNumber != null && modelNumber!.isNotEmpty) {
      json['model_number'] = modelNumber;
    }
    if (assetTypes.isNotEmpty) {
      json['asset_types'] = assetTypes;
    }
    if (cpus.isNotEmpty) {
      json['cpus'] = cpus;
    }
    if (generations.isNotEmpty) {
      json['generations'] = generations;
    }
    if (ramTotalSize != null) {
      json['ram_size'] = ramTotalSize;
      json['ram_operator'] = ramSizeOperator ?? '>=';
    }
    if (ramTypes.isNotEmpty) {
      json['ram_types'] = ramTypes;
    }
    if (ramFormFactors.isNotEmpty) {
      json['ram_form_factors'] = ramFormFactors;
    }
    if (storageTotalSize != null) {
      json['storage_size'] = storageTotalSize;
      json['storage_operator'] = storageSizeOperator ?? '>=';
    }
    if (storageTypes.isNotEmpty) {
      json['storage_types'] = storageTypes;
    }
    if (locationIds.isNotEmpty) {
      json['location_ids'] = locationIds;
    }

    return json;
  }

  AssetSearchFilter copyWith({
    String? tagId,
    String? serialNumber,
    String? modelNumber,
    List<String>? assetTypes,
    List<String>? cpus,
    List<String>? generations,
    int? ramTotalSize,
    String? ramSizeOperator,
    List<String>? ramTypes,
    List<String>? ramFormFactors,
    int? storageTotalSize,
    String? storageSizeOperator,
    List<String>? storageTypes,
    List<String>? locationIds,
    bool clearRamSize = false,
    bool clearStorageSize = false,
  }) {
    return AssetSearchFilter(
      tagId: tagId ?? this.tagId,
      serialNumber: serialNumber ?? this.serialNumber,
      modelNumber: modelNumber ?? this.modelNumber,
      assetTypes: assetTypes ?? this.assetTypes,
      cpus: cpus ?? this.cpus,
      generations: generations ?? this.generations,
      ramTotalSize: clearRamSize ? null : (ramTotalSize ?? this.ramTotalSize),
      ramSizeOperator: ramSizeOperator ?? this.ramSizeOperator,
      ramTypes: ramTypes ?? this.ramTypes,
      ramFormFactors: ramFormFactors ?? this.ramFormFactors,
      storageTotalSize:
          clearStorageSize ? null : (storageTotalSize ?? this.storageTotalSize),
      storageSizeOperator: storageSizeOperator ?? this.storageSizeOperator,
      storageTypes: storageTypes ?? this.storageTypes,
      locationIds: locationIds ?? this.locationIds,
    );
  }

  @override
  List<Object?> get props => [
        tagId,
        serialNumber,
        modelNumber,
        assetTypes,
        cpus,
        generations,
        ramTotalSize,
        ramSizeOperator,
        ramTypes,
        ramFormFactors,
        storageTotalSize,
        storageSizeOperator,
        storageTypes,
        locationIds,
      ];
}

/// Represents the result of a search query.
class SearchResult<T> {
  final List<T> assets;
  final int totalCount;

  const SearchResult({
    required this.assets,
    required this.totalCount,
  });

  /// Returns true if there are more results available.
  bool hasMoreResults(int currentPage, int pageSize) {
    return (currentPage + 1) * pageSize < totalCount;
  }

  /// Returns the total number of pages.
  int totalPages(int pageSize) {
    if (pageSize <= 0) return 0;
    return (totalCount / pageSize).ceil();
  }
}
