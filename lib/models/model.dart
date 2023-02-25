class Model {
  String id;
  Map<String, String> fields;
  String identifyingField; // Must be present in fields
  List<String> fieldOrder;

  Model(
      {required this.id, required this.fields, required this.identifyingField, required this.fieldOrder});
}
