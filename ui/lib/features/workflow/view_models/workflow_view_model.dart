import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ui/core/api_client.dart';
import 'package:ui/features/tasks/task_command.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart' as vnf;
import 'package:ui/features/workflow/models/workflow_models.dart' as models;
import 'package:ui/features/workflow/services/workflow_engine.dart';
import 'package:ui/features/workflow/services/workflow_persistence.dart';
import 'package:uuid/uuid.dart';

import 'package:ui/features/assets/services/asset_storage_service.dart';

class WorkflowViewModel extends ChangeNotifier {
  final ApiClient _apiClient;
  final WorkflowEngine _engine;
  final WorkflowPersistence _persistence;
  final AssetStorageService _assetStorage;

  late final vnf.NodeFlowController<models.NodeData, dynamic> controller;

  String _workflowId = const Uuid().v4();
  String _workflowName = 'New Workflow';
  String? _filePath;
  bool _isModified = false;

  WorkflowViewModel({
    required WorkflowEngine engine,
    required WorkflowPersistence persistence,
    required ApiClient apiClient,
    required AssetStorageService assetStorage,
    String? initialFilePath,
  }) : _engine = engine,
       _persistence = persistence,
       _apiClient = apiClient,
       _assetStorage = assetStorage,
       _filePath = initialFilePath {
    controller = vnf.NodeFlowController<models.NodeData, dynamic>();
    _setupController();
    if (_filePath != null) {
      loadFile(File(_filePath!));
    }
  }

  String? get filePath => _filePath;
  bool get isModified => _isModified;

  Future<void> loadFile(File file) async {
    final workflow = await _persistence.importWorkflow(file);
    if (workflow != null) {
      _workflowId = workflow.id;
      _workflowName = workflow.name;
      _filePath = file.path;
      controller.clearGraph();
      
      // Load nodes
      for (final node in workflow.nodes) {
        addNode(node);
      }

      // Recreate connections
      for (final conn in workflow.connections) {
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
      _isModified = false;
      notifyListeners();
    }
  }

  Future<void> saveToFile() async {
    if (_filePath == null) return;
    await _persistence.exportWorkflow(currentWorkflow, File(_filePath!));
    _isModified = false;
    notifyListeners();
  }

  Future<void> loadDraft() async {
    controller.clearGraph();
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

    // IV. Observability: Logging
    debugPrint('Workflow $_workflowId graph changed');

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
    _isModified = true;
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
    // Prevent multiple start nodes
    if (data is models.StartNode &&
        controller.nodes.values.any((n) => n.data is models.StartNode)) {
      return;
    }

    final List<vnf.Port> ports = [];

    // Persisted inputs or default one
    final inputPorts = data.inputs.isEmpty 
      ? [const models.PortData(id: 'in', name: 'In')] 
      : data.inputs;
      
    for (final port in inputPorts) {
      ports.add(
        vnf.Port(
          id: port.id,
          name: port.name,
          type: vnf.PortType.input,
          position: vnf.PortPosition.left,
          offset: Offset(0, 30.0 + (ports.where((p) => p.type == vnf.PortType.input).length * 20.0)),
          maxConnections: 10,
        ),
      );
    }

    // Outputs
    if (data is models.BranchNode) {
      for (int i = 0; i < data.outcomes.length; i++) {
        ports.add(
          vnf.Port(
            id: data.outcomes[i],
            name: data.outcomes[i],
            type: vnf.PortType.output,
            position: vnf.PortPosition.right,
            offset: Offset(0, 25.0 + (i * 20.0)),
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
          offset: const Offset(0, 25),
        ),
      );
      ports.add(
        vnf.Port(
          id: 'Not Found',
          name: 'Not Found',
          type: vnf.PortType.output,
          position: vnf.PortPosition.right,
          offset: const Offset(0, 45),
        ),
      );
    } else if (data is models.ExistNode) {
      ports.add(
        vnf.Port(
          id: 'Found',
          name: 'Yes',
          type: vnf.PortType.output,
          position: vnf.PortPosition.right,
          offset: const Offset(0, 25),
          showLabel: true,
        ),
      );
      ports.add(
        vnf.Port(
          id: 'Not Found',
          name: 'No',
          type: vnf.PortType.output,
          position: vnf.PortPosition.right,
          offset: const Offset(0, 45),
          showLabel: true,
        ),
      );
    } else if (data is! models.EndNode) {
      ports.add(
        vnf.Port(
          id: 'out',
          name: 'Out',
          type: vnf.PortType.output,
          position: vnf.PortPosition.right,
          offset: const Offset(0, 30),
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
    addNode(
      models.StartNode(
        id: const Uuid().v4(),
        position: const Offset(100, 100),
      ),
    );
    notifyListeners();
  }

  Future<void> runWorkflow() async {
    final assets = await _assetStorage.loadAssets();
    final assetMap = {for (var a in assets) a.id: a.path};
    final assetNameMap = {for (var a in assets) a.id: a.filename};

    await _persistence.saveDraft(currentWorkflow);
    await _apiClient.hideApp();
    try {
      await _engine.run(currentWorkflow, assetMap: assetMap, assetNameMap: assetNameMap);
    } catch (e) {
      debugPrint('Workflow execution failed: $e');
      _engine.stop();
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

  void updateNodeAction(String nodeId, StandardAction action) {
    final node = controller.getNode(nodeId);
    if (node != null && node.data is models.VdaActionNode) {
      final oldData = node.data as models.VdaActionNode;
      final newData = oldData.copyWith(
        command: TaskCommand(
          name: oldData.command.name,
          referenceImagePath: oldData.command.referenceImagePath,
          profile: TaskProfile(
            mode: oldData.command.profile.mode,
            standardAction: action,
            confidenceThreshold: oldData.command.profile.confidenceThreshold,
            timeoutSeconds: oldData.command.profile.timeoutSeconds,
            scrollMagnitude: oldData.command.profile.scrollMagnitude,
            x: oldData.command.profile.x,
            y: oldData.command.profile.y,
          ),
        ),
      );

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

  void addInputPort(String nodeId) {
    final node = controller.getNode(nodeId);
    if (node == null) return;

    final newPort = vnf.Port(
      id: const Uuid().v4(),
      name: 'In',
      type: vnf.PortType.input,
      position: vnf.PortPosition.left,
      offset: Offset(0, 30.0 + (node.ports.where((p) => p.type == vnf.PortType.input).length * 20.0)),
      maxConnections: 10,
    );

    // Update node's persisted input ports
    final newPortData = models.PortData(id: newPort.id, name: newPort.name);
    final newData = node.data.copyWith(inputs: [...node.data.inputs, newPortData]);

    controller.addNode(
      vnf.Node<models.NodeData>(
        id: node.id,
        type: node.type,
        position: node.position.value,
        data: newData,
        ports: [...node.ports, newPort],
      ),
    );
    notifyListeners();
  }

  void removeInputPort(String nodeId, String portId) {
    final node = controller.getNode(nodeId);
    if (node == null) return;

    final inputPorts = node.ports.where((p) => p.type == vnf.PortType.input).toList();
    if (inputPorts.length <= 1) return;

    // Remove connections attached to this port
    final connectionsToRemove = controller.connections.where((c) => c.targetNodeId == nodeId && c.targetPortId == portId).toList();
    for (final conn in connectionsToRemove) {
      controller.removeConnection(conn.id);
    }

    // Update node's persisted input ports
    final newData = node.data.copyWith(inputs: node.data.inputs.where((p) => p.id != portId).toList());

    controller.addNode(
      vnf.Node<models.NodeData>(
        id: node.id,
        type: node.type,
        position: node.position.value,
        data: newData,
        ports: node.ports.where((p) => p.id != portId).toList(),
      ),
    );
    controller.selectNode(nodeId);
    notifyListeners();
  }

  void updateNodeScrollMagnitude(String nodeId, int magnitude) {
    final node = controller.getNode(nodeId);
    if (node != null && node.data is models.VdaActionNode) {
      final oldData = node.data as models.VdaActionNode;
      final newData = oldData.copyWith(
        command: TaskCommand(
          name: oldData.command.name,
          referenceImagePath: oldData.command.referenceImagePath,
          profile: TaskProfile(
            mode: oldData.command.profile.mode,
            standardAction: oldData.command.profile.standardAction,
            confidenceThreshold: oldData.command.profile.confidenceThreshold,
            timeoutSeconds: oldData.command.profile.timeoutSeconds,
            scrollMagnitude: magnitude,
            x: oldData.command.profile.x,
            y: oldData.command.profile.y,
          ),
        ),
      );

      // Re-add node with updated data
      controller.addNode(
        vnf.Node<models.NodeData>(
          id: node.id,
          type: node.type,
          position: node.position.value,
          data: newData,
          ports: node.ports.toList(),
        ),
      );
      
      // Explicitly restore selection
      controller.selectNode(nodeId);
      notifyListeners();
    }
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

  void updateNodeAssetId(String nodeId, String assetId) {
    final node = controller.getNode(nodeId);
    if (node == null) return;

    models.NodeData? newData;
    if (node.data is models.ExistNode) {
      newData = (node.data as models.ExistNode).copyWith(assetId: assetId);
    } else if (node.data is models.VisualCheckNode) {
      newData = (node.data as models.VisualCheckNode).copyWith(
        assetId: assetId,
      );
    } else if (node.data is models.VdaActionNode) {
      newData = (node.data as models.VdaActionNode).copyWith(assetId: assetId);
    }

    if (newData != null) {
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
    await loadFile(file);
  }
}
