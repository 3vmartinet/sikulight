import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:sikulite/features/workflow/services/archive_service.dart';

void main() {
  late ArchiveService archiveService;
  late Directory tempDir;
  late String workDirPath;

  setUp(() async {
    archiveService = ArchiveService();
    tempDir = await Directory.systemTemp.createTemp('archive_test');
    workDirPath = tempDir.path;
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  group('ArchiveService', () {
    test('bundleWorkflow should create a .macaque file with expected contents', () async {
      final workflowFile = File(p.join(workDirPath, 'workflow.json'));
      await workflowFile.writeAsString('{"id": "test-id"}');

      final asset1 = File(p.join(workDirPath, 'asset1.png'));
      await asset1.writeAsBytes([0, 1, 2]);

      final asset2 = File(p.join(workDirPath, 'asset2.jpg'));
      await asset2.writeAsBytes([3, 4, 5]);

      final outputPath = p.join(workDirPath, 'test.macaque');

      await archiveService.bundleWorkflow(
        workflowFile: workflowFile,
        assets: [asset1, asset2],
        outputPath: outputPath,
      );

      final outputFile = File(outputPath);
      expect(await outputFile.exists(), isTrue);

      // Verify ZIP contents
      final bytes = await outputFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      expect(archive.files.length, 3);
      expect(archive.findFile('workflow.json'), isNotNull);
      expect(archive.findFile('assets/asset1.png'), isNotNull);
      expect(archive.findFile('assets/asset2.jpg'), isNotNull);
    });

    test('extractWorkflow should extract files to destination', () async {
      // Create a dummy ZIP first
      final archive = Archive();
      
      final workflowJson = File(p.join(workDirPath, 'source_workflow.json'));
      await workflowJson.writeAsString('{}');
      archive.addFile(ArchiveFile('workflow.json', workflowJson.lengthSync(), await workflowJson.readAsBytes()));
      
      final assetFile = File(p.join(workDirPath, 'source_asset.png'));
      await assetFile.writeAsBytes([0]);
      archive.addFile(ArchiveFile('assets/source_asset.png', assetFile.lengthSync(), await assetFile.readAsBytes()));
      
      final zipPath = p.join(workDirPath, 'source.macaque');
      await File(zipPath).writeAsBytes(ZipEncoder().encode(archive)!);

      final destinationPath = p.join(workDirPath, 'extraction_target');
      await archiveService.extractWorkflow(
        archiveFile: File(zipPath),
        destinationPath: destinationPath,
      );

      expect(await File(p.join(destinationPath, 'workflow.json')).exists(), isTrue);
      expect(await File(p.join(destinationPath, 'assets', 'source_asset.png')).exists(), isTrue);
    });

    test('deleteIsolatedStore should remove the directory', () async {
      final storePath = p.join(workDirPath, 'to_delete');
      await Directory(storePath).create(recursive: true);
      await File(p.join(storePath, 'some_file.txt')).writeAsString('test');

      expect(await Directory(storePath).exists(), isTrue);

      await archiveService.deleteIsolatedStore(storePath);

      expect(await Directory(storePath).exists(), isFalse);
    });
  });
}
