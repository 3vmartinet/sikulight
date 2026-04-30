import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui/features/tasks/task_provider.dart';

class TaskCreateView extends StatefulWidget {
  const TaskCreateView({super.key});

  @override
  State<TaskCreateView> createState() => _TaskCreateViewState();
}

class _TaskCreateViewState extends State<TaskCreateView> {
  final _nameController = TextEditingController();
  final _pathController = TextEditingController();
  String _selectedAction = 'CLICK';

  @override
  void dispose() {
    _nameController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Task')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _TaskFormFields(
              nameController: _nameController,
              pathController: _pathController,
              selectedAction: _selectedAction,
              onActionChanged: (val) => setState(() => _selectedAction = val!),
            ),
            const SizedBox(height: 20),
            _SubmitButton(
              onPressed: _handleSubmit,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    final task = {
      'name': _nameController.text,
      'reference_image_path': _pathController.text,
      'profile': {
        'mode': 'STANDARD',
        'standard_action': _selectedAction,
        'confidence_threshold': 0.8,
        'timeout_seconds': 30,
      }
    };
    
    final result = await context.read<TaskProvider>().runTask(task);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Done')),
      );
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
            DropdownMenuItem(value: 'DOUBLE_CLICK', child: Text('DOUBLE_CLICK')),
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

class _SubmitButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _SubmitButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final isBusy = context.select<TaskProvider, bool>((p) => p.isBusy);

    return ElevatedButton(
      onPressed: isBusy ? null : onPressed,
      child: isBusy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text('Run Task'),
    );
  }
}
