import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui/features/tasks/task_provider.dart';
import 'package:ui/features/tasks/task_create_view.dart';
import 'package:ui/features/tasks/task_command.dart';
import 'package:ui/features/workflow/workflow_screen.dart';

class TaskMonitorView extends StatelessWidget {
  const TaskMonitorView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_tree),
            onPressed: () => WorkflowScreen.show(context),
          ),
          const _RefreshButton(),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => TaskCreateSheet.show(context),
          ),
        ],
      ),
      body: const Row(
        children: [
          Expanded(flex: 1, child: _PersistedCommandsList()),
          VerticalDivider(width: 1),
          Expanded(flex: 2, child: _StatusDisplay()),
        ],
      ),
    );
  }
}

class _RefreshButton extends StatelessWidget {
  const _RefreshButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.refresh),
      onPressed: () => context.read<TaskProvider>().fetchStatus(),
    );
  }
}

class _StatusDisplay extends StatelessWidget {
  const _StatusDisplay();

  @override
  Widget build(BuildContext context) {
    final status = context.select<TaskProvider, Map<String, dynamic>?>(
      (provider) => provider.engineStatus,
    );
    final isBusy = context.select<TaskProvider, bool>(
      (provider) => provider.isBusy,
    );

    if (status == null) {
      return const Center(child: Text('Loading engine status...'));
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Engine Status: ${status['status']}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (status['current_task_id'] != null)
          Text(
            'Running Task: ${status['current_task_id']}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        const SizedBox(height: 20),
        if (isBusy) const _AbortButton(),
      ],
    );
  }
}

class _PersistedCommandsList extends StatelessWidget {
  const _PersistedCommandsList();

  @override
  Widget build(BuildContext context) {
    final commands = context.select<TaskProvider, List<TaskCommand>>(
      (provider) => provider.persistedCommands,
    );

    return ListView.builder(
      itemCount: commands.length,
      itemBuilder: (context, index) {
        final command = commands[index];
        return Dismissible(
          key: ValueKey(command),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Theme.of(context).colorScheme.error,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            child: Icon(
              Icons.delete,
              color: Theme.of(context).colorScheme.onError,
            ),
          ),
          onDismissed: (_) {
            context.read<TaskProvider>().deleteCommand(command);
          },
          child: ListTile(
            leading: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                width: 48,
                height: 48,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.file(
                    File(command.referenceImagePath),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.image_not_supported),
                  ),
                ),
              ),
            ),
            title: Text(command.name),
            subtitle: Text(command.profile.standardAction),
            trailing: IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () => context.read<TaskProvider>().runTask(command),
            ),
            onTap: () => TaskCreateSheet.show(context, task: command),
          ),
        );
      },
    );
  }
}

class _AbortButton extends StatelessWidget {
  const _AbortButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ElevatedButton(
        onPressed: () => context.read<TaskProvider>().abort(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.error,
          foregroundColor: Theme.of(context).colorScheme.onError,
        ),
        child: const Text('Abort Task'),
      ),
    );
  }
}
