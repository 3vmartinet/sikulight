import 'package:ui/features/workflow/view_models/workflow_view_model.dart';

class WorkspaceSession {
  final String? activeWorkflowPath;
  final List<String> openFilePaths;
  final DateTime lastUpdated;

  WorkspaceSession({
    this.activeWorkflowPath,
    required this.openFilePaths,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() {
    return {
      'active_workflow_path': activeWorkflowPath,
      'open_file_paths': openFilePaths,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  factory WorkspaceSession.fromJson(Map<String, dynamic> json) {
    return WorkspaceSession(
      activeWorkflowPath: json['active_workflow_path'] as String?,
      openFilePaths: (json['open_file_paths'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'] as String)
          : DateTime.now(),
    );
  }

  WorkspaceSession copyWith({
    String? activeWorkflowPath,
    List<String>? openFilePaths,
    DateTime? lastUpdated,
  }) {
    return WorkspaceSession(
      activeWorkflowPath: activeWorkflowPath ?? this.activeWorkflowPath,
      openFilePaths: openFilePaths ?? this.openFilePaths,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class TabMetadata {
  final String id;
  final String name;
  final String? filePath;
  final bool isModified;
  final WorkflowViewModel viewModel;

  TabMetadata({
    required this.id,
    required this.name,
    this.filePath,
    this.isModified = false,
    required this.viewModel,
  });

  TabMetadata copyWith({
    String? name,
    String? filePath,
    bool? isModified,
  }) {
    return TabMetadata(
      id: id,
      name: name ?? this.name,
      filePath: filePath ?? this.filePath,
      isModified: isModified ?? this.isModified,
      viewModel: viewModel,
    );
  }
}
