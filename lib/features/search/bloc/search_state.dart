import '../../../data/models/asset_model.dart';
import '../../../data/models/asset_search_filter.dart';

sealed class SearchState {
  final AssetSearchFilter filter;
  final List<AssetModel> results;
  final int totalCount;
  final int currentPage;
  final int pageSize;

  const SearchState({
    required this.filter,
    this.results = const [],
    this.totalCount = 0,
    this.currentPage = 0,
    this.pageSize = 25,
  });

  bool get hasResults => results.isNotEmpty;
  bool get hasMoreResults => (currentPage + 1) * pageSize < totalCount;
  int get totalPages => pageSize > 0 ? (totalCount / pageSize).ceil() : 0;
}

/// Initial state - no search performed yet.
class SearchInitial extends SearchState {
  const SearchInitial()
      : super(filter: const AssetSearchFilter.empty());
}

/// Loading state - search in progress.
class SearchLoading extends SearchState {
  SearchLoading({
    required super.filter,
    super.results,
    super.totalCount,
    super.currentPage,
    super.pageSize,
  });
}

/// Loaded state - search completed successfully.
class SearchLoaded extends SearchState {
  SearchLoaded({
    required super.filter,
    required super.results,
    required super.totalCount,
    required super.currentPage,
    super.pageSize,
  });
}

/// Error state - search failed.
class SearchError extends SearchState {
  final String message;

  SearchError({
    required this.message,
    required super.filter,
    super.results,
    super.totalCount,
    super.currentPage,
    super.pageSize,
  });
}
