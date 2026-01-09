import '../../../data/models/asset_search_filter.dart';

sealed class SearchEvent {}

/// Update the current search filter.
class SearchFilterChanged extends SearchEvent {
  final AssetSearchFilter filter;
  SearchFilterChanged(this.filter);
}

/// Execute search with current filter.
class SearchRequested extends SearchEvent {}

/// Change the current page.
class SearchPageChanged extends SearchEvent {
  final int page;
  SearchPageChanged(this.page);
}

/// Clear all filters and reset to initial state.
class SearchCleared extends SearchEvent {}
