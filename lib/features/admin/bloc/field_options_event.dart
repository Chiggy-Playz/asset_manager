sealed class FieldOptionsEvent {}

class FieldOptionsFetchRequested extends FieldOptionsEvent {}

class FieldOptionUpdateRequested extends FieldOptionsEvent {
  final String fieldName;
  final List<String> options;
  final bool? isRequired;

  FieldOptionUpdateRequested({
    required this.fieldName,
    required this.options,
    this.isRequired,
  });
}
