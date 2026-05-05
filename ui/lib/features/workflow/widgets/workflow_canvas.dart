import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart' as vnf;
import 'package:ui/features/workflow/view_models/workflow_view_model.dart';
import 'package:ui/features/workflow/models/workflow_models.dart' as models;
import 'package:ui/features/workflow/services/workflow_engine.dart';

const _imageSize = 56.0;

class WorkflowCanvas extends StatelessWidget {
  const WorkflowCanvas({super.key});

  @override
  Widget build(BuildContext context) {
    final engine = Provider.of<WorkflowEngine>(context);
    final viewModel = Provider.of<WorkflowViewModel>(context);

    return vnf.NodeFlowEditor<models.NodeData, dynamic>(
      controller: viewModel.controller,
      theme: vnf.NodeFlowTheme.light,
      connectionStyleBuilder: (connection, sourceNode, targetNode) {
        return vnf.ConnectionStyles.bezier;
      },
      nodeBuilder: (context, node) {
        final isActive = engine.activeNodeId == node.id;
        final executionCount = engine.nodeExecutionCounts[node.id] ?? 0;
        return _NodeWidget(
          nodeData: node.data,
          isActive: isActive,
          executionCount: executionCount,
        );
      },
    );
  }
}

class _NodeWidget extends StatelessWidget {
  final models.NodeData nodeData;
  final bool isActive;
  final int executionCount;

  const _NodeWidget({
    required this.nodeData,
    this.isActive = false,
    this.executionCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: _getNodeColor(theme, nodeData),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? Colors.yellowAccent : theme.dividerColor,
              width: isActive ? 3 : 1,
            ),
            boxShadow: [
              if (isActive)
                BoxShadow(
                  color: Colors.yellowAccent.withValues(alpha: 0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              Text(
                nodeData.type.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
              if (nodeData is models.ExistNode &&
                  (nodeData as models.ExistNode).referenceImagePath.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.file(
                    File((nodeData as models.ExistNode).referenceImagePath),
                    width: _imageSize,
                    height: _imageSize,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.broken_image,
                      color: Colors.white,
                      size: _imageSize,
                    ),
                  ),
                )
              else
                Text(
                  _getNodeLabel(nodeData),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
        if (executionCount > 0)
          Positioned(
            top: -10,
            right: -10,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  executionCount.toString(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Color _getNodeColor(ThemeData theme, models.NodeData data) {
    return switch (data) {
      models.StartNode() => Colors.green.shade700,
      models.EndNode() => Colors.red.shade700,
      models.VdaActionNode() => Colors.blue.shade700,
      models.VisualCheckNode() => Colors.teal.shade700,
      models.ExistNode() => Colors.amber.shade800,
      models.BranchNode() => Colors.orange.shade800,
      models.LoopNode() => Colors.purple.shade700,
      models.VariableNode() => Colors.indigo.shade700,
      models.WaitNode() => Colors.grey.shade700,
    };
  }

  String _getNodeLabel(models.NodeData data) {
    return switch (data) {
      models.StartNode() => 'START',
      models.EndNode() => 'END',
      models.VdaActionNode n => n.command.name,
      models.VisualCheckNode n =>
        'Check: ${n.referenceImagePath.split('/').last}',
      models.ExistNode n => 'Exist: ${n.referenceImagePath.split('/').last}',
      models.BranchNode n => 'If ${n.conditionType.name}',
      models.LoopNode n => 'Repeat (${n.loopType.name})',
      models.VariableNode n => '${n.variableName} = ${n.value}',
      models.WaitNode n => 'Wait ${n.durationSeconds}s',
    };
  }
}
