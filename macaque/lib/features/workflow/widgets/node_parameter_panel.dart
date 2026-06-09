import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:macaque/features/tasks/task_command.dart';
import 'package:macaque/features/workflow/view_models/workflow_view_model.dart';
import 'package:macaque/features/workflow/models/workflow_models.dart'
    as models;
import 'package:vyuh_node_flow/vyuh_node_flow.dart' as vnf;

import 'package:macaque/features/assets/view_models/asset_view_model.dart';

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
      key: ValueKey(nodeId),
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
                _InputPortsSection(
                  nodeId: nodeId,
                  ports: node.ports
                      .where((p) => p.type == vnf.PortType.input)
                      .toList(),
                  onAdd: () => viewModel.addInputPort(nodeId),
                  onRemove: (portId) =>
                      viewModel.removeInputPort(nodeId, portId),
                ),
                const SizedBox(height: 16),
                if (nodeData is models.VdaActionNode) ...[
                  Text(
                    'Command: ${nodeData.command.name}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  _ActionSelector(
                    selectedAction: nodeData.command.profile.standardAction,
                    onSelected: (action) =>
                        viewModel.updateNodeAction(nodeId, action),
                  ),
                  if (nodeData.command.profile.standardAction ==
                      StandardAction.scroll) ...[
                    const SizedBox(height: 16),
                    _ScrollMagnitudeSlider(
                      currentMagnitude:
                          nodeData.command.profile.scrollMagnitude ?? 10,
                      onChanged: (val) =>
                          viewModel.updateNodeScrollMagnitude(nodeId, val),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _InputPortsSection(
                    nodeId: nodeId,
                    ports: node.ports
                        .where((p) => p.type == vnf.PortType.input)
                        .toList(),
                    onAdd: () => viewModel.addInputPort(nodeId),
                    onRemove: (portId) =>
                        viewModel.removeInputPort(nodeId, portId),
                  ),
                  const SizedBox(height: 16),
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

class _ActionSelector extends StatelessWidget {
  final StandardAction selectedAction;
  final ValueChanged<StandardAction> onSelected;

  const _ActionSelector({
    required this.selectedAction,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Action', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<StandardAction>(
          initialValue: selectedAction,
          isExpanded: true,
          decoration: const InputDecoration(
            isDense: true,
            border: OutlineInputBorder(),
          ),
          items: StandardAction.values.map((action) {
            return DropdownMenuItem(value: action, child: Text(action.value));
          }).toList(),
          onChanged: (val) {
            if (val != null) onSelected(val);
          },
        ),
      ],
    );
  }
}

class _ScrollMagnitudeSlider extends StatefulWidget {
  final int currentMagnitude;
  final ValueChanged<int> onChanged;

  const _ScrollMagnitudeSlider({
    required this.currentMagnitude,
    required this.onChanged,
  });

  @override
  State<_ScrollMagnitudeSlider> createState() => _ScrollMagnitudeSliderState();
}

class _ScrollMagnitudeSliderState extends State<_ScrollMagnitudeSlider> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.currentMagnitude.toDouble();
  }

  @override
  void didUpdateWidget(covariant _ScrollMagnitudeSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentMagnitude != oldWidget.currentMagnitude) {
      _value = widget.currentMagnitude.toDouble();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Scroll Magnitude',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            OutlinedButton(
              onPressed: () =>
                  widget.onChanged((_value.round() - 1).clamp(-50, 50)),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(36, 36),
              ),
              child: const Icon(Icons.remove),
            ),
            Expanded(
              child: Slider(
                value: _value.clamp(-50.0, 50.0),
                min: -50,
                max: 50,
                divisions: 100,
                label: _value.round().toString(),
                onChanged: (double value) {
                  setState(() => _value = value);
                },
                onChangeEnd: (double value) => widget.onChanged(value.round()),
              ),
            ),
            OutlinedButton(
              onPressed: () =>
                  widget.onChanged((_value.round() + 1).clamp(-50, 50)),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(36, 36),
              ),
              child: const Icon(Icons.add),
            ),
          ],
        ),
        Center(child: Text(_value.round().toString())),
      ],
    );
  }
}

class _InputPortsSection extends StatelessWidget {
  final String nodeId;
  final List<vnf.Port> ports;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;

  const _InputPortsSection({
    required this.nodeId,
    required this.ports,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Input Ports',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: onAdd,
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...ports.map(
          (port) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Expanded(child: Text(port.id)),
                if (ports.length > 1)
                  IconButton(
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: Colors.red,
                    ),
                    onPressed: () => onRemove(port.id),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
          ),
        ),
      ],
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
    final assetViewModel = context.watch<AssetViewModel>();
    final assets = assetViewModel.assets;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: assets.any((a) => a.id == selectedAssetId)
              ? selectedAssetId
              : null,
          isExpanded: true,
          decoration: const InputDecoration(
            isDense: true,
            border: OutlineInputBorder(),
          ),
          items: assets.map((asset) {
            return DropdownMenuItem(
              value: asset.id,
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: FutureBuilder<String>(
                      future: assetViewModel.getThumbnailPath(asset),
                      builder: (context, snapshot) {
                        if (snapshot.hasData &&
                            File(snapshot.data!).existsSync()) {
                          return Image.file(
                            File(snapshot.data!),
                            fit: BoxFit.cover,
                          );
                        }
                        return const Icon(Icons.image, size: 16);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      asset.filename,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
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
