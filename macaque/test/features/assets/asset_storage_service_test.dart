import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:macaque/features/assets/services/asset_storage_service.dart';
import 'package:macaque/core/utils/isolate_processor_service.dart';
import 'package:macaque/features/assets/models/asset.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'asset_storage_service_test.mocks.dart';

@GenerateMocks([IsolateProcessorService])
void main() {
  late AssetStorageService service;
  late MockIsolateProcessorService mockIsolateProcessor;
  late Directory tempDir;

  setUp(() async {
    mockIsolateProcessor = MockIsolateProcessorService();
    tempDir = await Directory.systemTemp.createTemp('asset_storage_test');
    service = AssetStorageService(
      isolateProcessor: mockIsolateProcessor,
      testBaseDir: tempDir,
    );

    // Stub IsolateProcessorService.run to return Future<Null>
    when(mockIsolateProcessor.run<Null>(any)).thenAnswer((_) async => null);
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  group('AssetStorageService', () {
    test('saveAssets and loadAssets should persist metadata', () async {
      final assets = [
        Asset(
          id: '1',
          filename: 'test.png',
          path: '/path/to/test.png',
          status: AssetStatus.available,
          lastModified: DateTime.now(),
        ),
      ];

      await service.saveAssets(assets);
      final loadedAssets = await service.loadAssets();

      expect(loadedAssets.length, 1);
      expect(loadedAssets.first.id, '1');
      expect(loadedAssets.first.filename, 'test.png');
    });

    test('importAsset should copy file to assets directory', () async {
      final assetsDir = Directory('${tempDir.path}/Assets');
      await assetsDir.create(recursive: true);

      final sourceFile = File('${tempDir.path}/source.png');
      // Minimal PNG-like bytes to avoid decoder crash if it checks header
      await sourceFile.writeAsBytes([
        0x89,
        0x50,
        0x4E,
        0x47,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
        0,
        0,
        0,
        13,
        73,
        72,
        68,
        82,
        0,
        0,
        0,
        1,
        0,
        0,
        0,
        1,
        8,
        2,
        0,
        0,
        0,
        144,
        119,
        83,
        222,
        0,
        0,
        0,
        0,
        73,
        69,
        78,
        68,
        174,
        66,
        96,
        130,
      ]);

      final asset = await service.importAsset(sourceFile.path);

      expect(asset, isNotNull);
      expect(await File(asset!.path).exists(), isTrue);
      expect(asset.filename, 'source.png');
      verify(mockIsolateProcessor.run<Null>(any)).called(1);
    });

    test(
      'generateUniqueFilename should return new name if collision exists',
      () async {
        final assetsDir = Directory('${tempDir.path}/Assets');
        await assetsDir.create(recursive: true);

        await File('${assetsDir.path}/test.png').writeAsString('dummy');

        final uniqueName = await service.generateUniqueFilename('test.png');

        expect(uniqueName, 'test_1.png');
      },
    );

    test(
      'renameAsset should rename file on disk and return updated asset',
      () async {
        final assetsDir = Directory('${tempDir.path}/Assets');
        await assetsDir.create(recursive: true);

        // Create a dummy file
        final oldFile = File('${assetsDir.path}/old.png');
        await oldFile.writeAsString('dummy');

        final asset = Asset(
          id: '1',
          filename: 'old.png',
          path: oldFile.path,
          status: AssetStatus.available,
          lastModified: DateTime.now(),
        );

        final updatedAsset = await service.renameAsset(asset, 'new.png');

        expect(updatedAsset.filename, 'new.png');
        expect(updatedAsset.path, endsWith('new.png'));
        expect(await File(updatedAsset.path).exists(), isTrue);
        expect(await oldFile.exists(), isFalse);
      },
    );

    test('deleteAsset should remove file and thumbnail from disk', () async {
      final assetsDir = Directory('${tempDir.path}/Assets');
      await assetsDir.create(recursive: true);

      final file = File('${assetsDir.path}/test.png');
      await file.writeAsString('dummy');

      final thumbDir = Directory('${assetsDir.path}/.thumbnails');
      await thumbDir.create(recursive: true);
      final thumbFile = File('${thumbDir.path}/1.png');
      await thumbFile.writeAsString('dummy_thumb');

      final asset = Asset(
        id: '1',
        filename: 'test.png',
        path: file.path,
        status: AssetStatus.available,
        lastModified: DateTime.now(),
      );

      await service.deleteAsset(asset);

      expect(await file.exists(), isFalse);
      expect(await thumbFile.exists(), isFalse);
    });
  });
}
