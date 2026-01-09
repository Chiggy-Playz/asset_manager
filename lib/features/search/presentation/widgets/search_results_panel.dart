import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../router/routes.dart';
import '../../../assets/presentation/widgets/asset_card.dart';
import '../../bloc/search_state.dart';

class SearchResultsPanel extends StatelessWidget {
  final SearchState state;
  final ValueChanged<int> onPageChanged;

  const SearchResultsPanel({
    super.key,
    required this.state,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Results header
        _buildResultsHeader(context),
        const SizedBox(height: 16),
        // Results content
        Expanded(child: _buildResultsContent(context)),
        // Pagination
        if (state.totalCount > 0) ...[
          const SizedBox(height: 16),
          _buildPagination(context),
        ],
      ],
    );
  }

  Widget _buildResultsHeader(BuildContext context) {
    final theme = Theme.of(context);

    if (state is SearchInitial) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Icon(Icons.inventory_2, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 8),
          Text(
            'Found: ${state.totalCount} asset${state.totalCount == 1 ? '' : 's'}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          if (state is SearchLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  Widget _buildResultsContent(BuildContext context) {
    final theme = Theme.of(context);

    if (state is SearchInitial) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'Set your filters and click Search',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Use the filters on the left to narrow down your search',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    if (state is SearchLoading && state.results.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is SearchError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Search failed',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              (state as SearchError).message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (state.results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: state.results.length,
      itemBuilder: (context, index) {
        final asset = state.results[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: AssetCard(
            asset: asset,
            isSelected: false,
            isLoading: false,
            onTap: () {
              context.push(Routes.assetDetailPath(asset.id));
            },
          ),
        );
      },
    );
  }

  Widget _buildPagination(BuildContext context) {
    final theme = Theme.of(context);
    final totalPages = state.totalPages;
    final currentPage = state.currentPage;

    if (totalPages <= 1) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Previous button
        IconButton(
          onPressed: currentPage > 0
              ? () => onPageChanged(currentPage - 1)
              : null,
          icon: const Icon(Icons.chevron_left),
        ),
        // Page info
        Text(
          'Page ${currentPage + 1} of $totalPages',
          style: theme.textTheme.bodyMedium,
        ),
        // Next button
        IconButton(
          onPressed: currentPage < totalPages - 1
              ? () => onPageChanged(currentPage + 1)
              : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}
