import 'package:equatable/equatable.dart';

enum StandardAction {
  click('CLICK'),
  doubleClick('DOUBLE_CLICK'),
  rightClick('RIGHT_CLICK'),
  hover('HOVER'),
  middleClick('MIDDLE_CLICK'),
  scroll('SCROLL'),
  none('NONE');

  final String value;
  const StandardAction(this.value);

  static StandardAction fromString(String value) {
    final normalized = value.toUpperCase().trim();
    return StandardAction.values.firstWhere(
      (e) => e.value == normalized,
      orElse: () => StandardAction.click,
    );
  }
}

enum TaskMode {
  standard('STANDARD'),
  delegated('DELEGATED'),
  exist('EXIST');

  final String value;
  const TaskMode(this.value);

  static TaskMode fromString(String value) {
    final normalized = value.toUpperCase().trim();
    return TaskMode.values.firstWhere(
      (e) => e.value == normalized,
      orElse: () => TaskMode.standard,
    );
  }
}

class TaskProfile extends Equatable {
  final TaskMode mode;
  final StandardAction standardAction;
  final double confidenceThreshold;
  final int timeoutSeconds;

  final int? scrollMagnitude;
  final int? x;
  final int? y;

  const TaskProfile({
    required this.mode,
    required this.standardAction,
    required this.confidenceThreshold,
    required this.timeoutSeconds,
    this.scrollMagnitude,
    this.x,
    this.y,
  });

  factory TaskProfile.fromJson(Map<String, dynamic> json) {
    return TaskProfile(
      mode: TaskMode.fromString(json['mode'] as String),
      standardAction: StandardAction.fromString(
        json['standard_action'] as String,
      ),
      confidenceThreshold: (json['confidence_threshold'] as num).toDouble(),
      timeoutSeconds: json['timeout_seconds'] as int,
      scrollMagnitude: json['scroll_magnitude'] as int?,
      x: json['x'] as int?,
      y: json['y'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mode': mode.value,
      'standard_action': standardAction.value,
      'confidence_threshold': confidenceThreshold,
      'timeout_seconds': timeoutSeconds,
      if (scrollMagnitude != null) 'scroll_magnitude': scrollMagnitude,
      if (x != null) 'x': x,
      if (y != null) 'y': y,
    };
  }

  @override
  List<Object?> get props => [
    mode,
    standardAction,
    confidenceThreshold,
    timeoutSeconds,
    scrollMagnitude,
    x,
    y,
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
