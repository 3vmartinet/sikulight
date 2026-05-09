import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ui/features/workflow/models/workflow_models.dart';

class WorkflowPersistence {
  static const String exportedFileName = 'exported_workflow.swflow';

  Future<Directory> get localDirectory async {
    return await getApplicationDocumentsDirectory();
  }

  Future<File> _getDraftFile(String workflowId) async {
    final dir = await localDirectory;
    return File('${dir.path}/draft_$workflowId.json');
  }

  Future<String> getAbsoluteFilePath(String workflowId, {String? filePath}) async {
    if (filePath != null && !filePath.startsWith('new://')) {
      return filePath;
    }
    final file = await _getDraftFile(workflowId);
    return file.path;
  }

  Future<File> getExportFile() async {
    final dir = await localDirectory;
    return File('${dir.path}/$exportedFileName');
  }

  Future<void> saveDraft(Workflow workflow) async {
    final file = await _getDraftFile(workflow.id);
    await file.writeAsString(jsonEncode(workflow.toJson()));
  }

  Future<Workflow?> loadDraft(String workflowId) async {
    try {
      final file = await _getDraftFile(workflowId);
      if (await file.exists()) {
        final contents = await file.readAsString();
        return Workflow.fromJson(jsonDecode(contents) as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('Error loading draft for $workflowId: $e');
    }
    return null;
  }

  Future<void> exportWorkflow(Workflow workflow, File targetFile) async {
    await targetFile.writeAsString(jsonEncode(workflow.toJson()));
  }

  Future<Workflow?> importWorkflow(File sourceFile) async {
    debugPrint('Attempting to import workflow from: ${sourceFile.path}');
    if (await sourceFile.exists()) {
      try {
        final contents = await sourceFile.readAsString();
        final json = jsonDecode(contents) as Map<String, dynamic>;
        debugPrint('Successfully loaded JSON from: ${sourceFile.path}. Nodes count: ${(json['nodes'] as List).length}');
        return Workflow.fromJson(json);
      } catch (e) {
        debugPrint('Error importing workflow from ${sourceFile.path}: $e');
        return null;
      }
    }
    debugPrint('File does not exist: ${sourceFile.path}');
    return null;
  }
}
