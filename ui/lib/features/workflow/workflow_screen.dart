import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui/core/api_client.dart';
import 'package:ui/features/workflow/view_models/workflow_view_model.dart';
import 'package:ui/features/workflow/services/workflow_engine.dart';
import 'package:ui/features/workflow/services/workflow_persistence.dart';
import 'package:ui/features/workflow/widgets/workflow_canvas.dart';
import 'package:ui/features/workflow/widgets/workflow_toolbar.dart';
import 'package:ui/features/workflow/widgets/command_registry_panel.dart';
import 'package:ui/features/workflow/widgets/node_parameter_panel.dart';

class WorkflowScreen extends StatelessWidget {
  const WorkflowScreen({super.key});

  static void show(BuildContext context) {
    final apiClient = ApiClient();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) => WorkflowEngine(apiClient: apiClient),
            ),
            Provider(create: (_) => WorkflowPersistence()),
            ChangeNotifierProvider(
              create: (context) => WorkflowViewModel(
                engine: context.read<WorkflowEngine>(),
                persistence: context.read<WorkflowPersistence>(),
              ),
            ),
          ],
          child: const _WorkflowScreenBody(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Use WorkflowScreen.show(context)')),
    );
  }
}

class _WorkflowScreenBody extends StatelessWidget {
  const _WorkflowScreenBody();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<WorkflowViewModel>();
    final selectedNode = viewModel.controller.nodes.values
        .where((node) => node.isSelected)
        .firstOrNull;
    final selectedNodeId = selectedNode?.id ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Visual Workflow Builder')),
      body: Row(
        children: [
          const CommandRegistryPanel(),
          const Expanded(child: WorkflowCanvas()),
          if (selectedNodeId.isNotEmpty)
            NodeParameterPanel(nodeId: selectedNodeId),
        ],
      ),
      bottomNavigationBar: const WorkflowToolbar(),
    );
  }
}
