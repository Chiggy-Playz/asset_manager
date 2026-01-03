import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../profile/bloc/profile_bloc.dart';
import '../../../profile/bloc/profile_state.dart';
import '../../bloc/users_bloc.dart';
import '../../bloc/users_event.dart';
import '../../bloc/users_state.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  @override
  void initState() {
    super.initState();
    context.read<UsersBloc>().add(UsersFetchRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UsersBloc, UsersState>(
      listener: (context, state) {
        if (state is UserActionSuccess) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        } else if (state is UsersError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Users')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showInviteDialog(context),
            icon: const Icon(Icons.person_add),
            label: const Text('Invite'),
          ),
          body: _buildContent(context, state),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, UsersState state) {
    if (state is UsersLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final users = switch (state) {
      UsersLoaded s => s.users,
      UserActionInProgress s => s.users,
      UserActionSuccess s => s.users,
      _ => <dynamic>[],
    };

    if (users.isEmpty) {
      return const Center(child: Text('No users found'));
    }

    final sortedUsers = List.of(users)
      ..sort((a, b) {
        if (a.isActive == b.isActive) {
          return a.name.compareTo(b.name);
        }
        return a.isActive ? -1 : 1;
      });

    final currentUserId = _getCurrentUserId(context);
    final actionUserId = state is UserActionInProgress
        ? state.actionUserId
        : null;

    return RefreshIndicator(
      onRefresh: () async {
        context.read<UsersBloc>().add(UsersFetchRequested());
      },
      child: ListView.builder(
        itemCount: sortedUsers.length + 1,
        itemBuilder: (context, index) {
          if (index == sortedUsers.length) {
            return const SizedBox(height: 24);
          }
          final user = sortedUsers[index];
          final isCurrentUser = user.id == currentUserId;
          final isActionInProgress = actionUserId == user.id;

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: user.isActive
                  ? null
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                style: user.isActive
                    ? null
                    : TextStyle(color: Theme.of(context).colorScheme.outline),
              ),
            ),
            title: Text(
              user.name,
              style: user.isActive
                  ? null
                  : TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
            subtitle: Row(
              children: [
                Text(
                  user.role,
                  style: user.isActive
                      ? null
                      : TextStyle(color: Theme.of(context).colorScheme.outline),
                ),
                if (!user.isActive) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Inactive',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            trailing: isCurrentUser
                ? const Chip(label: Text('You'))
                : isActionInProgress
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : PopupMenuButton<String>(
                    onSelected: (value) =>
                        _handleUserAction(context, value, user.id),
                    itemBuilder: (context) => [
                      if (user.isActive)
                        const PopupMenuItem(
                          value: 'disable',
                          child: Row(
                            children: [
                              Icon(Icons.block),
                              SizedBox(width: 8),
                              Text('Disable User'),
                            ],
                          ),
                        )
                      else
                        const PopupMenuItem(
                          value: 'enable',
                          child: Row(
                            children: [
                              Icon(Icons.check_circle_outline),
                              SizedBox(width: 8),
                              Text('Enable User'),
                            ],
                          ),
                        ),
                    ],
                  ),
          );
        },
      ),
    );
  }

  String? _getCurrentUserId(BuildContext context) {
    final profileState = context.read<ProfileBloc>().state;
    if (profileState is ProfileLoaded) {
      return profileState.profile.id;
    }
    return null;
  }

  void _handleUserAction(BuildContext context, String action, String userId) {
    if (action == 'disable') {
      _showDisableConfirmation(context, userId);
    } else if (action == 'enable') {
      _showEnableConfirmation(context, userId);
    }
  }

  void _showDisableConfirmation(BuildContext context, String userId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Disable User'),
        content: const Text(
          'Are you sure you want to disable this user? They will no longer be able to sign in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<UsersBloc>().add(UserBanRequested(userId));
            },
            child: const Text('Disable'),
          ),
        ],
      ),
    );
  }

  void _showEnableConfirmation(BuildContext context, String userId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Enable User'),
        content: const Text(
          'Are you sure you want to enable this user? They will be able to sign in again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<UsersBloc>().add(UserUnbanRequested(userId));
            },
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }

  void _showInviteDialog(BuildContext context) {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Invite User'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'Enter email address',
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter an email';
              }
              if (!RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(dialogContext).pop();
                context.read<UsersBloc>().add(
                  UserInviteRequested(emailController.text.trim()),
                );
              }
            },
            child: const Text('Send Invite'),
          ),
        ],
      ),
    );
  }
}
