import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui/core/constants.dart';
import 'package:ui/features/assets/widgets/asset_registry_panel.dart';
import 'package:ui/features/workflow/view_models/sidebar_view_model.dart';
import 'package:ui/features/workflow/view_models/workflow_view_model.dart';
import 'package:ui/features/workflow/view_models/workspace_view_model.dart';
import 'package:ui/features/workflow/widgets/workflow_canvas.dart';
import 'package:ui/features/workflow/widgets/workflow_toolbar.dart';
import 'package:ui/features/workflow/widgets/workflow_tab_bar.dart';
import 'package:ui/features/workflow/widgets/empty_workspace_view.dart';
import 'package:ui/features/workflow/widgets/command_registry_panel.dart';
import 'package:ui/features/workflow/widgets/node_parameter_panel.dart';
import 'package:ui/features/workflow/widgets/expandable_panel.dart';

class WorkflowScreen extends StatelessWidget {
  const WorkflowScreen({super.key});

  static void show(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const WorkflowScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return const _WorkflowScreenBody();
  }
}

class _WorkflowScreenBody extends StatelessWidget {
  const _WorkflowScreenBody();

  @override
  Widget build(BuildContext context) {
    final workspaceVM = context.watch<WorkspaceViewModel>();
    final sidebarViewModel = context.watch<SidebarViewModel>();

    final activeTab = workspaceVM.activeTab;

    return activeTab != null
        ? ChangeNotifierProvider.value(
            value: activeTab.viewModel,
            child: Scaffold(
              appBar: const WorkflowToolbar(),
              body: Column(
                children: [
                  const WorkflowTabBar(),
                  Expanded(
                    child: _WorkspaceContent(
                      sidebarViewModel: sidebarViewModel,
                    ),
                  ),
                ],
              ),
            ),
          )
        : Scaffold(body: const EmptyWorkspaceView());
  }
}

class _WorkspaceContent extends StatelessWidget {
  final SidebarViewModel sidebarViewModel;

  const _WorkspaceContent({required this.sidebarViewModel});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<WorkflowViewModel>();
    final selectedNode = viewModel.controller.nodes.values
        .where((node) => node.isSelected)
        .firstOrNull;
    final selectedNodeId = selectedNode?.id ?? '';

    return Row(
      children: [
        _Sidebar(viewModel: sidebarViewModel),
        const Expanded(child: WorkflowCanvas()),
        if (selectedNodeId.isNotEmpty)
          NodeParameterPanel(nodeId: selectedNodeId),
      ],
    );
  }
}

class _Sidebar extends StatelessWidget {
  final SidebarViewModel viewModel;

  const _Sidebar({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppConstants.expandedSidebarWidth,
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        border: Border(
          right: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        children: [
          ExpandablePanel(
            header: const Text('Commands Registry'),
            isExpanded: viewModel.isCommandRegistryExpanded,
            onToggle: viewModel.toggleCommandRegistry,
            child: const CommandRegistryPanel(),
          ),
          ExpandablePanel(
            header: const Text('Asset Registry'),
            isExpanded: viewModel.isAssetRegistryExpanded,
            onToggle: viewModel.toggleAssetRegistry,
            child: const AssetRegistryPanel(),
          ),
        ],
      ),
    );
  }
}
