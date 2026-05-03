import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:ui/core/api_client.dart';
import 'package:ui/features/workflow/models/workflow_models.dart';
import 'package:ui/features/workflow/models/execution_result.dart';
import 'package:ui/features/tasks/task_command.dart';

enum WorkflowStatus { idle, running, stopping, completed, error }

class WorkflowEngine extends ChangeNotifier {
  final ApiClient _apiClient;
  
  WorkflowStatus _status = WorkflowStatus.idle;
  WorkflowStatus get status => _status;

  String? _activeNodeId;
  String? get activeNodeId => _activeNodeId;

  final Map<String, dynamic> _variables = {};
  Map<String, dynamic> get variables => Map.unmodifiable(_variables);

  ExecutionResult? _lastResult;
  ExecutionResult? get lastResult => _lastResult;

  final Stopwatch _stopwatch = Stopwatch();
  Duration get elapsedTime => _stopwatch.elapsed;

  final Map<String, int> _nodeExecutionCounts = {};
  Map<String, int> get nodeExecutionCounts => Map.unmodifiable(_nodeExecutionCounts);

  WorkflowEngine({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<void> run(Workflow workflow) async {
    if (_status == WorkflowStatus.running) return;

    _status = WorkflowStatus.running;
    _activeNodeId = null;
    _variables.clear();
    _variables.addAll(workflow.variables);
    _nodeExecutionCounts.clear();
    _lastResult = null;
    _stopwatch.reset();
    _stopwatch.start();
    notifyListeners();

    try {
      final startNode = workflow.nodes.whereType<StartNode>().firstOrNull;
      if (startNode == null) throw Exception('No start node found');

      await _executeNode(startNode, workflow);
      _status = WorkflowStatus.completed;
    } catch (e) {
      debugPrint('Workflow execution error: $e');
      _status = WorkflowStatus.error;
    } finally {
      _stopwatch.stop();
      _activeNodeId = null;
      notifyListeners();
    }
  }

  Future<void> _executeNode(NodeData node, Workflow workflow) async {
    if (_status == WorkflowStatus.stopping) return;

    _activeNodeId = node.id;
    _nodeExecutionCounts[node.id] = (_nodeExecutionCounts[node.id] ?? 0) + 1;
    notifyListeners();

    await _handleNodeLogic(node, workflow);

    if (_status == WorkflowStatus.stopping) return;

    final nextNode = _findNextNode(node, workflow);
    if (nextNode != null) {
      await _executeNode(nextNode, workflow);
    }
  }

  Future<void> _handleNodeLogic(NodeData node, Workflow workflow) async {
    switch (node) {
      case StartNode():
        break;
      case EndNode():
        _status = WorkflowStatus.completed;
        break;
      case VdaActionNode n:
        _lastResult = await _apiClient.executeTask(n.command);
        break;
      case VisualCheckNode n:
        final command = TaskCommand(
          name: 'Visual Check',
          referenceImagePath: n.referenceImagePath,
          profile: const TaskProfile(
            mode: 'STANDARD',
            standardAction: 'HOVER',
            confidenceThreshold: 0.8,
            timeoutSeconds: 30,
          ),
        );
        _lastResult = await _apiClient.checkTask(command);
        break;
      case WaitNode n:
        await Future.delayed(Duration(seconds: n.durationSeconds));
        break;
      case VariableNode n:
        _handleVariableNode(n);
        break;
      case LoopNode():
      case BranchNode():
        break;
    }
  }

  void _handleVariableNode(VariableNode node) {
    final currentValue = _variables[node.variableName] ?? 0;
    switch (node.operation) {
      case VariableOperation.set:
        _variables[node.variableName] = node.value;
        break;
      case VariableOperation.increment:
        if (currentValue is num) {
          _variables[node.variableName] = currentValue + (node.value as num? ?? 1);
        }
        break;
      case VariableOperation.decrement:
        if (currentValue is num) {
          _variables[node.variableName] = currentValue - (node.value as num? ?? 1);
        }
        break;
    }
  }

  NodeData? _findNextNode(NodeData node, Workflow workflow) {
    if (node is EndNode) return null;

    final connections = workflow.connections.where((c) => c.sourceNodeId == node.id).toList();
    if (connections.isEmpty) return null;

    ConnectionData? selectedConnection;
    if (node is BranchNode) {
      final outcome = _evaluateCondition(node);
      selectedConnection = connections.where((c) => c.sourcePortId == outcome).firstOrNull ?? connections.first;
    } else if (node is VisualCheckNode) {
      final outcome = _lastResult?.success == true ? 'Found' : 'Not Found';
      selectedConnection = connections.where((c) => c.sourcePortId == outcome).firstOrNull ?? connections.first;
    } else if (node is LoopNode) {
      final iterations = _nodeExecutionCounts[node.id] ?? 0;
      if (iterations < node.maxIterations) {
        selectedConnection = connections.where((c) => c.sourcePortId == 'body').firstOrNull ?? connections.first;
      } else {
        selectedConnection = connections.where((c) => c.sourcePortId == 'exit').firstOrNull;
      }
    } else {
      selectedConnection = connections.first;
    }

    if (selectedConnection == null) return null;

    return workflow.nodes.where((n) => n.id == selectedConnection!.targetNodeId).firstOrNull;
  }

  String _evaluateCondition(BranchNode node) {
    if (_lastResult == null) return 'Error';

    switch (node.conditionType) {
      case ConditionType.visualSuccess:
        return _lastResult!.success ? 'Success' : 'Failure';
      case ConditionType.scriptExitCode:
        final exitCode = _lastResult!.executionDetails?.exitCode;
        return exitCode == 0 ? 'Success' : 'Failure';
      case ConditionType.variableMatch:
        return 'Success';
      case ConditionType.fileExists:
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
