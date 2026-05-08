import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui/features/workflow/view_models/workspace_view_model.dart';
import 'package:file_picker/file_picker.dart';

class EmptyWorkspaceView extends StatelessWidget {
  const EmptyWorkspaceView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workspaceVM = context.read<WorkspaceViewModel>();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.work_outline, size: 64, color: theme.colorScheme.primary.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text('No workflow open', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await FilePicker.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['swflow'],
              );
              if (result != null && result.files.single.path != null) {
                await workspaceVM.openWorkflow(result.files.single.path!);
              }
            },
            icon: const Icon(Icons.folder_open),
            label: const Text('Open Workflow'),
          ),
          const SizedBox(height: 24),
          if (workspaceVM.tabs.isEmpty) // Logic for Recently Open (FR-013)
            Text('Recent files (TODO)', style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
