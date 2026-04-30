import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:ui/features/tasks/task_provider.dart';
import 'package:ui/features/tasks/task_command.dart';

class TaskCreateSheet extends StatefulWidget {
  final TaskCommand? initialTask;

  const TaskCreateSheet({super.key, this.initialTask});

  static Future<void> show(BuildContext context, {TaskCommand? task}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => TaskCreateSheet(initialTask: task),
    );
  }

  @override
  State<TaskCreateSheet> createState() => _TaskCreateSheetState();
}

class _TaskCreateSheetState extends State<TaskCreateSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _pathController;
  late String _selectedAction;

  @override
  void initState() {
    super.initState();
    final task = widget.initialTask;
    _nameController = TextEditingController(text: task?.name ?? '');
    _pathController = TextEditingController(
      text: task?.referenceImagePath ?? '',
    );
    _selectedAction = task?.profile.standardAction ?? 'CLICK';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        bottom: bottomPadding,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.initialTask == null ? 'Create Task' : 'Edit Task',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _TaskFormFields(
              nameController: _nameController,
              pathController: _pathController,
              selectedAction: _selectedAction,
              onActionChanged: (val) => setState(() => _selectedAction = val!),
            ),
            const SizedBox(height: 24),
            _ActionButtons(onTry: _handleTry, onSave: _handleSave),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  TaskCommand _buildTask() {
    return TaskCommand(
      name: _nameController.text,
      referenceImagePath: _pathController.text,
      profile: TaskProfile(
        mode: 'STANDARD',
        standardAction: _selectedAction,
        confidenceThreshold: 0.8,
        timeoutSeconds: 30,
      ),
    );
  }

  Future<void> _handleTry() async {
    final task = _buildTask();
    final result = await context.read<TaskProvider>().runTask(task);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Done')));
    }
  }

  Future<void> _handleSave() async {
    final task = _buildTask();

    String finalImagePath = task.referenceImagePath;
    if (finalImagePath.isNotEmpty) {
      final sourceFile = File(finalImagePath);
      if (await sourceFile.exists()) {
        final appDir = await getApplicationDocumentsDirectory();
        final imagesDir = Directory('${appDir.path}/sikulight_images');
        if (!await imagesDir.exists()) {
          await imagesDir.create(recursive: true);
        }

        if (!finalImagePath.startsWith(imagesDir.path)) {
          final fileName =
              '${DateTime.now().millisecondsSinceEpoch}_${sourceFile.uri.pathSegments.last}';
          final targetPath = '${imagesDir.path}/$fileName';
          await sourceFile.copy(targetPath);
          finalImagePath = targetPath;
        }
      }
    }

    final finalTask = TaskCommand(
      name: task.name,
      referenceImagePath: finalImagePath,
      profile: task.profile,
    );

    if (mounted) {
      await context.read<TaskProvider>().saveCommand(
        finalTask,
        oldCommand: widget.initialTask,
      );
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }
}

class _TaskFormFields extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController pathController;
  final String selectedAction;
  final ValueChanged<String?> onActionChanged;

  const _TaskFormFields({
    required this.nameController,
    required this.pathController,
    required this.selectedAction,
    required this.onActionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Task Name'),
        ),
        TextField(
          controller: pathController,
          decoration: const InputDecoration(labelText: 'Reference Image Path'),
        ),
        DropdownButtonFormField<String>(
          value: selectedAction,
          items: const [
            DropdownMenuItem(value: 'CLICK', child: Text('CLICK')),
            DropdownMenuItem(
              value: 'DOUBLE_CLICK',
              child: Text('DOUBLE_CLICK'),
            ),
            DropdownMenuItem(value: 'RIGHT_CLICK', child: Text('RIGHT_CLICK')),
            DropdownMenuItem(value: 'HOVER', child: Text('HOVER')),
          ],
          onChanged: onActionChanged,
          decoration: const InputDecoration(labelText: 'Action'),
        ),
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final VoidCallback onTry;
  final VoidCallback onSave;

  const _ActionButtons({required this.onTry, required this.onSave});

  @override
  Widget build(BuildContext context) {
    final isBusy = context.select<TaskProvider, bool>((p) => p.isBusy);

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: isBusy ? null : onTry,
          child: const Text('Try'),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: isBusy ? null : onSave,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
