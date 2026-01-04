class FieldOptionModel {
  final String id;
  final String fieldName;
  final List<String> options;
  final bool isRequired;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FieldOptionModel({
    required this.id,
    required this.fieldName,
    required this.options,
    required this.isRequired,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FieldOptionModel.fromJson(Map<String, dynamic> json) {
    final optionsJson = json['options'] as List<dynamic>? ?? [];

    return FieldOptionModel(
      id: json['id'] as String,
      fieldName: json['field_name'] as String,
      options: optionsJson.map((e) => e as String).toList(),
      isRequired: json['is_required'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'field_name': fieldName,
      'options': options,
      'is_required': isRequired,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  FieldOptionModel copyWith({
    String? id,
    String? fieldName,
    List<String>? options,
    bool? isRequired,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FieldOptionModel(
      id: id ?? this.id,
      fieldName: fieldName ?? this.fieldName,
      options: options ?? this.options,
      isRequired: isRequired ?? this.isRequired,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Display-friendly name for the field
  String get displayName {
    return switch (fieldName) {
      'cpu' => 'CPU',
      'generation' => 'Generation',
      'ram' => 'RAM',
      'storage' => 'Storage',
      'model' => 'Model',
      _ => fieldName,
    };
  }
}
