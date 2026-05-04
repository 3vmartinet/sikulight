import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ui/core/api_client.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart' as vnf;
import 'package:ui/features/workflow/models/workflow_models.dart' as models;
import 'package:ui/features/workflow/services/workflow_engine.dart';
import 'package:ui/features/workflow/services/workflow_persistence.dart';
import 'package:uuid/uuid.dart';

class WorkflowViewModel extends ChangeNotifier {
  final ApiClient _apiClient;
  final WorkflowEngine _engine;
  final WorkflowPersistence _persistence;

  late final vnf.NodeFlowController<models.NodeData, dynamic> controller;

  String _workflowId = const Uuid().v4();
  String _workflowName = 'New Workflow';

  WorkflowViewModel({
    required WorkflowEngine engine,
    required WorkflowPersistence persistence,
    required ApiClient apiClient,
  }) : _engine = engine,
       _persistence = persistence,
       _apiClient = apiClient {
    controller = vnf.NodeFlowController<models.NodeData, dynamic>();
    _setupController();
    _loadInitialWorkflow();
  }

  Future<void> _loadInitialWorkflow() async {
    final draft = await _persistence.loadDraft();
    if (draft != null) {
      _workflowId = draft.id;
      _workflowName = draft.name;
      
      // Load nodes
      for (final node in draft.nodes) {
        addNode(node);
      }
      
      // Recreate connections
      for (final conn in draft.connections) {
        controller.addConnection(
          vnf.Connection(
            id: const Uuid().v4(),
            sourceNodeId: conn.sourceNodeId,
            sourcePortId: conn.sourcePortId,
            targetNodeId: conn.targetNodeId,
            targetPortId: conn.targetPortId,
          ),
        );
      }
      notifyListeners();
    } else {
      addNode(
        models.StartNode(
          id: const Uuid().v4(),
          position: const Offset(100, 100),
        ),
      );
    }
  }

  void _setupController() {
    controller.updateEvents(
      vnf.NodeFlowEvents(
        node: vnf.NodeEvents(
          onCreated: (_) => _onGraphChanged(),
          onDeleted: (node) {
            if (node.data is models.StartNode) {
              // Re-add if it was deleted
              addNode(node.data);
            } else {
              _onGraphChanged();
            }
          },
          onDragStop: (_) => _onGraphChanged(),
        ),
        connection: vnf.ConnectionEvents(
          onCreated: (_) => _onGraphChanged(),
          onDeleted: (_) => _onGraphChanged(),
        ),
        onSelectionChange: (_) => notifyListeners(),
      ),
    );
  }

  bool _isUpdating = false;

  void _onGraphChanged() {
    if (_isUpdating) return;
    _isUpdating = true;

    // Update node positions before saving
    for (final node in controller.nodes.values) {
      final updatedData = node.data.copyWith(position: node.position.value);
      controller.addNode(
        vnf.Node<models.NodeData>(
          id: node.id,
          type: node.type,
          position: node.position.value,
          data: updatedData,
          ports: node.ports.toList(),
        ),
      );
    }
    _persistence.saveDraft(currentWorkflow);
    notifyListeners();

    _isUpdating = false;
  }


  models.Workflow get currentWorkflow => models.Workflow(
    id: _workflowId,
    name: _workflowName,
    nodes: controller.nodes.values.map((n) => n.data).toList(),
    connections: controller.connections
        .map(
          (c) => models.ConnectionData(
            sourceNodeId: c.sourceNodeId,
            sourcePortId: c.sourcePortId,
            targetNodeId: c.targetNodeId,
            targetPortId: c.targetPortId,
          ),
        )
        .toList(),
    variables: _engine.variables,
  );

  void addNode(models.NodeData data) {
    final List<vnf.Port> ports = [];

    // Inputs
    if (data is! models.StartNode) {
      ports.add(
        vnf.Port(
          id: 'in',
          name: 'In',
          type: vnf.PortType.input,
          position: vnf.PortPosition.left,
        ),
      );
    }

    // Outputs
    if (data is models.BranchNode) {
      for (final outcome in data.outcomes) {
        ports.add(
          vnf.Port(
            id: outcome,
            name: outcome,
            type: vnf.PortType.output,
            position: vnf.PortPosition.right,
          ),
        );
      }
    } else if (data is models.VisualCheckNode) {
      ports.add(
        vnf.Port(
          id: 'Found',
          name: 'Found',
          type: vnf.PortType.output,
          position: vnf.PortPosition.right,
        ),
      );
      ports.add(
        vnf.Port(
          id: 'Not Found',
          name: 'Not Found',
          type: vnf.PortType.output,
          position: vnf.PortPosition.right,
        ),
      );
    } else if (data is! models.EndNode) {
      ports.add(
        vnf.Port(
          id: 'out',
          name: 'Out',
          type: vnf.PortType.output,
          position: vnf.PortPosition.right,
        ),
      );
    }

    controller.addNode(
      vnf.Node<models.NodeData>(
        id: data.id,
        type: data.type,
        position: data.position,
        data: data,
        ports: ports,
      ),
    );
  }

  void resetWorkflow() {
    _workflowId = const Uuid().v4();
    _workflowName = 'New Workflow';
    controller.clearGraph();
    notifyListeners();
  }

  Future<void> runWorkflow() async {
    await _persistence.saveDraft(currentWorkflow);
    await _apiClient.hideApp();
    try {
      await _engine.run(currentWorkflow);
    } finally {
      await _apiClient.showApp();
    }
  }

  void stopWorkflow() {
    _engine.stop();
  }

  void undo() {
    debugPrint('Undo called');
  }

  void redo() {
    debugPrint('Redo called');
  }

  void updateWaitDuration(String nodeId, int duration) {
    final node = controller.getNode(nodeId);
    if (node != null && node.data is models.WaitNode) {
      final oldData = node.data as models.WaitNode;
      final newData = models.WaitNode(
        id: oldData.id,
        position: oldData.position,
        durationSeconds: duration,
      );

      // Replace node with updated data
      controller.addNode(
        vnf.Node<models.NodeData>(
          id: node.id,
          type: node.type,
          position: node.position.value,
          data: newData,
          ports: node.ports.toList(),
        ),
      );

      notifyListeners();
    }
  }

  void updateTimeoutOverride(String nodeId, int? timeout) {
    final node = controller.getNode(nodeId);
    if (node != null && node.data is models.VdaActionNode) {
      final oldData = node.data as models.VdaActionNode;
      final newData = models.VdaActionNode(
        id: oldData.id,
        position: oldData.position,
        command: oldData.command,
        timeoutOverride: timeout,
      );

      // Replace node with updated data
      controller.addNode(
        vnf.Node<models.NodeData>(
          id: node.id,
          type: node.type,
          position: node.position.value,
          data: newData,
          ports: node.ports.toList(),
        ),
      );

      notifyListeners();
    }
  }

  Future<void> exportWorkflow() async {
    final targetFile = await _persistence.getExportFile();
    await _persistence.exportWorkflow(currentWorkflow, targetFile);
  }

  Future<void> importWorkflow(File file) async {
    final workflow = await _persistence.importWorkflow(file);
    if (workflow != null) {
      _workflowId = workflow.id;
      _workflowName = workflow.name;
      controller.clearGraph();
      for (final node in workflow.nodes) {
        addNode(node);
      }
      notifyListeners();
    }
  }
}
