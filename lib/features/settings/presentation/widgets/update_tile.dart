import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_filex/open_filex.dart';

import '../../../../data/repositories/update_repository.dart';
import '../../bloc/update_bloc.dart';
import '../../bloc/update_event.dart';
import '../../bloc/update_state.dart';

class UpdateTile extends StatelessWidget {
  const UpdateTile({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          UpdateBloc(updateRepository: UpdateRepository())
            ..add(UpdateCheckRequested()),
      child: BlocBuilder<UpdateBloc, UpdateState>(
        builder: (context, state) {
          final (icon, title, subtitle, trailing, onTap) = switch (state) {
            UpdateInitial() || UpdateChecking() => (
              _progress(),
              'Checking for updates...',
              null,
              null,
              null,
            ),
            UpdateAvailable(:final updateInfo) => (
              Badge(child: const Icon(Icons.system_update)),
              'Update available',
              'Version ${updateInfo.versionName}',
              const Icon(Icons.download),
              () => context.read<UpdateBloc>().add(UpdateDownloadRequested()),
            ),
            UpdateNotAvailable() => (
              const Icon(Icons.check_circle_outline),
              'App is up to date',
              null,
              null,
              () => context.read<UpdateBloc>().add(UpdateCheckRequested()),
            ),
            UpdateDownloading(:final progress) => (
              _progress(progress),
              'Downloading update...',
              '${(progress * 100).toStringAsFixed(0)}%',
              null,
              null,
            ),
            UpdateDownloaded(:final filePath) => (
              const Icon(Icons.check_circle),
              'Update downloaded',
              'Tap to install',
              null,
              () => _install(context, filePath),
            ),
            UpdateError(:final message) => (
              const Icon(Icons.error_outline),
              'Update check failed',
              message,
              const Icon(Icons.refresh),
              () => context.read<UpdateBloc>().add(UpdateCheckRequested()),
            ),
          };

          return ListTile(
            leading: icon,
            title: Text(title),
            subtitle: subtitle != null
                ? Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis)
                : null,
            trailing: trailing,
            onTap: onTap,
          );
        },
      ),
    );
  }

  static Widget _progress([double? value]) => SizedBox(
    width: 24,
    height: 24,
    child: CircularProgressIndicator(value: value, strokeWidth: 2),
  );

  static Future<void> _install(BuildContext context, String path) async {
    final result = await OpenFilex.open(path);
    if (result.type != ResultType.done && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open installer: ${result.message}')),
      );
    }
  }
}
