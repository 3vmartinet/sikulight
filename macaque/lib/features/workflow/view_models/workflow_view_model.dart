import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:macaque/core/api_client.dart';
import 'package:macaque/features/tasks/task_command.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart' as vnf;
import 'package:macaque/features/workflow/models/workflow_models.dart'
    as models;
import 'package:macaque/features/workflow/services/workflow_engine.dart';
import 'package:macaque/features/workflow/services/workflow_persistence.dart';
import 'package:macaque/features/workflow/models/isolated_asset_store.dart';
import 'package:uuid/uuid.dart';

import 'package:macaque/features/assets/services/asset_storage_service.dart';
import 'package:macaque/core/constants.dart';

class WorkflowViewModel extends ChangeNotifier {
  final ApiClient _apiClient;
  final WorkflowEngine _engine;
  final WorkflowPersistence _persistence;
  final AssetStorageService _assetStorage;

  late final vnf.NodeFlowController<models.NodeData, dynamic> controller;

  String _workflowId = const Uuid().v4();
  String _workflowName = 'New Workflow';
  String? _filePath;
  String? _resolvedPath;
  bool _isModified = false;
  IsolatedAssetStore? _isolatedStore;

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
    // Set initial name based on file path if available
    if (_filePath != null && !_filePath!.startsWith('new://')) {
      _workflowName = p.basenameWithoutExtension(_filePath!);
    }

    controller = vnf.NodeFlowController<models.NodeData, dynamic>();
    _setupController();

    if (_filePath != null) {
      if (_filePath!.startsWith('new://')) {
        // FR-013: Extract ID from the path to maintain stability across restarts
        final uri = Uri.parse(_filePath!);
        final id = uri.pathSegments.last;
        if (id.isNotEmpty) {
          _workflowId = id;
        }
        loadDraft();
      } else {
        loadFile(File(_filePath!));
      }
    } else {
      loadDraft();
    }
    unawaited(_resolvePath());
  }

  String? get filePath => _filePath;
  String? get resolvedPath => _resolvedPath;
  bool get isModified => _isModified;
  String? get isolatedAssetPath => _isolatedStore?.rootPath;

  Future<void> _resolvePath() async {
    _resolvedPath = await _persistence.getAbsoluteFilePath(
      _workflowId,
      filePath: _filePath,
    );
    notifyListeners();
  }

  String get workflowName => _workflowName;

  /// Returns [name] without the workflow file extension so that the stored
  /// name is always extension-free regardless of how it was persisted.
  String _sanitizedName(String name) {
    if (name.endsWith(AppConstants.workflowExtension)) {
      return name.substring(0, name.length - AppConstants.workflowExtension.length);
    }
    return name;
  }

  void renameWorkflow(String newName) {
    if (newName.trim().isEmpty) return;
    _workflowName = _sanitizedName(newName.trim());
    _saveAutomatically();
    notifyListeners();
  }

  Future<void> _initIsolatedStore() async {
    if (_isolatedStore == null) {
      _isolatedStore = IsolatedAssetStore(workflowId: _workflowId);
      await _isolatedStore!.init();
    }
  }

  Future<void> loadFile(File file) async {
    final extension = p.extension(file.path).toLowerCase();
    models.Workflow? workflow;

    if (extension == AppConstants.workflowExtension) {
      await _initIsolatedStore();
      workflow = await _persistence.loadWorkflow(file, _isolatedStore!.rootPath);
    } else {
      debugPrint('Unsupported file type for loadFile: ${file.path}');
      return;
    }

    if (workflow != null) {
      // Use a new ID for the imported workflow to avoid draft conflicts
      // but keep the name.
      _workflowId = const Uuid().v4();
      _workflowName = _sanitizedName(workflow.name);
      _filePath = file.path;
      unawaited(_resolvePath());

      // Sync the controller with the imported workflow data
      _isUpdating = true;
      controller.clearGraph();

      // Load nodes
      for (final nodeData in workflow.nodes) {
        final ports = _generatePortsForNode(nodeData);
        controller.addNode(
          vnf.Node<models.NodeData>(
            id: nodeData.id,
            type: nodeData.type,
            position: nodeData.position,
            data: nodeData,
            ports: ports,
          ),
        );
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
      _isUpdating = false;
      _isModified = false;
      notifyListeners();
    } else {
      // If load fails, ensure at least a start node exists if graph is empty
      if (controller.nodes.isEmpty) {
        _isUpdating = true;
        addNode(
          models.StartNode(
            id: const Uuid().v4(),
            position: const Offset(100, 100),
          ),
        );
        _isUpdating = false;
        notifyListeners();
      }
    }
  }

  Future<({List<File> assets, List<String> missing})> _collectAssets(
    models.Workflow workflow,
  ) async {
    final assetIds = workflow.referencedAssetIds;
    final assetsToBundle = <File>[];
    final missingAssetIds = <String>[];

    final localAssets = await _assetStorage.loadAssets();
    for (final id in assetIds) {
      bool found = false;

      if (_isolatedStore != null) {
        final isolatedPath = _isolatedStore!.getPathForAsset(id);
        final file = File(isolatedPath);
        if (await file.exists()) {
          assetsToBundle.add(file);
          found = true;
        }
      }

      if (!found) {
        final localAsset = localAssets.where((a) => a.id == id).firstOrNull;
        if (localAsset != null) {
          final file = File(localAsset.path);
          if (await file.exists()) {
            assetsToBundle.add(file);
            found = true;
          }
        }
      }

      if (!found) {
        missingAssetIds.add(id);
      }
    }

    return (assets: assetsToBundle, missing: missingAssetIds);
  }

  Future<List<String>> saveToFile({bool forceSave = false}) async {
    final targetPath = _filePath != null && !_filePath!.startsWith('new://')
        ? _filePath!
        : (await _persistence.getExportFile(fileName: _workflowName)).path;

    final workflow = currentWorkflow;
    final (:assets, :missing) = await _collectAssets(workflow);

    if (missing.isNotEmpty && !forceSave) {
      return missing;
    }

    await _persistence.saveWorkflow(
      workflow: workflow,
      assets: assets,
      targetFile: File(targetPath),
    );

    _filePath = targetPath;
    _isModified = false;
    notifyListeners();

    return [];
  }

  Future<void> loadDraft() async {
    _isUpdating = true;
    controller.clearGraph();

    final draft = await _persistence.loadDraft(_workflowId);

    if (draft != null) {
      _workflowName = _sanitizedName(draft.name);
      _isModified = false;

      // Load nodes
      for (final nodeData in draft.nodes) {
        final ports = _generatePortsForNode(nodeData);
        controller.addNode(
          vnf.Node<models.NodeData>(
            id: nodeData.id,
            type: nodeData.type,
            position: nodeData.position,
            data: nodeData,
            ports: ports,
          ),
        );
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
    } else {
      // Create empty workflow with start node
      addNode(
        models.StartNode(
          id: const Uuid().v4(),
          position: const Offset(100, 100),
        ),
      );
    }
    _isUpdating = false;
    notifyListeners();
  }

  List<vnf.Port> _generatePortsForNode(models.NodeData data) {
    final List<vnf.Port> ports = [];

    // 1. Input Ports
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
          offset: Offset(
            0,
            30.0 +
                (ports.where((p) => p.type == vnf.PortType.input).length *
                    20.0),
          ),
          maxConnections: 10,
        ),
      );
    }

    // 2. Output Ports
    if (data is models.BranchNode) {
      for (int i = 0; i < data.outcomes.length; i++) {
        ports.add(
          vnf.Port(
            id: data.outcomes[i],
            name: data.outcomes[i],
            type: vnf.PortType.output,
            position: vnf.PortPosition.right,
            offset: Offset(0, 25.0 + (i * 20.0)),
            maxConnections: 10,
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
          maxConnections: 10,
        ),
      );
      ports.add(
        vnf.Port(
          id: 'Not Found',
          name: 'Not Found',
          type: vnf.PortType.output,
          position: vnf.PortPosition.right,
          offset: const Offset(0, 45),
          maxConnections: 10,
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
          maxConnections: 10,
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
          maxConnections: 10,
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
          maxConnections: 10,
        ),
      );
    }

    return ports;
  }

  void _setupController() {
    controller.updateEvents(
      vnf.NodeFlowEvents(
        node: vnf.NodeEvents(
          onCreated: (_) => _onGraphChanged(),
          onBeforeDelete: (node) async {
            return node.data is! models.StartNode;
          },
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

    // Continuous auto-save
    _saveAutomatically();

    _isUpdating = false;
  }

  Future<void> _saveAutomatically() async {
    _isModified = true;
    notifyListeners();

    // Spec FR-001: Every save operation results in a .macaque file
    await saveToFile(forceSave: true);

    _isModified = false;
    notifyListeners();
  }

  models.Workflow get currentWorkflow {
    // Sync node positions from controller back to NodeData before saving
    final nodes = controller.nodes.values.map((n) {
      return n.data.copyWith(position: n.position.value);
    }).toList();

    debugPrint('Saving workflow $_workflowId with ${nodes.length} nodes');
    return models.Workflow(
      id: _workflowId,
      name: _workflowName,
      nodes: nodes,
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
  }

  void addNode(models.NodeData data) {
    // Prevent multiple start nodes
    if (data is models.StartNode &&
        controller.nodes.values.any((n) => n.data is models.StartNode)) {
      return;
    }

    final ports = _generatePortsForNode(data);

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
    unawaited(_resolvePath());
    controller.clearGraph();
    addNode(
      models.StartNode(id: const Uuid().v4(), position: const Offset(100, 100)),
    );
    notifyListeners();
  }

  Future<void> runWorkflow() async {
    final localAssets = await _assetStorage.loadAssets();
    final assetMap = {for (var a in localAssets) a.id: a.path};
    final assetNameMap = {for (var a in localAssets) a.id: a.filename};

    // Merge with isolated assets
    if (_isolatedStore != null && await _isolatedStore!.exists()) {
      final dir = Directory(_isolatedStore!.rootPath);
      final files = dir.listSync().whereType<File>();
      for (final file in files) {
        final filename = p.basename(file.path);
        // Using filename as ID for isolated assets
        assetMap[filename] = file.path;
        assetNameMap[filename] = filename;
      }
    }

    await _persistence.saveDraft(currentWorkflow);
    await _apiClient.hideApp();
    try {
      await _engine.run(
        currentWorkflow,
        assetMap: assetMap,
        assetNameMap: assetNameMap,
      );
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
      offset: Offset(
        0,
        30.0 +
            (node.ports.where((p) => p.type == vnf.PortType.input).length *
                20.0),
      ),
      maxConnections: 10,
    );

    // Update node's persisted input ports
    final newPortData = models.PortData(id: newPort.id, name: newPort.name);
    final newData = node.data.copyWith(
      inputs: [...node.data.inputs, newPortData],
    );

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

    final inputPorts = node.ports
        .where((p) => p.type == vnf.PortType.input)
        .toList();
    if (inputPorts.length <= 1) return;

    // Remove connections attached to this port
    final connectionsToRemove = controller.connections
        .where((c) => c.targetNodeId == nodeId && c.targetPortId == portId)
        .toList();
    for (final conn in connectionsToRemove) {
      controller.removeConnection(conn.id);
    }

    // Update node's persisted input ports
    final newData = node.data.copyWith(
      inputs: node.data.inputs.where((p) => p.id != portId).toList(),
    );

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

  void updateExistNodeConfidenceThreshold(
    String nodeId,
    double confidenceThreshold,
  ) {
    final node = controller.getNode(nodeId);
    if (node == null || node.data is! models.ExistNode) return;

    final newData = (node.data as models.ExistNode).copyWith(
      confidenceThreshold: confidenceThreshold,
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

  Future<void> exportWorkflow([File? target]) async {
    final targetFile = target ??
        await _persistence.getExportFile(
          fileName: '$_workflowName${AppConstants.workflowExtension}',
        );
    final workflow = currentWorkflow;
    final (:assets, missing: _) = await _collectAssets(workflow);

    await _persistence.saveWorkflow(
      workflow: workflow,
      assets: assets,
      targetFile: targetFile,
    );
  }
}
