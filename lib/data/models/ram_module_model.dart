class RamModuleModel {
  final String? size;
  final String? formFactor;
  final String? ddrType;

  const RamModuleModel({
    this.size,
    this.formFactor,
    this.ddrType,
  });

  factory RamModuleModel.fromJson(Map<String, dynamic> json) {
    return RamModuleModel(
      size: json['size'] as String?,
      formFactor: json['form_factor'] as String?,
      ddrType: json['ddr_type'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (size != null) 'size': size,
      if (formFactor != null) 'form_factor': formFactor,
      if (ddrType != null) 'ddr_type': ddrType,
    };
  }

  RamModuleModel copyWith({
    String? size,
    String? formFactor,
    String? ddrType,
  }) {
    return RamModuleModel(
      size: size ?? this.size,
      formFactor: formFactor ?? this.formFactor,
      ddrType: ddrType ?? this.ddrType,
    );
  }

  String get displayText {
    final parts = <String>[];
    if (size != null) parts.add(size!);
    if (ddrType != null) parts.add(ddrType!);
    if (formFactor != null) parts.add(formFactor!);
    return parts.isEmpty ? 'Empty' : parts.join(' - ');
  }

  bool get isEmpty => size == null && formFactor == null && ddrType == null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RamModuleModel &&
        other.size == size &&
        other.formFactor == formFactor &&
        other.ddrType == ddrType;
  }

  @override
  int get hashCode => Object.hash(size, formFactor, ddrType);
}
