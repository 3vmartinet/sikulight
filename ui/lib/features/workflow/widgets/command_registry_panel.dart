import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui/features/tasks/task_provider.dart';
import 'package:ui/features/tasks/task_command.dart';

class CommandRegistryPanel extends StatelessWidget {
  const CommandRegistryPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: taskProvider.persistedCommands.length,
            itemBuilder: (context, index) {
              final command = taskProvider.persistedCommands[index];
              return Draggable<TaskCommand>(
                data: command,
                feedback: Material(
                  elevation: 4,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 200),
                    child: ListTile(
                      title: Text(command.name),
                      subtitle: Text(command.profile.standardAction.value),
                    ),
                  ),
                ),
                childWhenDragging: Opacity(
                  opacity: 0.5,
                  child: ListTile(
                    title: Text(command.name),
                    subtitle: Text(command.profile.standardAction.value),
                    trailing: const Icon(Icons.drag_indicator),
                  ),
                ),
                child: ListTile(
                  title: Text(command.name),
                  subtitle: Text(command.profile.standardAction.value),
                  trailing: const Icon(Icons.drag_indicator),
                ),
              );
            },
          ),
        ),
        const Divider(),
        const _SystemNodesList(),
      ],
    );
  }
}

class _SystemNodesList extends StatelessWidget {
  const _SystemNodesList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Draggable<String>(
          data: 'wait_node',
          feedback: Material(
            elevation: 4,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 200),
              child: const ListTile(
                title: Text('Wait Node'),
                leading: Icon(Icons.timer),
              ),
            ),
          ),
          childWhenDragging: const Opacity(
            opacity: 0.5,
            child: ListTile(
              title: Text('Wait Node'),
              leading: Icon(Icons.timer),
              trailing: Icon(Icons.drag_indicator),
            ),
          ),
          child: const ListTile(
            title: Text('Wait Node'),
            leading: Icon(Icons.timer),
            trailing: Icon(Icons.drag_indicator),
          ),
        ),
        Draggable<String>(
          data: 'exist_node',
          feedback: Material(
            elevation: 4,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 200),
              child: const ListTile(
                title: Text('Exist Node'),
                leading: Icon(Icons.visibility),
              ),
            ),
          ),
          childWhenDragging: const Opacity(
            opacity: 0.5,
            child: ListTile(
              title: Text('Exist Node'),
              leading: Icon(Icons.visibility),
              trailing: Icon(Icons.drag_indicator),
            ),
          ),
          child: const ListTile(
            title: Text('Exist Node'),
            leading: Icon(Icons.visibility),
            trailing: Icon(Icons.drag_indicator),
          ),
        ),
      ],
    );
  }
}

