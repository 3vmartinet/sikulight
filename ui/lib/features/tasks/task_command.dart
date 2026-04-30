import 'package:equatable/equatable.dart';

class TaskProfile extends Equatable {
  final String mode;
  final String standardAction;
  final double confidenceThreshold;
  final int timeoutSeconds;

  const TaskProfile({
    required this.mode,
    required this.standardAction,
    required this.confidenceThreshold,
    required this.timeoutSeconds,
  });

  factory TaskProfile.fromJson(Map<String, dynamic> json) {
    return TaskProfile(
      mode: json['mode'] as String,
      standardAction: json['standard_action'] as String,
      confidenceThreshold: (json['confidence_threshold'] as num).toDouble(),
      timeoutSeconds: json['timeout_seconds'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mode': mode,
      'standard_action': standardAction,
      'confidence_threshold': confidenceThreshold,
      'timeout_seconds': timeoutSeconds,
    };
  }

  @override
  List<Object?> get props => [
    mode,
    standardAction,
    confidenceThreshold,
    timeoutSeconds,
  ];
}

class TaskCommand extends Equatable {
  final String name;
  final String referenceImagePath;
  final TaskProfile profile;

  const TaskCommand({
    required this.name,
    required this.referenceImagePath,
    required this.profile,
  });

  factory TaskCommand.fromJson(Map<String, dynamic> json) {
    return TaskCommand(
      name: json['name'] as String,
      referenceImagePath: json['reference_image_path'] as String,
      profile: TaskProfile.fromJson(json['profile'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'reference_image_path': referenceImagePath,
      'profile': profile.toJson(),
    };
  }

  @override
  List<Object?> get props => [name, referenceImagePath, profile];
}
