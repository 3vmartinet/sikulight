import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:ui/features/workflow/models/workspace_models.dart';
import 'package:ui/features/workflow/view_models/workspace_view_model.dart';
import 'package:ui/features/workflow/view_models/workflow_view_model.dart';

class WorkflowTab extends StatelessWidget {
  final TabMetadata tab;
  final bool isActive;

  const WorkflowTab({
    super.key,
    required this.tab,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workspaceVM = context.read<WorkspaceViewModel>();
    final isModified = context.select<WorkflowViewModel, bool>(
      (vm) => vm.isModified,
    );

    return InkWell(
      onTap: () => workspaceVM.selectTab(
            workspaceVM.tabs.indexOf(tab),
          ),
      onSecondaryTapDown: (details) {
        final position = details.globalPosition;
        showMenu(
          context: context,
          position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
          items: [
            PopupMenuItem(
              onTap: () => workspaceVM.closeTab(tab.id),
              child: const Text('Close'),
            ),
            PopupMenuItem(
              onTap: () {
                final tabsToClose = workspaceVM.tabs.where((t) => t.id != tab.id).toList();
                for (final t in tabsToClose) {
                  workspaceVM.closeTab(t.id);
                }
              },
              child: const Text('Close Others'),
            ),
            PopupMenuItem(
              onTap: () {
                final index = workspaceVM.tabs.indexOf(tab);
                final tabsToClose = workspaceVM.tabs.sublist(index + 1);
                for (final t in tabsToClose) {
                  workspaceVM.closeTab(t.id);
                }
              },
              child: const Text('Close Tabs to the Right'),
            ),
            PopupMenuItem(
              onTap: () {
                if (tab.filePath != null) {
                  Clipboard.setData(ClipboardData(text: tab.filePath!));
                }
              },
              child: const Text('Copy File Path'),
            ),
          ],
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? theme.colorScheme.surface : theme.colorScheme.surfaceVariant.withOpacity(0.5),
          border: Border(
            right: BorderSide(color: theme.dividerColor),
            bottom: isActive ? BorderSide.none : BorderSide(color: theme.dividerColor),
          ),
        ),
        constraints: const BoxConstraints(minWidth: 100, maxWidth: 200),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isModified)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(
                  Icons.circle,
                  size: 8,
                  color: theme.colorScheme.primary,
                ),
              ),
            Flexible(
              child: Text(
                tab.name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
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
    );
  }
}
