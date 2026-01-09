import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/asset_search_filter.dart';
import '../../../data/repositories/assets_repository.dart';
import 'search_event.dart';
import 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final AssetsRepository _assetsRepository;

  // Cache the current filter for persistence within session
  AssetSearchFilter _currentFilter = const AssetSearchFilter.empty();

  SearchBloc({required AssetsRepository assetsRepository})
      : _assetsRepository = assetsRepository,
        super(const SearchInitial()) {
    on<SearchFilterChanged>(_onFilterChanged);
    on<SearchRequested>(_onSearchRequested);
    on<SearchPageChanged>(_onPageChanged);
    on<SearchCleared>(_onCleared);
  }

  void _onFilterChanged(
    SearchFilterChanged event,
    Emitter<SearchState> emit,
  ) {
    _currentFilter = event.filter;
    // Don't emit a new state here, just update the cached filter
    // The UI will trigger SearchRequested when ready
  }

  Future<void> _onSearchRequested(
    SearchRequested event,
    Emitter<SearchState> emit,
  ) async {
    emit(SearchLoading(
      filter: _currentFilter,
      results: state.results,
      totalCount: state.totalCount,
      currentPage: 0,
      pageSize: state.pageSize,
    ));

    try {
      final result = await _assetsRepository.searchAssets(
        _currentFilter,
        page: 0,
        pageSize: state.pageSize,
      );

      emit(SearchLoaded(
        filter: _currentFilter,
        results: result.assets,
        totalCount: result.totalCount,
        currentPage: 0,
        pageSize: state.pageSize,
      ));
    } catch (e) {
      emit(SearchError(
        message: e.toString(),
        filter: _currentFilter,
        results: state.results,
        totalCount: state.totalCount,
        currentPage: state.currentPage,
        pageSize: state.pageSize,
      ));
    }
  }

  Future<void> _onPageChanged(
    SearchPageChanged event,
    Emitter<SearchState> emit,
  ) async {
    if (event.page < 0 || event.page >= state.totalPages) {
      return;
    }

    emit(SearchLoading(
      filter: _currentFilter,
      results: state.results,
      totalCount: state.totalCount,
      currentPage: event.page,
      pageSize: state.pageSize,
    ));

    try {
      final result = await _assetsRepository.searchAssets(
        _currentFilter,
        page: event.page,
        pageSize: state.pageSize,
      );

      emit(SearchLoaded(
        filter: _currentFilter,
        results: result.assets,
        totalCount: result.totalCount,
        currentPage: event.page,
        pageSize: state.pageSize,
      ));
    } catch (e) {
      emit(SearchError(
        message: e.toString(),
        filter: _currentFilter,
        results: state.results,
        totalCount: state.totalCount,
        currentPage: state.currentPage,
        pageSize: state.pageSize,
      ));
    }
  }

  void _onCleared(
    SearchCleared event,
    Emitter<SearchState> emit,
  ) {
    _currentFilter = const AssetSearchFilter.empty();
    emit(const SearchInitial());
  }

  /// Get the current filter (for UI to access cached filter).
  AssetSearchFilter get currentFilter => _currentFilter;
}
