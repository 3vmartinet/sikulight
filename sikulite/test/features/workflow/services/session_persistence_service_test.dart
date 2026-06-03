import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sikulite/features/workflow/models/workspace_models.dart';
import 'package:sikulite/features/workflow/services/session_persistence_service.dart';

void main() {
  late SessionPersistenceService service;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('session_persistence_test');
    service = SessionPersistenceService(testBaseDir: tempDir);
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  group('SessionPersistenceService', () {
    test('saveSession and loadSession should persist session data', () async {
      final session = WorkspaceSession(
        activeWorkflowPath: '/path/to/active.swflow',
        openFilePaths: ['/path/to/active.swflow', '/path/to/other.swflow'],
        lastUpdated: DateTime(2026, 5, 8),
      );

      await service.saveSession(session);
      final loadedSession = await service.loadSession();

      expect(loadedSession, isNotNull);
      expect(loadedSession!.activeWorkflowPath, '/path/to/active.swflow');
      expect(loadedSession.openFilePaths, contains('/path/to/other.swflow'));
      expect(loadedSession.lastUpdated, session.lastUpdated);
    });

    test('loadSession should return null if no session file exists', () async {
      final loadedSession = await service.loadSession();
      expect(loadedSession, isNull);
    });
  });
}
