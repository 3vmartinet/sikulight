import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui/features/workflow/view_models/workspace_view_model.dart';
import 'package:ui/features/workflow/widgets/workflow_tab.dart';

class WorkflowTabBar extends StatelessWidget {
  const WorkflowTabBar({super.key});

  @override
  Widget build(BuildContext context) {
    final workspaceVM = context.watch<WorkspaceViewModel>();
    final theme = Theme.of(context);

    if (workspaceVM.tabs.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: ReorderableListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: workspaceVM.tabs.length,
        onReorder: workspaceVM.reorderTabs,
        proxyDecorator: (child, index, animation) {
          return AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return Material(
                elevation: 4,
                color: Colors.transparent,
                child: child,
              );
            },
            child: child,
          );
        },
        itemBuilder: (context, index) {
          final tab = workspaceVM.tabs[index];
          return ChangeNotifierProvider.value(
            key: ValueKey(tab.id),
            value: tab.viewModel,
            child: WorkflowTab(
              tab: tab,
              isActive: workspaceVM.activeTabIndex == index,
            ),
          );
        },
      ),
    );
  }
}
