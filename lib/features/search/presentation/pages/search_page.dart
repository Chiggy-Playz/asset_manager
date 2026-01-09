import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/responsive.dart';
import '../../../admin/bloc/field_options_bloc.dart';
import '../../../admin/bloc/field_options_event.dart';
import '../../../admin/bloc/field_options_state.dart';
import '../../../admin/bloc/locations_bloc.dart';
import '../../../admin/bloc/locations_event.dart';
import '../../../admin/bloc/locations_state.dart';
import '../../bloc/search_bloc.dart';
import '../../bloc/search_event.dart';
import '../../bloc/search_state.dart';
import '../widgets/search_filter_panel.dart';
import '../widgets/search_results_panel.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  @override
  void initState() {
    super.initState();
    // Load field options and locations for filter dropdowns
    final fieldOptionsBloc = context.read<FieldOptionsBloc>();
    if (fieldOptionsBloc.state is! FieldOptionsLoaded) {
      fieldOptionsBloc.add(FieldOptionsFetchRequested());
    }
    final locationsBloc = context.read<LocationsBloc>();
    final locState = locationsBloc.state;
    final hasLocations = locState is LocationsLoaded && locState.locations.isNotEmpty;
    if (!hasLocations) {
      locationsBloc.add(LocationsFetchRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, screenSize) {
        final isMobile = screenSize == ScreenSize.mobile;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Search Assets'),
            actions: [
              TextButton.icon(
                onPressed: () {
                  context.read<SearchBloc>().add(SearchCleared());
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear'),
              ),
            ],
          ),
          body: isMobile
              ? _buildMobileLayout(context)
              : _buildDesktopLayout(context),
        );
      },
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return BlocBuilder<SearchBloc, SearchState>(
      builder: (context, state) {
        return CustomScrollView(
          slivers: [
            // Filter panel as expandable section
            SliverToBoxAdapter(
              child: ExpansionTile(
                title: const Text('Filters'),
                subtitle: Text(
                  state.filter.isEmpty
                      ? 'No filters applied'
                      : 'Filters applied',
                ),
                leading: const Icon(Icons.filter_list),
                initiallyExpanded: state is SearchInitial,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SearchFilterPanel(
                      filter: state.filter,
                      onFilterChanged: (filter) {
                        context
                            .read<SearchBloc>()
                            .add(SearchFilterChanged(filter));
                      },
                      onSearch: () {
                        context.read<SearchBloc>().add(SearchRequested());
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Results
            SliverFillRemaining(
              child: SearchResultsPanel(
                state: state,
                onPageChanged: (page) {
                  context.read<SearchBloc>().add(SearchPageChanged(page));
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return BlocBuilder<SearchBloc, SearchState>(
      builder: (context, state) {
        return Row(
          children: [
            // Filter panel on the left
            SizedBox(
              width: 320,
              child: Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SearchFilterPanel(
                    filter: state.filter,
                    onFilterChanged: (filter) {
                      context
                          .read<SearchBloc>()
                          .add(SearchFilterChanged(filter));
                    },
                    onSearch: () {
                      context.read<SearchBloc>().add(SearchRequested());
                    },
                  ),
                ),
              ),
            ),
            // Vertical divider
            const VerticalDivider(width: 1),
            // Results panel on the right
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SearchResultsPanel(
                  state: state,
                  onPageChanged: (page) {
                    context.read<SearchBloc>().add(SearchPageChanged(page));
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
