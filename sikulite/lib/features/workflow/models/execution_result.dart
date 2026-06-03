import 'package:equatable/equatable.dart';

class ExecutionDetails extends Equatable {
  final String mode;
  final int exitCode;
  final String stdout;
  final String stderr;

  const ExecutionDetails({
    required this.mode,
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  factory ExecutionDetails.fromJson(Map<String, dynamic> json) => ExecutionDetails(
    mode: json['mode'] as String,
    exitCode: json['exit_code'] as int,
    stdout: json['stdout'] as String,
    stderr: json['stderr'] as String,
  );

  Map<String, dynamic> toJson() => {
    'mode': mode,
    'exit_code': exitCode,
    'stdout': stdout,
    'stderr': stderr,
  };

  @override
  List<Object?> get props => [mode, exitCode, stdout, stderr];
}

class ExecutionResult extends Equatable {
  final bool success;
  final String message;
  final List<int>? coordinates;
  final ExecutionDetails? executionDetails;

  const ExecutionResult({
    required this.success,
    required this.message,
    this.coordinates,
    this.executionDetails,
  });

  factory ExecutionResult.fromJson(Map<String, dynamic> json) => ExecutionResult(
    success: json['success'] as bool,
    message: json['message'] as String,
    coordinates: (json['coordinates'] as List<dynamic>?)?.cast<int>(),
    executionDetails: json['execution_details'] != null
        ? ExecutionDetails.fromJson(json['execution_details'] as Map<String, dynamic>)
        : null,
  );

  Map<String, dynamic> toJson() => {
    'success': success,
    'message': message,
    'coordinates': coordinates,
    'execution_details': executionDetails?.toJson(),
  };

  @override
  List<Object?> get props => [success, message, coordinates, executionDetails];
}
