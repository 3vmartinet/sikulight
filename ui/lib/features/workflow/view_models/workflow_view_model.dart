import 'dart:io';
import 'package:flutter/material.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart' as vnf;
import 'package:ui/features/workflow/models/workflow_models.dart' as models;
import 'package:ui/features/workflow/services/workflow_engine.dart';
import 'package:ui/features/workflow/services/workflow_persistence.dart';
import 'package:uuid/uuid.dart';

class WorkflowViewModel extends ChangeNotifier {
  final WorkflowEngine _engine;
  final WorkflowPersistence _persistence;

  late final vnf.NodeFlowController<models.NodeData, dynamic> controller;
  
  String _workflowId = const Uuid().v4();
  String _workflowName = 'New Workflow';

  WorkflowViewModel({
    required WorkflowEngine engine,
    required WorkflowPersistence persistence,
  }) : _engine = engine,
       _persistence = persistence {
         controller = vnf.NodeFlowController<models.NodeData, dynamic>();
         _setupController();
       }

  void _setupController() {
    controller.updateEvents(vnf.NodeFlowEvents(
      node: vnf.NodeEvents(
        onCreated: (_) => _onGraphChanged(),
        onDeleted: (_) => _onGraphChanged(),
        onDragStop: (_) => _onGraphChanged(),
      ),
      connection: vnf.ConnectionEvents(
        onCreated: (_) => _onGraphChanged(),
        onDeleted: (_) => _onGraphChanged(),
      ),
      onSelectionChange: (_) => notifyListeners(),
    ));
  }

  void _onGraphChanged() {
    _persistence.saveDraft(currentWorkflow);
    notifyListeners();
  }

  models.Workflow get currentWorkflow => models.Workflow(
    id: _workflowId,
    name: _workflowName,
    nodes: controller.nodes.values.map((n) => n.data).toList(),
    connections: controller.connections.map((c) => models.ConnectionData(
      sourceNodeId: c.sourceNodeId,
      sourcePortId: c.sourcePortId,
      targetNodeId: c.targetNodeId,
      targetPortId: c.targetPortId,
    )).toList(),
    variables: _engine.variables,
  );

  void addNode(models.NodeData data) {
    final List<vnf.Port> ports = [];
    
    // Inputs
    if (data is! models.StartNode) {
       ports.add(vnf.Port(
         id: 'in', 
         name: 'In', 
         type: vnf.PortType.input, 
         position: vnf.PortPosition.left,
       ));
    }
    
    // Outputs
    if (data is models.BranchNode) {
       for (final outcome in data.outcomes) {
         ports.add(vnf.Port(
           id: outcome, 
           name: outcome, 
           type: vnf.PortType.output, 
           position: vnf.PortPosition.right,
         ));
       }
    } else if (data is models.VisualCheckNode) {
       ports.add(vnf.Port(
         id: 'Found', 
         name: 'Found', 
         type: vnf.PortType.output, 
         position: vnf.PortPosition.right,
       ));
       ports.add(vnf.Port(
         id: 'Not Found', 
         name: 'Not Found', 
         type: vnf.PortType.output, 
         position: vnf.PortPosition.right,
       ));
    } else if (data is! models.EndNode) {
       ports.add(vnf.Port(
         id: 'out', 
         name: 'Out', 
         type: vnf.PortType.output, 
         position: vnf.PortPosition.right,
       ));
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
    await _engine.run(currentWorkflow);
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
      controller.addNode(vnf.Node<models.NodeData>(
        id: node.id,
        type: node.type,
        position: node.position.value,
        data: newData,
        ports: node.ports.toList(),
      ));
      
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
      controller.addNode(vnf.Node<models.NodeData>(
        id: node.id,
        type: node.type,
        position: node.position.value,
        data: newData,
        ports: node.ports.toList(),
      ));
      
      notifyListeners();
    }
  }
  
  Future<void> exportWorkflow() async {
    final targetFile = File('exported_workflow.swflow');
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
