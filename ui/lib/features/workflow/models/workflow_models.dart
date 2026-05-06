import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:ui/features/tasks/task_command.dart';

class PortData extends Equatable {
  final String id;
  final String name;

  const PortData({required this.id, required this.name});

  @override
  List<Object?> get props => [id, name];

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  factory PortData.fromJson(Map<String, dynamic> json) => PortData(
    id: json['id'] as String,
    name: json['name'] as String,
  );
}

sealed class NodeData extends Equatable {
  final String id;
  final Offset position;
  final List<PortData> inputs;

  const NodeData({required this.id, required this.position, this.inputs = const []});

  NodeData copyWith({Offset? position, List<PortData>? inputs});

  String get type;

  @override
  List<Object?> get props => [id, position, inputs];

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'position': {'x': position.dx, 'y': position.dy},
    'inputs': inputs.map((p) => p.toJson()).toList(),
    ...extraToJson(),
  };

  Map<String, dynamic> toEngineJson(Map<String, String> assetMap) {
    final json = toJson();
    if (this is ExistNode) {
      json['referenceImagePath'] = assetMap[(this as ExistNode).assetId] ?? '';
    } else if (this is VisualCheckNode) {
      json['referenceImagePath'] = assetMap[(this as VisualCheckNode).assetId] ?? '';
    } else if (this is VdaActionNode) {
      final node = this as VdaActionNode;
      if (node.assetId != null) {
        final path = assetMap[node.assetId!] ?? '';
        final cmdJson = node.command.toJson();
        cmdJson['reference_image_path'] = path;
        json['command'] = cmdJson;
      }
    }
    return json;
  }

  Map<String, dynamic> extraToJson();

  static NodeData fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    final id = json['id'] as String;
    final positionJson = json['position'] as Map<String, dynamic>;
    final position = Offset(
      (positionJson['x'] as num).toDouble(),
      (positionJson['y'] as num).toDouble(),
    );
    final inputs = (json['inputs'] as List<dynamic>?)
        ?.map((p) => PortData.fromJson(p as Map<String, dynamic>))
        .toList() ?? [];

    switch (type) {
      case 'start':
        return StartNode(id: id, position: position, inputs: inputs);
      case 'end':
        return EndNode(id: id, position: position, inputs: inputs);
      case 'vda_action':
        return VdaActionNode(
          id: id,
          position: position,
          inputs: inputs,
          command: TaskCommand.fromJson(
            json['command'] as Map<String, dynamic>,
          ),
          timeoutOverride: json['timeoutOverride'] as int?,
          assetId: json['assetId'] as String?,
        );
      case 'visual_check':
        return VisualCheckNode(
          id: id,
          position: position,
          inputs: inputs,
          assetId: json['assetId'] as String,
          confidenceThreshold: (json['confidenceThreshold'] as num).toDouble(),
          timeoutSeconds: json['timeoutSeconds'] as int,
        );
      case 'exist':
        return ExistNode(
          id: id,
          position: position,
          inputs: inputs,
          assetId: json['assetId'] as String,
        );
      case 'branch':
        return BranchNode(
          id: id,
          position: position,
          inputs: inputs,
          conditionType: ConditionType.values.byName(
            json['conditionType'] as String,
          ),
          outcomes: (json['outcomes'] as List<dynamic>).cast<String>(),
        );
      case 'loop':
        return LoopNode(
          id: id,
          position: position,
          inputs: inputs,
          loopType: LoopType.values.byName(json['loopType'] as String),
          maxIterations: json['maxIterations'] as int,
        );
      case 'variable_set':
        return VariableNode(
          id: id,
          position: position,
          inputs: inputs,
          variableName: json['variableName'] as String,
          operation: VariableOperation.values.byName(
            json['operation'] as String,
          ),
          value: json['value'],
        );
      case 'wait':
        return WaitNode(
          id: id,
          position: position,
          inputs: inputs,
          durationSeconds: json['durationSeconds'] as int,
        );
      default:
        throw Exception('Unknown node type: $type');
    }
  }
}

class StartNode extends NodeData {
  const StartNode({required super.id, required super.position, super.inputs});

  @override
  NodeData copyWith({Offset? position, List<PortData>? inputs}) =>
      StartNode(id: id, position: position ?? this.position, inputs: inputs ?? this.inputs);

  @override
  String get type => 'start';

  @override
  Map<String, dynamic> extraToJson() => {};
}

class EndNode extends NodeData {
  const EndNode({required super.id, required super.position, super.inputs});

  @override
  NodeData copyWith({Offset? position, List<PortData>? inputs}) =>
      EndNode(id: id, position: position ?? this.position, inputs: inputs ?? this.inputs);

  @override
  String get type => 'end';

  @override
  Map<String, dynamic> extraToJson() => {};
}

class VdaActionNode extends NodeData {
  final TaskCommand command;
  final int? timeoutOverride;
  final String? assetId;

  const VdaActionNode({
    required super.id,
    required super.position,
    required this.command,
    super.inputs,
    this.timeoutOverride,
    this.assetId,
  });

  @override
  NodeData copyWith({
    Offset? position,
    List<PortData>? inputs,
    String? assetId,
    TaskCommand? command,
    int? timeoutOverride,
  }) => VdaActionNode(
    id: id,
    position: position ?? this.position,
    inputs: inputs ?? this.inputs,
    command: command ?? this.command,
    timeoutOverride: timeoutOverride ?? this.timeoutOverride,
    assetId: assetId ?? this.assetId,
  );

  @override
  String get type => 'vda_action';

  @override
  Map<String, dynamic> extraToJson() => {
    'command': command.toJson(),
    'timeoutOverride': timeoutOverride,
    'assetId': assetId,
  };

  @override
  List<Object?> get props => [...super.props, command, timeoutOverride, assetId];
}

class VisualCheckNode extends NodeData {
  final String assetId;
  final double confidenceThreshold;
  final int timeoutSeconds;

  const VisualCheckNode({
    required super.id,
    required super.position,
    super.inputs,
    required this.assetId,
    this.confidenceThreshold = 0.8,
    this.timeoutSeconds = 30,
  });

  @override
  NodeData copyWith({Offset? position, List<PortData>? inputs, String? assetId}) => VisualCheckNode(
    id: id,
    position: position ?? this.position,
    inputs: inputs ?? this.inputs,
    assetId: assetId ?? this.assetId,
    confidenceThreshold: confidenceThreshold,
    timeoutSeconds: timeoutSeconds,
  );

  @override
  String get type => 'visual_check';

  @override
  Map<String, dynamic> extraToJson() => {
    'assetId': assetId,
    'confidenceThreshold': confidenceThreshold,
    'timeoutSeconds': timeoutSeconds,
  };

  @override
  List<Object?> get props => [
    ...super.props,
    assetId,
    confidenceThreshold,
    timeoutSeconds,
  ];
}

enum ConditionType { visualSuccess, variableMatch, fileExists, scriptExitCode }

class BranchNode extends NodeData {
  final ConditionType conditionType;
  final List<String> outcomes;

  const BranchNode({
    required super.id,
    required super.position,
    super.inputs,
    required this.conditionType,
    required this.outcomes,
  });

  @override
  NodeData copyWith({Offset? position, List<PortData>? inputs}) => BranchNode(
    id: id,
    position: position ?? this.position,
    inputs: inputs ?? this.inputs,
    conditionType: conditionType,
    outcomes: outcomes,
  );

  @override
  String get type => 'branch';

  @override
  Map<String, dynamic> extraToJson() => {
    'conditionType': conditionType.name,
    'outcomes': outcomes,
  };

  @override
  List<Object?> get props => [...super.props, conditionType, outcomes];
}

enum LoopType { whileLoop, forLoop }

class LoopNode extends NodeData {
  final LoopType loopType;
  final int maxIterations;

  const LoopNode({
    required super.id,
    required super.position,
    super.inputs,
    required this.loopType,
    this.maxIterations = 100,
  });

  @override
  NodeData copyWith({Offset? position, List<PortData>? inputs}) => LoopNode(
    id: id,
    position: position ?? this.position,
    inputs: inputs ?? this.inputs,
    loopType: loopType,
    maxIterations: maxIterations,
  );

  @override
  String get type => 'loop';

  @override
  Map<String, dynamic> extraToJson() => {
    'loopType': loopType.name,
    'maxIterations': maxIterations,
  };

  @override
  List<Object?> get props => [...super.props, loopType, maxIterations];
}

enum VariableOperation { set, increment, decrement }

class VariableNode extends NodeData {
  final String variableName;
  final VariableOperation operation;
  final dynamic value;

  const VariableNode({
    required super.id,
    required super.position,
    super.inputs,
    required this.variableName,
    required this.operation,
    required this.value,
  });

  @override
  NodeData copyWith({Offset? position, List<PortData>? inputs}) => VariableNode(
    id: id,
    position: position ?? this.position,
    inputs: inputs ?? this.inputs,
    variableName: variableName,
    operation: operation,
    value: value,
  );

  @override
  String get type => 'variable_set';

  @override
  Map<String, dynamic> extraToJson() => {
    'variableName': variableName,
    'operation': operation.name,
    'value': value,
  };

  @override
  List<Object?> get props => [...super.props, variableName, operation, value];
}

class WaitNode extends NodeData {
  final int durationSeconds;

  const WaitNode({
    required super.id,
    required super.position,
    super.inputs,
    required this.durationSeconds,
  });

  @override
  NodeData copyWith({Offset? position, List<PortData>? inputs}) => WaitNode(
    id: id,
    position: position ?? this.position,
    inputs: inputs ?? this.inputs,
    durationSeconds: durationSeconds,
  );

  @override
  String get type => 'wait';

  @override
  Map<String, dynamic> extraToJson() => {'durationSeconds': durationSeconds};

  @override
  List<Object?> get props => [...super.props, durationSeconds];
}

class ExistNode extends NodeData {
  final String assetId;

  const ExistNode({
    required super.id,
    required super.position,
    super.inputs,
    required this.assetId,
  });

  @override
  NodeData copyWith({Offset? position, List<PortData>? inputs, String? assetId}) => ExistNode(
    id: id,
    position: position ?? this.position,
    inputs: inputs ?? this.inputs,
    assetId: assetId ?? this.assetId,
  );

  @override
  String get type => 'exist';

  @override
  Map<String, dynamic> extraToJson() => {'assetId': assetId};

  @override
  List<Object?> get props => [...super.props, assetId];
}

class ConnectionData extends Equatable {
  final String sourceNodeId;
  final String sourcePortId;
  final String targetNodeId;
  final String targetPortId;

  const ConnectionData({
    required this.sourceNodeId,
    required this.sourcePortId,
    required this.targetNodeId,
    required this.targetPortId,
  });

  @override
  List<Object?> get props => [
    sourceNodeId,
    sourcePortId,
    targetNodeId,
    targetPortId,
  ];

  Map<String, dynamic> toJson() => {
    'sourceNodeId': sourceNodeId,
    'sourcePortId': sourcePortId,
    'targetNodeId': targetNodeId,
    'targetPortId': targetPortId,
  };

  factory ConnectionData.fromJson(Map<String, dynamic> json) => ConnectionData(
    sourceNodeId: json['sourceNodeId'] as String,
    sourcePortId: json['sourcePortId'] as String,
    targetNodeId: json['targetNodeId'] as String,
    targetPortId: json['targetPortId'] as String,
  );
}

class Workflow extends Equatable {
  final String id;
  final String name;
  final List<NodeData> nodes;
  final List<ConnectionData> connections;
  final Map<String, dynamic> variables;

  const Workflow({
    required this.id,
    required this.name,
    required this.nodes,
    required this.connections,
    this.variables = const {},
  });

  @override
  List<Object?> get props => [id, name, nodes, connections, variables];

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'nodes': nodes.map((e) => e.toJson()).toList(),
    'connections': connections.map((e) => e.toJson()).toList(),
    'variables': variables,
  };

  Map<String, dynamic> toEngineJson(Map<String, String> assetMap) => {
    'id': id,
    'name': name,
    'nodes': nodes.map((e) => e.toEngineJson(assetMap)).toList(),
    'connections': connections.map((e) => e.toJson()).toList(),
    'variables': variables,
  };

  factory Workflow.fromJson(Map<String, dynamic> json) => Workflow(
    id: json['id'] as String,
    name: json['name'] as String,
    nodes: (json['nodes'] as List<dynamic>)
        .map((e) => NodeData.fromJson(e as Map<String, dynamic>))
        .toList(),
    connections: (json['connections'] as List<dynamic>)
        .map((e) => ConnectionData.fromJson(e as Map<String, dynamic>))
        .toList(),
    variables: json['variables'] as Map<String, dynamic>,
  );
}
