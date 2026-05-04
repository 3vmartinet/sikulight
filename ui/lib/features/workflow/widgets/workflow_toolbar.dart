import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui/features/workflow/services/workflow_persistence.dart';
import 'package:ui/features/workflow/view_models/workflow_view_model.dart';
import 'package:ui/features/workflow/services/workflow_engine.dart';

class WorkflowToolbar extends StatelessWidget implements PreferredSizeWidget {
  const WorkflowToolbar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<WorkflowViewModel>();
    final engine = context.watch<WorkflowEngine>();

    return AppBar(
      title: const Text('Visual Workflow Builder'),
      actions: [
        _ElapsedTimeDisplay(engine: engine),
        const VerticalDivider(),
        IconButton(
          icon: const Icon(Icons.undo),
          onPressed: viewModel.undo,
          tooltip: 'Undo',
        ),
        IconButton(
          icon: const Icon(Icons.redo),
          onPressed: viewModel.redo,
          tooltip: 'Redo',
        ),
        const VerticalDivider(),
        IconButton(
          icon: const Icon(Icons.play_arrow, color: Colors.green),
          onPressed: engine.status == WorkflowStatus.running
              ? null
              : viewModel.runWorkflow,
          tooltip: 'Run Workflow',
        ),
        IconButton(
          icon: const Icon(Icons.stop, color: Colors.red),
          onPressed: engine.status == WorkflowStatus.running
              ? viewModel.stopWorkflow
              : null,
          tooltip: 'Stop Workflow',
        ),
        const VerticalDivider(),
        IconButton(
          icon: const Icon(Icons.save),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Workflow draft saved.')),
            );
          },
          tooltip: 'Save Draft',
        ),
        IconButton(
          icon: const Icon(Icons.file_download),
          onPressed: () async {
            final fileNameController = TextEditingController();
            final persistence = context.read<WorkflowPersistence>();
            final result = await showDialog<String>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Import Workflow'),
                content: TextField(
                  controller: fileNameController,
                  decoration: const InputDecoration(hintText: 'Enter filename (e.g., exported_workflow.swflow)'),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, fileNameController.text),
                    child: const Text('Import'),
                  ),
                ],
              ),
            );

            if (result != null && result.isNotEmpty) {
              final dir = await persistence.localDirectory;
              await viewModel.importWorkflow(File('${dir.path}/$result'));
            }
          },
          tooltip: 'Import',
        ),
        IconButton(
          icon: const Icon(Icons.file_upload),
          onPressed: () async {
            final scaffoldMessenger = ScaffoldMessenger.of(context);
            final workflowPersistence = context.read<WorkflowPersistence>();
            
            await viewModel.exportWorkflow();
            final dir = await workflowPersistence.localDirectory;
            
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text('Exported as ${WorkflowPersistence.exportedFileName} to: ${dir.path}'),
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Open Folder',
                  onPressed: () async {
                    if (Platform.isMacOS) {
                      await Process.run('open', [dir.path]);
                    } else if (Platform.isLinux) {
                      await Process.run('xdg-open', [dir.path]);
                    }
                  },
                ),
              ),
            );
          },
          tooltip: 'Export',
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: viewModel.resetWorkflow,
          tooltip: 'Reset',
        ),
      ],
    );
  }
}

class _ElapsedTimeDisplay extends StatefulWidget {
  final WorkflowEngine engine;

  const _ElapsedTimeDisplay({required this.engine});

  @override
  State<_ElapsedTimeDisplay> createState() => _ElapsedTimeDisplayState();
}

class _ElapsedTimeDisplayState extends State<_ElapsedTimeDisplay> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted && widget.engine.status == WorkflowStatus.running) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final elapsedTime = widget.engine.elapsedTime;
    final minutes = elapsedTime.inMinutes.toString().padLeft(2, '0');
    final seconds = (elapsedTime.inSeconds % 60).toString().padLeft(2, '0');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: Text(
          '$minutes:$seconds',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
