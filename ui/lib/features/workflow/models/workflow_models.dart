import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:ui/features/tasks/task_command.dart';

sealed class NodeData extends Equatable {
  final String id;
  final Offset position;

  const NodeData({required this.id, required this.position});

  NodeData copyWith({Offset? position});

  String get type;

  @override
  List<Object?> get props => [id, position];

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'position': {'x': position.dx, 'y': position.dy},
    ...extraToJson(),
  };

  Map<String, dynamic> extraToJson();

  static NodeData fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    final id = json['id'] as String;
    final positionJson = json['position'] as Map<String, dynamic>;
    final position = Offset(
      (positionJson['x'] as num).toDouble(),
      (positionJson['y'] as num).toDouble(),
    );

    switch (type) {
      case 'start':
        return StartNode(id: id, position: position);
      case 'end':
        return EndNode(id: id, position: position);
      case 'vda_action':
        return VdaActionNode(
          id: id,
          position: position,
          command: TaskCommand.fromJson(
            json['command'] as Map<String, dynamic>,
          ),
          timeoutOverride: json['timeoutOverride'] as int?,
        );
      case 'visual_check':
        return VisualCheckNode(
          id: id,
          position: position,
          referenceImagePath: json['referenceImagePath'] as String,
          confidenceThreshold: (json['confidenceThreshold'] as num).toDouble(),
          timeoutSeconds: json['timeoutSeconds'] as int,
        );
      case 'exist':
        return ExistNode(
          id: id,
          position: position,
          referenceImagePath: json['referenceImagePath'] as String,
        );
      case 'branch':
        return BranchNode(
          id: id,
          position: position,
          conditionType: ConditionType.values.byName(
            json['conditionType'] as String,
          ),
          outcomes: (json['outcomes'] as List<dynamic>).cast<String>(),
        );
      case 'loop':
        return LoopNode(
          id: id,
          position: position,
          loopType: LoopType.values.byName(json['loopType'] as String),
          maxIterations: json['maxIterations'] as int,
        );
      case 'variable_set':
        return VariableNode(
          id: id,
          position: position,
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
          durationSeconds: json['durationSeconds'] as int,
        );
      default:
        throw Exception('Unknown node type: $type');
    }
  }
}

class StartNode extends NodeData {
  const StartNode({required super.id, required super.position});

  @override
  NodeData copyWith({Offset? position}) =>
      StartNode(id: id, position: position ?? this.position);

  @override
  String get type => 'start';

  @override
  Map<String, dynamic> extraToJson() => {};
}

class EndNode extends NodeData {
  const EndNode({required super.id, required super.position});

  @override
  NodeData copyWith({Offset? position}) =>
      EndNode(id: id, position: position ?? this.position);

  @override
  String get type => 'end';

  @override
  Map<String, dynamic> extraToJson() => {};
}

class VdaActionNode extends NodeData {
  final TaskCommand command;
  final int? timeoutOverride;

  const VdaActionNode({
    required super.id,
    required super.position,
    required this.command,
    this.timeoutOverride,
  });

  @override
  NodeData copyWith({Offset? position}) => VdaActionNode(
    id: id,
    position: position ?? this.position,
    command: command,
    timeoutOverride: timeoutOverride,
  );

  @override
  String get type => 'vda_action';

  @override
  Map<String, dynamic> extraToJson() => {
    'command': command.toJson(),
    'timeoutOverride': timeoutOverride,
  };

  @override
  List<Object?> get props => [...super.props, command, timeoutOverride];
}

class VisualCheckNode extends NodeData {
  final String referenceImagePath;
  final double confidenceThreshold;
  final int timeoutSeconds;

  const VisualCheckNode({
    required super.id,
    required super.position,
    required this.referenceImagePath,
    this.confidenceThreshold = 0.8,
    this.timeoutSeconds = 30,
  });

  @override
  NodeData copyWith({Offset? position}) => VisualCheckNode(
    id: id,
    position: position ?? this.position,
    referenceImagePath: referenceImagePath,
    confidenceThreshold: confidenceThreshold,
    timeoutSeconds: timeoutSeconds,
  );

  @override
  String get type => 'visual_check';

  @override
  Map<String, dynamic> extraToJson() => {
    'referenceImagePath': referenceImagePath,
    'confidenceThreshold': confidenceThreshold,
    'timeoutSeconds': timeoutSeconds,
  };

  @override
  List<Object?> get props => [
    ...super.props,
    referenceImagePath,
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
    required this.conditionType,
    required this.outcomes,
  });

  @override
  NodeData copyWith({Offset? position}) => BranchNode(
    id: id,
    position: position ?? this.position,
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
    required this.loopType,
    this.maxIterations = 100,
  });

  @override
  NodeData copyWith({Offset? position}) => LoopNode(
    id: id,
    position: position ?? this.position,
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
    required this.variableName,
    required this.operation,
    required this.value,
  });

  @override
  NodeData copyWith({Offset? position}) => VariableNode(
    id: id,
    position: position ?? this.position,
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
    required this.durationSeconds,
  });

  @override
  NodeData copyWith({Offset? position}) => WaitNode(
    id: id,
    position: position ?? this.position,
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
  final String referenceImagePath;

  const ExistNode({
    required super.id,
    required super.position,
    required this.referenceImagePath,
  });

  @override
  NodeData copyWith({Offset? position}) => ExistNode(
    id: id,
    position: position ?? this.position,
    referenceImagePath: referenceImagePath,
  );

  @override
  String get type => 'exist';

  @override
  Map<String, dynamic> extraToJson() => {'referenceImagePath': referenceImagePath};

  @override
  List<Object?> get props => [...super.props, referenceImagePath];
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
