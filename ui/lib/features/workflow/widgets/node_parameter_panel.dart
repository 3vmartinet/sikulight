import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui/features/workflow/view_models/workflow_view_model.dart';
import 'package:ui/features/workflow/models/workflow_models.dart' as models;
import 'package:vyuh_node_flow/vyuh_node_flow.dart' as vnf;

class NodeParameterPanel extends StatelessWidget {
  final String nodeId;

  const NodeParameterPanel({super.key, required this.nodeId});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<WorkflowViewModel>();
    final node = viewModel.controller.getNode(nodeId);
    
    if (node == null) {
      return const Center(child: Text('Node not found'));
    }
    
    final nodeData = node.data;

    return Container(
      width: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(left: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Node: ${nodeData.type}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                if (nodeData is models.VdaActionNode) ...[
                  Text('Action: ${nodeData.command.name}'),
                  const SizedBox(height: 8),
                  _TimeoutOverrideField(
                    nodeId: nodeId,
                    currentTimeout: nodeData.timeoutOverride,
                    onChanged: (val) => viewModel.updateTimeoutOverride(nodeId, val),
                  ),
                ],
                if (nodeData is models.WaitNode) ...[
                  _DurationField(
                    nodeId: nodeId,
                    currentDuration: nodeData.durationSeconds,
                    onChanged: (val) => viewModel.updateWaitDuration(nodeId, val),
                  ),
                ],
                // Add more node-specific fields here
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeoutOverrideField extends StatelessWidget {
  final String nodeId;
  final int? currentTimeout;
  final ValueChanged<int?> onChanged;

  const _TimeoutOverrideField({
    required this.nodeId,
    required this.currentTimeout,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: currentTimeout?.toString() ?? '',
      decoration: const InputDecoration(labelText: 'Timeout Override (s)'),
      keyboardType: TextInputType.number,
      onChanged: (value) {
        final timeout = int.tryParse(value);
        onChanged(timeout);
      },
    );
  }
}

class _DurationField extends StatelessWidget {
  final String nodeId;
  final int currentDuration;
  final ValueChanged<int> onChanged;

  const _DurationField({
    required this.nodeId, 
    required this.currentDuration,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: currentDuration.toString(),
      decoration: const InputDecoration(labelText: 'Duration (s)'),
      keyboardType: TextInputType.number,
      onChanged: (value) {
        final duration = int.tryParse(value) ?? currentDuration;
        onChanged(duration);
      },
    );
  }
}
