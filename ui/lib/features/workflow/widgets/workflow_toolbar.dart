import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui/features/workflow/view_models/workflow_view_model.dart';
import 'package:ui/features/workflow/view_models/workspace_view_model.dart';
import 'package:ui/features/workflow/services/workflow_engine.dart';
import 'package:ui/features/workflow/models/workflow_models.dart' as models;

class WorkflowToolbar extends StatelessWidget implements PreferredSizeWidget {
  const WorkflowToolbar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<WorkflowViewModel>();
    final engine = context.watch<WorkflowEngine>();

    return AppBar(
      elevation: 8,
      leading: const Icon(Icons.show_chart),
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
          onPressed:
              (engine.status == WorkflowStatus.running ||
                  !viewModel.controller.nodes.values.any(
                    (n) => n.data is models.StartNode,
                  ))
              ? null
              : viewModel.runWorkflow,
          tooltip:
              !viewModel.controller.nodes.values.any(
                (n) => n.data is models.StartNode,
              )
              ? 'Add a Start Node to execute workflow'
              : 'Run Workflow',
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
          onPressed: () async {
            final scaffoldMessenger = ScaffoldMessenger.of(context);
            await viewModel.saveToFile();
            final path = viewModel.resolvedPath ?? 'internal draft';
            scaffoldMessenger.showSnackBar(
              SnackBar(content: Text('Saved: $path')),
            );
          },
          tooltip: 'Save',
        ),
        IconButton(
          icon: const Icon(Icons.file_open),
          onPressed: () async {
            final workspaceVM = context.read<WorkspaceViewModel>();
            final result = await FilePicker.pickFiles(
              type: FileType.custom,
              allowedExtensions: ['swflow', 'json'],
            );

            if (result != null && result.files.single.path != null) {
              await workspaceVM.openWorkflow(result.files.single.path!);
            }
          },
          tooltip: 'Import',
        ),
        IconButton(
          icon: const Icon(Icons.save_alt),
          onPressed: () async {
            final scaffoldMessenger = ScaffoldMessenger.of(context);

            final String? outputFile = await FilePicker.saveFile(
              dialogTitle: 'Export Workflow',
              fileName: 'exported_workflow.swflow',
              type: FileType.custom,
              allowedExtensions: ['swflow'],
            );

            if (outputFile != null) {
              await viewModel.exportWorkflow(File(outputFile));
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text('Workflow exported to: $outputFile'),
                  duration: const Duration(seconds: 3),
                ),
              );
            }
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
