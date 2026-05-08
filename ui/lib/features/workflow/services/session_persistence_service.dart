import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:ui/features/workflow/models/workspace_models.dart';

class SessionPersistenceService {
  final Directory? testBaseDir;
  static const String _sessionFileName = 'session_history.json';

  SessionPersistenceService({this.testBaseDir});

  Future<File> _getSessionFile() async {
    if (testBaseDir != null) {
      return File(p.join(testBaseDir!.path, _sessionFileName));
    }
    final directory = await getApplicationDocumentsDirectory();
    return File(p.join(directory.path, _sessionFileName));
  }

  Future<void> saveSession(WorkspaceSession session) async {
    try {
      final file = await _getSessionFile();
      final jsonString = jsonEncode(session.toJson());
      await file.writeAsString(jsonString);
      debugPrint('Session saved to ${file.path}');
    } catch (e) {
      debugPrint('Error saving session: $e');
    }
  }

  Future<WorkspaceSession?> loadSession() async {
    try {
      final file = await _getSessionFile();
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
        return WorkspaceSession.fromJson(jsonMap);
      }
    } catch (e) {
      debugPrint('Error loading session: $e');
    }
    return null;
  }
}
