import '../../../data/models/field_option_model.dart';

sealed class FieldOptionsState {}

class FieldOptionsInitial extends FieldOptionsState {}

class FieldOptionsLoading extends FieldOptionsState {}

class FieldOptionsLoaded extends FieldOptionsState {
  final List<FieldOptionModel> fieldOptions;

  FieldOptionsLoaded(this.fieldOptions);

  /// Get options for a specific field
  List<String> getOptionsFor(String fieldName) {
    try {
      return fieldOptions.firstWhere((f) => f.fieldName == fieldName).options;
    } catch (_) {
      return [];
    }
  }

  /// Check if a field is required
  bool isFieldRequired(String fieldName) {
    try {
      return fieldOptions.firstWhere((f) => f.fieldName == fieldName).isRequired;
    } catch (_) {
      return false;
    }
  }

  /// Get a specific field option model
  FieldOptionModel? getField(String fieldName) {
    try {
      return fieldOptions.firstWhere((f) => f.fieldName == fieldName);
    } catch (_) {
      return null;
    }
  }
}

class FieldOptionsError extends FieldOptionsState {
  final String message;

  FieldOptionsError(this.message);
}

class FieldOptionActionInProgress extends FieldOptionsState {
  final List<FieldOptionModel> fieldOptions;

  FieldOptionActionInProgress(this.fieldOptions);
}

class FieldOptionActionSuccess extends FieldOptionsState {
  final List<FieldOptionModel> fieldOptions;
  final String message;

  FieldOptionActionSuccess(this.fieldOptions, this.message);
}
