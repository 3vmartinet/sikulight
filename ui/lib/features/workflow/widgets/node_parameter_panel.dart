import 'dart:io';
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
                if (nodeData is models.ExistNode) ...[
                  _ExistReferenceField(
                    nodeId: nodeId,
                    initialPath: nodeData.referenceImagePath,
                    onConfirmed: (val) => viewModel.updateExistReferencePath(nodeId, val),
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

class _ExistReferenceField extends StatefulWidget {
  final String nodeId;
  final String initialPath;
  final ValueChanged<String> onConfirmed;

  const _ExistReferenceField({
    required this.nodeId,
    required this.initialPath,
    required this.onConfirmed,
  });

  @override
  State<_ExistReferenceField> createState() => _ExistReferenceFieldState();
}

class _ExistReferenceFieldState extends State<_ExistReferenceField> {
  late TextEditingController _controller;
  bool _isValid = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialPath);
    _validatePath(widget.initialPath);
  }

  @override
  void didUpdateWidget(covariant _ExistReferenceField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialPath != _controller.text) {
      _controller.text = widget.initialPath;
      _validatePath(widget.initialPath);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _validatePath(String path) async {
    if (path.isEmpty) {
      if (mounted) {
        setState(() {
          _isValid = false;
          _error = 'Path is empty';
        });
      }
      return;
    }
    
    final file = File(path);
    final exists = await file.exists();
    
    if (mounted) {
      setState(() {
        _isValid = exists;
        _error = exists ? null : 'File does not exist';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _controller,
          decoration: const InputDecoration(labelText: 'Reference Image Path'),
          onChanged: _validatePath,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            ElevatedButton(
              onPressed: _isValid ? () => widget.onConfirmed(_controller.text) : null,
              child: const Text('Confirm'),
            ),
            if (_error != null) ...[
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
