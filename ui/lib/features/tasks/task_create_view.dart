import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:ui/features/tasks/task_provider.dart';
import 'package:ui/features/tasks/task_command.dart';
import 'package:ui/core/api_client.dart';

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
  late final TextEditingController _xController;
  late final TextEditingController _yController;
  late final TextEditingController _scrollController;
  late String _selectedAction;
  bool _isCaptured = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final task = widget.initialTask;
    _nameController = TextEditingController(text: task?.name ?? '');
    _pathController = TextEditingController(
      text: task?.referenceImagePath ?? '',
    );
    _selectedAction = task?.profile.standardAction ?? 'CLICK';
    _scrollController = TextEditingController(
      text: task?.profile.scrollMagnitude?.toString() ?? '0',
    );
    _xController = TextEditingController(
      text: task?.profile.x?.toString() ?? '',
    );
    _yController = TextEditingController(
      text: task?.profile.y?.toString() ?? '',
    );

    if (task != null) {
      _isCaptured = true;
    }
    _startContinuousCapture();
  }

  void _startContinuousCapture() {
    Map<String, int>? lastPos;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (mounted && !_isCaptured && _selectedAction == 'SCROLL') {
        try {
          final pos = await ApiClient().getCursorPosition();
          if (mounted && !_isCaptured) {
            final x = pos['x'] as int;
            final y = pos['y'] as int;
            if (lastPos == null ||
                lastPos!['x'] != x ||
                lastPos!['y'] != y) {
              _xController.text = x.toString();
              _yController.text = y.toString();
              lastPos = {'x': x, 'y': y};
            }
          }
        } catch (_) {}
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _nameController.dispose();
    _pathController.dispose();
    _xController.dispose();
    _yController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        const SingleActivator(LogicalKeyboardKey.keyL, control: true):
            const CaptureIntent(),
      },
      child: Actions(
        actions: {
          CaptureIntent: CallbackAction<CaptureIntent>(
            onInvoke: (CaptureIntent intent) =>
                setState(() => _isCaptured = !_isCaptured),
          ),
        },
        child: Focus(
          autofocus: true,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
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
                  _TaskFormFields(
                    nameController: _nameController,
                    pathController: _pathController,
                    xController: _xController,
                    yController: _yController,
                    scrollController: _scrollController,
                    selectedAction: _selectedAction,
                    isCaptured: _isCaptured,
                    onActionChanged: (val) =>
                        setState(() => _selectedAction = val!),
                  ),
                  const SizedBox(height: 24),
                  _ActionButtons(onTry: _handleTry, onSave: _handleSave),
                ],
              ),
            ),
          ),
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
        scrollMagnitude: int.tryParse(_scrollController.text),
        x: int.tryParse(_xController.text),
        y: int.tryParse(_yController.text),
      ),
    );
  }

  Future<void> _handleTry() async {
    final task = _buildTask();
    final result = await context.read<TaskProvider>().runTask(task);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
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

class CaptureIntent extends Intent {
  const CaptureIntent();
}

class _TaskFormFields extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController pathController;
  final TextEditingController xController;
  final TextEditingController yController;
  final TextEditingController scrollController;
  final String selectedAction;
  final ValueChanged<String?> onActionChanged;
  final bool isCaptured;

  const _TaskFormFields({
    required this.nameController,
    required this.pathController,
    required this.xController,
    required this.yController,
    required this.scrollController,
    required this.selectedAction,
    required this.onActionChanged,
    required this.isCaptured,
  });

  @override
  State<_TaskFormFields> createState() => _TaskFormFieldsState();
}

class _TaskFormFieldsState extends State<_TaskFormFields> {
  @override
  Widget build(BuildContext context) {
    final isScroll = widget.selectedAction == 'SCROLL';
    return Column(
      children: [
        TextField(
          controller: widget.nameController,
          decoration: const InputDecoration(labelText: 'Task Name'),
        ),
        if (!isScroll)
          TextField(
            controller: widget.pathController,
            decoration: const InputDecoration(
              labelText: 'Reference Image Path',
            ),
          ),
        DropdownButtonFormField<String>(
          initialValue: widget.selectedAction,
          items: const [
            DropdownMenuItem(value: 'CLICK', child: Text('CLICK')),
            DropdownMenuItem(
              value: 'DOUBLE_CLICK',
              child: Text('DOUBLE_CLICK'),
            ),
            DropdownMenuItem(value: 'RIGHT_CLICK', child: Text('RIGHT_CLICK')),
            DropdownMenuItem(value: 'HOVER', child: Text('HOVER')),
            DropdownMenuItem(
              value: 'MIDDLE_CLICK',
              child: Text('MIDDLE_CLICK'),
            ),
            DropdownMenuItem(value: 'SCROLL', child: Text('SCROLL')),
          ],
          onChanged: widget.onActionChanged,
          decoration: const InputDecoration(labelText: 'Action'),
        ),
        if (isScroll) ...[
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.xController,
                  decoration: const InputDecoration(labelText: 'X'),
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    color: widget.isCaptured ? Colors.green : null,
                    fontWeight: widget.isCaptured ? FontWeight.bold : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: widget.yController,
                  decoration: const InputDecoration(labelText: 'Y'),
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    color: widget.isCaptured ? Colors.green : null,
                    fontWeight: widget.isCaptured ? FontWeight.bold : null,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Scroll Magnitude'),
          Slider(
            value: (double.tryParse(widget.scrollController.text) ?? 0).clamp(
              -50.0,
              50.0,
            ),
            min: -50,
            max: 50,
            divisions: 100,
            label: widget.scrollController.text,
            onChanged: (double value) {
              setState(() {
                widget.scrollController.text = value.round().toString();
              });
            },
          ),
        ],
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final VoidCallback onTry, onSave;
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
