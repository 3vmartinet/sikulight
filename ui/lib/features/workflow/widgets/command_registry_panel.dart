import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui/features/tasks/task_provider.dart';
import 'package:ui/features/workflow/view_models/workflow_view_model.dart';
import 'package:ui/features/workflow/models/workflow_models.dart';
import 'package:uuid/uuid.dart';

class CommandRegistryPanel extends StatelessWidget {
  const CommandRegistryPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final workflowViewModel = context.read<WorkflowViewModel>();

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        border: Border(
          right: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.centerLeft,
            child: Text(
              'Commands Registry',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: taskProvider.persistedCommands.length,
              itemBuilder: (context, index) {
                final command = taskProvider.persistedCommands[index];
                return ListTile(
                  title: Text(command.name),
                  subtitle: Text(command.profile.standardAction),
                  trailing: const Icon(Icons.add),
                  onTap: () {
                    final node = VdaActionNode(
                      id: const Uuid().v4(),
                      position: const Offset(100, 100),
                      command: command,
                    );
                    workflowViewModel.addNode(node);
                  },
                );
              },
            ),
          ),
          const Divider(),
          _SystemNodesList(viewModel: workflowViewModel),
        ],
      ),
    );
  }
}

class _SystemNodesList extends StatelessWidget {
  final WorkflowViewModel viewModel;

  const _SystemNodesList({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: const Text('Wait Node'),
          leading: const Icon(Icons.timer),
          onTap: () => viewModel.addNode(
            WaitNode(
              id: const Uuid().v4(),
              position: const Offset(100, 100),
              durationSeconds: 5,
            ),
          ),
        ),
        ListTile(
          title: const Text('Exist Node'),
          leading: const Icon(Icons.visibility),
          onTap: () => viewModel.addNode(
            ExistNode(
              id: const Uuid().v4(),
              position: const Offset(100, 100),
              referenceImagePath: '',
            ),
          ),
        ),
      ],
    );
  }
}
