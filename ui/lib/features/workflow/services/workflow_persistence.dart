import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:ui/features/workflow/models/workflow_models.dart';

class WorkflowPersistence {
  static const String _draftFileName = 'draft_workflow.json';

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _draftFile async {
    final path = await _localPath;
    return File('$path/$_draftFileName');
  }

  Future<void> saveDraft(Workflow workflow) async {
    final file = await _draftFile;
    await file.writeAsString(jsonEncode(workflow.toJson()));
  }

  Future<Workflow?> loadDraft() async {
    try {
      final file = await _draftFile;
      if (await file.exists()) {
        final contents = await file.readAsString();
        return Workflow.fromJson(jsonDecode(contents) as Map<String, dynamic>);
      }
    } catch (e) {
      // Log error
    }
    return null;
  }

  Future<void> exportWorkflow(Workflow workflow, File targetFile) async {
    await targetFile.writeAsString(jsonEncode(workflow.toJson()));
  }

  Future<Workflow?> importWorkflow(File sourceFile) async {
    if (await sourceFile.exists()) {
      final contents = await sourceFile.readAsString();
      return Workflow.fromJson(jsonDecode(contents) as Map<String, dynamic>);
    }
    return null;
  }
}
