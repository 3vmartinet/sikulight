import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui/features/workflow/view_models/workflow_view_model.dart';
import 'package:ui/features/workflow/models/workflow_models.dart' as models;
import 'package:vyuh_node_flow/vyuh_node_flow.dart' as vnf;

import 'package:ui/features/assets/view_models/asset_view_model.dart';

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
                    onChanged: (val) =>
                        viewModel.updateTimeoutOverride(nodeId, val),
                  ),
                  const SizedBox(height: 16),
                  _AssetSelector(
                    label: 'Override Asset',
                    selectedAssetId: nodeData.assetId,
                    onSelected: (assetId) =>
                        viewModel.updateNodeAssetId(nodeId, assetId),
                  ),
                ],
                if (nodeData is models.WaitNode) ...[
                  _DurationField(
                    nodeId: nodeId,
                    currentDuration: nodeData.durationSeconds,
                    onChanged: (val) =>
                        viewModel.updateWaitDuration(nodeId, val),
                  ),
                ],
                if (nodeData is models.ExistNode) ...[
                  _AssetSelector(
                    label: 'Reference Asset',
                    selectedAssetId: nodeData.assetId,
                    onSelected: (assetId) =>
                        viewModel.updateNodeAssetId(nodeId, assetId),
                  ),
                ],
                if (nodeData is models.VisualCheckNode) ...[
                  _AssetSelector(
                    label: 'Check Asset',
                    selectedAssetId: nodeData.assetId,
                    onSelected: (assetId) =>
                        viewModel.updateNodeAssetId(nodeId, assetId),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AssetSelector extends StatelessWidget {
  final String label;
  final String? selectedAssetId;
  final ValueChanged<String> onSelected;

  const _AssetSelector({
    required this.label,
    required this.selectedAssetId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final assets = context.watch<AssetViewModel>().assets;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: assets.any((a) => a.id == selectedAssetId)
              ? selectedAssetId
              : null,
          decoration: const InputDecoration(
            isDense: true,
            border: OutlineInputBorder(),
          ),
          items: assets.map((asset) {
            return DropdownMenuItem(
              value: asset.id,
              child: Text(asset.filename),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) onSelected(val);
          },
        ),
      ],
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
