import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui/features/tasks/task_provider.dart';
import 'package:ui/features/tasks/task_create_view.dart';

class TaskMonitorView extends StatelessWidget {
  const TaskMonitorView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SikuLight Dashboard'),
        actions: const [_RefreshButton()],
      ),
      body: const Center(child: _StatusDisplay()),
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
      return const Text('Loading engine status...');
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
        const _NavigateToCreateButton(),
        if (isBusy) const _AbortButton(),
      ],
    );
  }
}

class _NavigateToCreateButton extends StatelessWidget {
  const _NavigateToCreateButton();

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const TaskCreateView()),
      ),
      child: const Text('Add/Run New Task'),
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
