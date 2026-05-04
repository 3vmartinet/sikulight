import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui/core/api_client.dart';
import 'package:ui/features/tasks/task_provider.dart';
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
    final taskProvider = context.read<TaskProvider>();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: taskProvider),
            ChangeNotifierProvider(
              create: (_) => WorkflowEngine(apiClient: apiClient),
            ),
            Provider(create: (_) => WorkflowPersistence()),
            ChangeNotifierProvider(
              create: (context) => WorkflowViewModel(
                apiClient: apiClient,
                engine: context.read<WorkflowEngine>(),
                persistence: context.read<WorkflowPersistence>(),
              ),
            ),
          ],
          child: const WorkflowScreen(),
        ),
      ),
    );
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
    final viewModel = context.watch<WorkflowViewModel>();
    final selectedNode = viewModel.controller.nodes.values
        .where((node) => node.isSelected)
        .firstOrNull;
    final selectedNodeId = selectedNode?.id ?? '';

    return Scaffold(
      appBar: const WorkflowToolbar(),
      body: SizedBox.expand(
        child: Row(
          children: [
            const CommandRegistryPanel(),
            const Expanded(child: WorkflowCanvas()),
            if (selectedNodeId.isNotEmpty)
              NodeParameterPanel(nodeId: selectedNodeId),
          ],
        ),
      ),
    );
  }
}
