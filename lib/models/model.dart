class Model {
  String id;
  Map<String, dynamic> fields;
  String identifyingField; // Must be present in fields

  Model(
      {required this.id, required this.fields, required this.identifyingField});
}
