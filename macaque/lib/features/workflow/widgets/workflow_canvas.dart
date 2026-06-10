import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:macaque/features/assets/models/asset.dart';
import 'package:macaque/features/tasks/task_command.dart';
import 'package:uuid/uuid.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart' as vnf;
import 'package:macaque/features/workflow/view_models/workflow_view_model.dart';
import 'package:macaque/features/workflow/models/workflow_models.dart'
    as models;
import 'package:macaque/features/workflow/services/workflow_engine.dart';

import 'package:macaque/features/assets/view_models/asset_view_model.dart';

const _imageSize = 56.0;

class WorkflowCanvas extends StatelessWidget {
  const WorkflowCanvas({super.key});

  @override
  Widget build(BuildContext context) {
    final engine = Provider.of<WorkflowEngine>(context);
    final viewModel = Provider.of<WorkflowViewModel>(context);

    return DragTarget<Object>(
      onWillAcceptWithDetails: (details) {
        final data = details.data;
        return data is Asset || data is TaskCommand || data is String;
      },
      onAcceptWithDetails: (details) {
        final data = details.data;
        final renderBox = context.findRenderObject() as RenderBox;
        final localOffset = renderBox.globalToLocal(details.offset);

        if (data is Asset) {
          final node = models.VdaActionNode(
            id: const Uuid().v4(),
            position: localOffset,
            assetId: data.id,
            command: TaskCommand(
              name: 'Click ${data.filename}',
              referenceImagePath: data.path,
              profile: const TaskProfile(
                mode: TaskMode.standard,
                standardAction: StandardAction.click,
                confidenceThreshold: 0.8,
                timeoutSeconds: 30,
              ),
            ),
          );
          viewModel.addNode(node);
        } else if (data is TaskCommand) {
          final node = models.VdaActionNode(
            id: const Uuid().v4(),
            position: localOffset,
            command: data,
          );
          viewModel.addNode(node);
        } else if (data is String) {
          if (data == 'wait_node') {
            viewModel.addNode(
              models.WaitNode(
                id: const Uuid().v4(),
                position: localOffset,
                durationSeconds: 5,
              ),
            );
          } else if (data == 'exist_node') {
            viewModel.addNode(
              models.ExistNode(
                id: const Uuid().v4(),
                position: localOffset,
                assetId: '',
              ),
            );
          }
        }
      },
      builder: (context, candidateData, rejectedData) {
        // Ensure controller is initialized by waiting for the next frame if needed,
        // or ensure WorkflowViewModel provides a valid controller.
        return vnf.NodeFlowEditor<models.NodeData, dynamic>(
          key: ValueKey('workflow_editor_${viewModel.controller.hashCode}'),
          controller: viewModel.controller,
          theme: vnf.NodeFlowTheme.light,
          connectionStyleBuilder: (connection, sourceNode, targetNode) {
            return vnf.ConnectionStyles.bezier;
          },
          nodeBuilder: (context, node) {
            final isActive = engine.activeNodeId == node.id;
            final isError = engine.status == WorkflowStatus.error &&
                engine.stoppedAtNodeId == node.id;
            final executionCount = engine.nodeExecutionCounts[node.id] ?? 0;
            return _NodeWidget(
              nodeData: node.data,
              isActive: isActive,
              isError: isError,
              executionCount: executionCount,
            );
          },
        );
      },
    );
  }
}

class _NodeWidget extends StatelessWidget {
  final models.NodeData nodeData;
  final bool isActive;
  final bool isError;
  final int executionCount;

  const _NodeWidget({
    required this.nodeData,
    this.isActive = false,
    this.isError = false,
    this.executionCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final assetViewModel = context.watch<AssetViewModel>();

    String? assetId;
    if (nodeData is models.ExistNode) {
      assetId = (nodeData as models.ExistNode).assetId;
    } else if (nodeData is models.VisualCheckNode) {
      assetId = (nodeData as models.VisualCheckNode).assetId;
    } else if (nodeData is models.VdaActionNode) {
      assetId = (nodeData as models.VdaActionNode).assetId;
    }

    final asset = assetId != null
        ? assetViewModel.assets.where((a) => a.id == assetId).firstOrNull
        : null;

    final isActionNode = nodeData is models.VdaActionNode;

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
              color: isError
                  ? Colors.redAccent
                  : isActive
                  ? Colors.yellowAccent
                  : theme.dividerColor,
              width: (isActive || isError) ? 3 : 1,
            ),
            boxShadow: [
              if (isError)
                BoxShadow(
                  color: Colors.redAccent.withValues(alpha: 0.5),
                  blurRadius: 12,
                  spreadRadius: 3,
                ),
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
              if (!isActionNode)
                Text(
                  nodeData.type.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
              if (nodeData is models.VdaActionNode)
                Text(
                  (nodeData as models.VdaActionNode)
                      .command
                      .profile
                      .standardAction
                      .value,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              if (asset != null)
                FutureBuilder<String>(
                  future: assetViewModel.getThumbnailPath(asset),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && File(snapshot.data!).existsSync()) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.file(
                          File(snapshot.data!),
                          width: _imageSize,
                          height: _imageSize,
                          fit: BoxFit.fill,
                        ),
                      );
                    }
                    return const Icon(
                      Icons.image,
                      size: _imageSize,
                      color: Colors.white54,
                    );
                  },
                )
              else
                Text(
                  _getNodeLabel(nodeData, asset?.filename),
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

  String _getNodeLabel(models.NodeData data, String? assetName) {
    return switch (data) {
      models.StartNode() => 'START',
      models.EndNode() => 'END',
      models.VdaActionNode n => assetName ?? n.command.name,
      models.VisualCheckNode _ => 'Check: ${assetName ?? '???'}',
      models.ExistNode _ => 'Exist: ${assetName ?? '???'}',
      models.BranchNode n => 'If ${n.conditionType.name}',
      models.LoopNode n => 'Repeat (${n.loopType.name})',
      models.VariableNode n => '${n.variableName} = ${n.value}',
      models.WaitNode n => 'Wait ${n.durationSeconds}s',
    };
  }
}
