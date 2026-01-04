import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/field_option_model.dart';
import '../../../data/repositories/field_options_repository.dart';
import 'field_options_event.dart';
import 'field_options_state.dart';

class FieldOptionsBloc extends Bloc<FieldOptionsEvent, FieldOptionsState> {
  final FieldOptionsRepository _repository;
  List<FieldOptionModel> _cachedOptions = [];

  FieldOptionsBloc({required FieldOptionsRepository repository})
      : _repository = repository,
        super(FieldOptionsInitial()) {
    on<FieldOptionsFetchRequested>(_onFetchRequested);
    on<FieldOptionUpdateRequested>(_onUpdateRequested);
  }

  Future<void> _onFetchRequested(
    FieldOptionsFetchRequested event,
    Emitter<FieldOptionsState> emit,
  ) async {
    emit(FieldOptionsLoading());
    try {
      final options = await _repository.fetchAll();
      _cachedOptions = options;
      emit(FieldOptionsLoaded(options));
    } catch (e) {
      emit(FieldOptionsError(e.toString()));
    }
  }

  Future<void> _onUpdateRequested(
    FieldOptionUpdateRequested event,
    Emitter<FieldOptionsState> emit,
  ) async {
    emit(FieldOptionActionInProgress(_cachedOptions));
    try {
      await _repository.updateFieldOption(
        event.fieldName,
        options: event.options,
        isRequired: event.isRequired,
      );
      emit(FieldOptionActionSuccess(_cachedOptions, 'Field options updated'));
      add(FieldOptionsFetchRequested());
    } catch (e) {
      emit(FieldOptionsError(e.toString()));
      emit(FieldOptionsLoaded(_cachedOptions));
    }
  }
}
