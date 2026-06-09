import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sikulite/features/workflow/models/workflow_models.dart';
import 'package:sikulite/features/workflow/services/archive_service.dart';

class WorkflowPersistence {
  static const String exportedFileName = 'exported_workflow.macaque';
  final ArchiveService _archiveService = ArchiveService();

  Future<Directory> get localDirectory async {
    return await getApplicationDocumentsDirectory();
  }

  Future<File> _getDraftFile(String workflowId) async {
    final dir = await localDirectory;
    return File('${dir.path}/draft_$workflowId.json');
  }

  Future<String> getAbsoluteFilePath(
    String workflowId, {
    String? filePath,
  }) async {
    if (filePath != null && !filePath.startsWith('new://')) {
      return filePath;
    }
    final file = await _getDraftFile(workflowId);
    return file.path;
  }

  Future<File> getExportFile({String? fileName}) async {
    final dir = await localDirectory;
    final name = fileName ?? exportedFileName;
    // Ensure .macaque extension
    final finalName = name.endsWith('.macaque') ? name : '$name.macaque';
    return File('${dir.path}/$finalName');
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

  /// Saves a workflow and its assets into a .macaque bundle.
  Future<void> saveWorkflow({
    required Workflow workflow,
    required List<File> assets,
    required File targetFile,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final jsonFile = File('${tempDir.path}/${workflow.id}.json');
    await jsonFile.writeAsString(jsonEncode(workflow.toJson()));

    await _archiveService.bundleWorkflow(
      workflowFile: jsonFile,
      assets: assets,
      outputPath: targetFile.path,
    );

    // Clean up temp JSON
    if (await jsonFile.exists()) {
      await jsonFile.delete();
    }
  }

  /// Loads a workflow from a .macaque bundle and extracts assets to the destination.
  Future<Workflow?> loadWorkflow(File sourceFile, String extractionPath) async {
    debugPrint('Attempting to load .macaque from: ${sourceFile.path}');
    if (!await sourceFile.exists()) return null;

    try {
      await _archiveService.extractWorkflow(
        archiveFile: sourceFile,
        destinationPath: extractionPath,
      );

      final workflowJsonFile = File('$extractionPath/workflow.json');
      if (await workflowJsonFile.exists()) {
        final contents = await workflowJsonFile.readAsString();
        return Workflow.fromJson(jsonDecode(contents) as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('Error loading .macaque from ${sourceFile.path}: $e');
    }
    return null;
  }

  Future<void> exportWorkflow(Workflow workflow, File targetFile) async {
    // For backward compatibility or simple exports without assets
    await targetFile.writeAsString(jsonEncode(workflow.toJson()));
  }

  Future<Workflow?> importWorkflow(File sourceFile) async {
    debugPrint('Attempting to import workflow from: ${sourceFile.path}');
    if (await sourceFile.exists()) {
      try {
        final contents = await sourceFile.readAsString();
        final json = jsonDecode(contents) as Map<String, dynamic>;
        return Workflow.fromJson(json);
      } catch (e) {
        debugPrint('Error importing workflow from ${sourceFile.path}: $e');
        return null;
      }
    }
    return null;
  }
}
