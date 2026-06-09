import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:macaque/features/workflow/view_models/workspace_view_model.dart';

class EmptyWorkspaceView extends StatelessWidget {
  const EmptyWorkspaceView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Container(
        padding: const EdgeInsets.all(48),
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: Actions
            Expanded(
              flex: 2,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 48),
                  Icon(
                    Icons.show_chart,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Macaque',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 48),
                  _ActionTile(
                    icon: Icons.add,
                    title: 'New Workflow',
                    description: 'Start building a new automation from scratch',
                    onTap: () => context.read<WorkspaceViewModel>().openWorkflow(
                      'new://workflow/${DateTime.now().millisecondsSinceEpoch}',
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ActionTile(
                    icon: Icons.folder_open,
                    title: 'Open Workflow',
                    description:
                        'Open an existing .swflow or .json workflow file',
                    onTap: () async {
                      final result = await FilePicker.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['swflow', 'json'],
                      );
                      if (result != null && result.files.single.path != null) {
                        if (context.mounted) {
                          await context.read<WorkspaceViewModel>().openWorkflow(
                            result.files.single.path!,
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
            // Divider
            VerticalDivider(width: 64, thickness: 1, color: theme.dividerColor),
            // Right: Recents
            Expanded(
              flex: 3,

              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 48),
                  Text(
                    'Recent Workflows',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Expanded(child: _RecentFilesList()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Icon(icon, size: 32, color: theme.colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: theme.colorScheme.outline),
          ],
        ),
      ),
    );
  }
}

class _RecentFilesList extends StatelessWidget {
  const _RecentFilesList();

  @override
  Widget build(BuildContext context) {
    final workspaceVM = context.watch<WorkspaceViewModel>();
    final theme = Theme.of(context);

    if (workspaceVM.recentFilePaths.isEmpty) {
      return Text(
        'No recent workflows',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.outline,
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: workspaceVM.recentFilePaths.length,
      itemBuilder: (context, index) {
        final path = workspaceVM.recentFilePaths[index];
        final file = File(path);
        final exists = file.existsSync();
        final fileName = p.basename(path);

        return InkWell(
          onTap: exists ? () => workspaceVM.openWorkflow(path) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                Icon(
                  Icons.description_outlined,
                  color: exists
                      ? theme.colorScheme.primary
                      : theme.colorScheme.error,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fileName,
                        style: TextStyle(
                          color: exists ? null : theme.colorScheme.error,
                          decoration: exists
                              ? null
                              : TextDecoration.lineThrough,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        path,
                        style: theme.textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () => workspaceVM.removeRecentFile(path),
                  tooltip: 'Remove from list',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
