import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sikulite/core/api_client.dart';
import 'package:sikulite/features/workflow/models/asset_node.dart' as models;
import 'package:sikulite/features/workflow/models/workflow_models.dart'
    as models;
import 'package:sikulite/features/workflow/models/execution_result.dart';
import 'package:sikulite/features/tasks/task_command.dart';

enum WorkflowStatus { idle, running, stopping, completed, error }

class WorkflowEngine extends ChangeNotifier {
  final ApiClient _apiClient;

  WorkflowStatus _status = WorkflowStatus.idle;
  WorkflowStatus get status => _status;

  String? _activeNodeId;
  String? get activeNodeId => _activeNodeId;

  String? _stoppedAtNodeId;
  String? get stoppedAtNodeId => _stoppedAtNodeId;

  final Map<String, dynamic> _variables = {};
  Map<String, dynamic> get variables => Map.unmodifiable(_variables);

  ExecutionResult? _lastResult;
  ExecutionResult? get lastResult => _lastResult;

  final Stopwatch _stopwatch = Stopwatch();
  Duration get elapsedTime => _stopwatch.elapsed;

  final Map<String, int> _nodeExecutionCounts = {};
  Map<String, int> get nodeExecutionCounts =>
      Map.unmodifiable(_nodeExecutionCounts);

  WorkflowEngine({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<bool> executeAssetNode(models.AssetNode node) async {
    final command = TaskCommand(
      name: node.action.value,
      referenceImagePath: _assetMap[node.assetId] ?? node.assetId,
      profile: TaskProfile(
        mode: TaskMode.standard,
        standardAction: node.action,
        confidenceThreshold: 0.8,
        timeoutSeconds: 5,
      ),
    );

    final result = await _apiClient.executeTask(command);

    if (!result.success && !node.ignoreError) {
      stop();
    }

    return result.success;
  }

  final Map<String, String> _assetMap = {};
  final Map<String, String> _assetNameMap = {};

  Future<void> run(
    models.Workflow workflow, {
    Map<String, String> assetMap = const {},
    Map<String, String> assetNameMap = const {},
  }) async {
    if (_status == WorkflowStatus.running) return;

    _status = WorkflowStatus.running;
    _activeNodeId = null;
    _stoppedAtNodeId = null;
    _variables.clear();
    _variables.addAll(workflow.variables);
    _assetMap.clear();
    _assetMap.addAll(assetMap);
    _assetNameMap.clear();
    _assetNameMap.addAll(assetNameMap);
    _nodeExecutionCounts.clear();
    _lastResult = null;
    _stopwatch.reset();
    _stopwatch.start();
    notifyListeners();

    try {
      final startNode = workflow.nodes
          .whereType<models.StartNode>()
          .firstOrNull;
      if (startNode == null) throw Exception('No start node found');

      models.NodeData? currentNode = startNode;
      while (currentNode != null && _status == WorkflowStatus.running) {
        _activeNodeId = currentNode.id;
        _stoppedAtNodeId = currentNode.id;
        _nodeExecutionCounts[currentNode.id] =
            (_nodeExecutionCounts[currentNode.id] ?? 0) + 1;
        notifyListeners();

        await _handleNodeLogic(currentNode, workflow);

        if (_status != WorkflowStatus.running) break;

        currentNode = _findNextNode(currentNode, workflow);

        // Brief delay to prevent tight loops from freezing the UI
        await Future.delayed(Duration.zero);
      }

      if (_status != WorkflowStatus.error) {
        _status = WorkflowStatus.completed;
      }
    } catch (e) {
      debugPrint('Workflow execution error: $e');
      _status = WorkflowStatus.error;
    } finally {
      _stopwatch.stop();
      _activeNodeId = null;
      notifyListeners();
    }
  }

  Future<void> _handleNodeLogic(
    models.NodeData node,
    models.Workflow workflow,
  ) async {
    final assetName = (node is models.ExistNode)
        ? (_assetNameMap[node.assetId] ?? 'Unknown')
        : (node is models.VisualCheckNode)
        ? (_assetNameMap[node.assetId] ?? 'Unknown')
        : (node is models.VdaActionNode && node.assetId != null)
        ? (_assetNameMap[node.assetId!] ?? 'Unknown')
        : 'N/A';

    String details = '';
    if (node is models.VdaActionNode) {
      details =
          'Action: ${node.command.profile.standardAction.value}, Asset: $assetName';
    } else if (node is models.WaitNode) {
      details = 'Duration: ${node.durationSeconds}s';
    } else if (node is models.ExistNode || node is models.VisualCheckNode) {
      details = 'Asset: $assetName';
    }

    debugPrint('Executing node: ${node.type} [$details]');

    switch (node) {
      case models.StartNode():
        break;
      case models.EndNode():
        _status = WorkflowStatus.completed;
        break;
      case models.VdaActionNode n:
        var command = n.command;
        if (n.assetId != null) {
          command = TaskCommand(
            name: command.name,
            referenceImagePath:
                _assetMap[n.assetId!] ?? command.referenceImagePath,
            profile: command.profile,
          );
        }
        _lastResult = await _apiClient.executeTask(command);
        if (!_lastResult!.success) {
          throw Exception(_lastResult!.message);
        }
        break;
      case models.VisualCheckNode n:
        final command = TaskCommand(
          name: 'Visual Check',
          referenceImagePath: _assetMap[n.assetId] ?? '',
          profile: const TaskProfile(
            mode: TaskMode.standard,
            standardAction: StandardAction.hover,
            confidenceThreshold: 0.8,
            timeoutSeconds: 30,
          ),
        );
        _lastResult = await _apiClient.checkTask(command);
        break;
      case models.ExistNode n:
        final command = TaskCommand(
          name: 'Exist Check',
          referenceImagePath: _assetMap[n.assetId] ?? '',
          profile: const TaskProfile(
            mode: TaskMode.exist,
            standardAction: StandardAction.none,
            confidenceThreshold: 0.8,
            timeoutSeconds: 5,
          ),
        );
        _lastResult = await _apiClient.checkTask(command);
        break;
      case models.WaitNode n:
        await Future.delayed(Duration(seconds: n.durationSeconds));
        break;
      case models.AssetNode n:
        await executeAssetNode(n);
        break;
      case models.VariableNode n:
        _handleVariableNode(n);
        break;
      case models.LoopNode():
      case models.BranchNode():
        break;
    }
  }

  void _handleVariableNode(models.VariableNode node) {
    final currentValue = _variables[node.variableName] ?? 0;
    switch (node.operation) {
      case models.VariableOperation.set:
        _variables[node.variableName] = node.value;
        break;
      case models.VariableOperation.increment:
        if (currentValue is num) {
          _variables[node.variableName] =
              currentValue + (node.value as num? ?? 1);
        }
        break;
      case models.VariableOperation.decrement:
        if (currentValue is num) {
          _variables[node.variableName] =
              currentValue - (node.value as num? ?? 1);
        }
        break;
    }
  }

  models.NodeData? _findNextNode(
    models.NodeData node,
    models.Workflow workflow,
  ) {
    if (node is models.EndNode) return null;

    final connections = workflow.connections
        .where((c) => c.sourceNodeId == node.id)
        .toList();
    if (connections.isEmpty) return null;

    models.ConnectionData? selectedConnection;
    if (node is models.BranchNode) {
      final outcome = _evaluateCondition(node);
      selectedConnection =
          connections.where((c) => c.sourcePortId == outcome).firstOrNull ??
          connections.first;
    } else if (node is models.VisualCheckNode || node is models.ExistNode) {
      final outcome = _lastResult?.success == true ? 'Found' : 'Not Found';
      selectedConnection =
          connections.where((c) => c.sourcePortId == outcome).firstOrNull ??
          connections.first;
    } else if (node is models.LoopNode) {
      final iterations = _nodeExecutionCounts[node.id] ?? 0;
      if (iterations < node.maxIterations) {
        selectedConnection =
            connections.where((c) => c.sourcePortId == 'body').firstOrNull ??
            connections.first;
      } else {
        selectedConnection = connections
            .where((c) => c.sourcePortId == 'exit')
            .firstOrNull;
      }
    } else {
      selectedConnection = connections.first;
    }

    if (selectedConnection == null) return null;

    return workflow.nodes
        .where((n) => n.id == selectedConnection!.targetNodeId)
        .firstOrNull;
  }

  String _evaluateCondition(models.BranchNode node) {
    if (_lastResult == null) return 'Error';

    switch (node.conditionType) {
      case models.ConditionType.visualSuccess:
        return _lastResult!.success ? 'Success' : 'Failure';
      case models.ConditionType.scriptExitCode:
        final exitCode = _lastResult!.executionDetails?.exitCode;
        return exitCode == 0 ? 'Success' : 'Failure';
      case models.ConditionType.variableMatch:
        return 'Success';
      case models.ConditionType.fileExists:
        return 'Success';
    }
  }

  void stop() {
    if (_status == WorkflowStatus.running) {
      _status = WorkflowStatus.stopping;
      notifyListeners();
    }
  }
}
