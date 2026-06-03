import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sikulite/features/workflow/models/workspace_models.dart';
import 'package:sikulite/features/workflow/view_models/workspace_view_model.dart';
import 'package:sikulite/features/workflow/view_models/workflow_view_model.dart';

class WorkflowTab extends StatelessWidget {
  final TabMetadata tab;
  final bool isActive;

  const WorkflowTab({super.key, required this.tab, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workspaceVM = context.read<WorkspaceViewModel>();
    final isModified = context.select<WorkflowViewModel, bool>(
      (vm) => vm.isModified,
    );
    final resolvedPath = context.select<WorkflowViewModel, String?>(
      (vm) => vm.resolvedPath,
    );

    return Tooltip(
      message: resolvedPath ?? tab.filePath ?? 'Draft: ${tab.id}',
      waitDuration: const Duration(seconds: 1),
      child: InkWell(
        onTap: () => workspaceVM.selectTab(workspaceVM.tabs.indexOf(tab)),
        onSecondaryTapDown: (details) {
          final position = details.globalPosition;
          showMenu<dynamic>(
            context: context,
            position: RelativeRect.fromLTRB(
              position.dx,
              position.dy,
              position.dx,
              position.dy,
            ),
            items: <PopupMenuEntry<dynamic>>[
              PopupMenuItem(
                onTap: () {
                  final controller = TextEditingController(text: tab.name);
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Rename Workflow'),
                      content: TextField(
                        controller: controller,
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: 'Enter new name',
                        ),
                        onSubmitted: (value) {
                          if (value.trim().isNotEmpty) {
                            workspaceVM.renameWorkflow(tab.id, value);
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            if (controller.text.trim().isNotEmpty) {
                              workspaceVM.renameWorkflow(
                                tab.id,
                                controller.text,
                              );
                              Navigator.of(context).pop();
                            }
                          },
                          child: const Text('Rename'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18),
                    SizedBox(width: 12),
                    Text('Rename'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                onTap: () => workspaceVM.closeTab(tab.id),
                child: const Row(
                  children: [
                    Icon(Icons.close, size: 18),
                    SizedBox(width: 12),
                    Text('Close'),
                  ],
                ),
              ),
              PopupMenuItem(
                onTap: () {
                  final tabsToClose = workspaceVM.tabs
                      .where((t) => t.id != tab.id)
                      .toList();
                  for (final t in tabsToClose) {
                    workspaceVM.closeTab(t.id);
                  }
                },
                child: const Row(
                  children: [
                    Icon(Icons.tab_unselected, size: 18),
                    SizedBox(width: 12),
                    Text('Close Others'),
                  ],
                ),
              ),
              PopupMenuItem(
                onTap: () {
                  final index = workspaceVM.tabs.indexOf(tab);
                  final tabsToClose = workspaceVM.tabs.sublist(index + 1);
                  for (final t in tabsToClose) {
                    workspaceVM.closeTab(t.id);
                  }
                },
                child: const Row(
                  children: [
                    Icon(Icons.keyboard_tab, size: 18),
                    SizedBox(width: 12),
                    Text('Close Tabs to the Right'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                onTap: () {
                  final pathToCopy = resolvedPath ?? tab.filePath;
                  if (pathToCopy != null) {
                    Clipboard.setData(ClipboardData(text: pathToCopy));
                  }
                },
                child: const Row(
                  children: [
                    Icon(Icons.copy, size: 18),
                    SizedBox(width: 12),
                    Text('Copy File Path'),
                  ],
                ),
              ),
            ],
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? theme.colorScheme.surface
                : theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
            border: Border(
              right: BorderSide(color: theme.dividerColor),
              bottom: isActive
                  ? BorderSide.none
                  : BorderSide(color: theme.dividerColor),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Reorder Handle
              MouseRegion(
                cursor: SystemMouseCursors.grab,
                child: ReorderableDragStartListener(
                  index: context.read<WorkspaceViewModel>().tabs.indexOf(tab),
                  child: Icon(
                    Icons.drag_indicator,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 4), // Modified State Indicator
              if (isModified)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    Icons.circle,
                    size: 8,
                    color: theme.colorScheme.primary,
                  ),
                ),
              Flexible(
                fit: FlexFit.loose,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 150),
                  child: Text(
                    tab.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isActive
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => workspaceVM.closeTab(tab.id),
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
