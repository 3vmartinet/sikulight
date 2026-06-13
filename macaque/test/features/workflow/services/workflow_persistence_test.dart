import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:macaque/features/workflow/models/workflow_models.dart';
import 'package:macaque/features/workflow/services/workflow_persistence.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:path/path.dart' as p;

class MockPathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final String _tempPath;
  final String _docsPath;

  MockPathProviderPlatform(this._tempPath, this._docsPath);

  @override
  Future<String?> getTemporaryPath() async => _tempPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => _docsPath;
}

void main() {
  late WorkflowPersistence persistence;
  late Directory baseTestDir;
  late String tempDirPath;
  late String docsDirPath;

  setUp(() async {
    baseTestDir = await Directory.systemTemp.createTemp('workflow_persistence_test');
    
    // We create non-existent subdirectories under the base temp directory
    tempDirPath = p.join(baseTestDir.path, 'non_existent_temp_sub_dir');
    docsDirPath = p.join(baseTestDir.path, 'non_existent_docs_sub_dir');

    PathProviderPlatform.instance = MockPathProviderPlatform(tempDirPath, docsDirPath);
    persistence = WorkflowPersistence();
  });

  tearDown(() async {
    if (await baseTestDir.exists()) {
      await baseTestDir.delete(recursive: true);
    }
  });

  group('WorkflowPersistence', () {
    test('saveWorkflow should recursively create directories and save workflow bundle', () async {
      final workflow = Workflow(
        id: '1781344267042',
        name: 'Test Workflow',
        nodes: [],
        connections: [],
      );

      final targetPath = p.join(baseTestDir.path, 'output_dir', 'workflow.macaque');
      final targetFile = File(targetPath);

      // Verify that neither the temporary directory nor target parent directory exists initially
      expect(await Directory(tempDirPath).exists(), isFalse);
      expect(await Directory(p.join(baseTestDir.path, 'output_dir')).exists(), isFalse);

      // Execute saveWorkflow
      await expectLater(
        persistence.saveWorkflow(
          workflow: workflow,
          assets: [],
          targetFile: targetFile,
        ),
        completes,
      );

      // Verify directory creation and target file existence
      expect(await targetFile.exists(), isTrue);
    });
  });
}
