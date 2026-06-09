import 'package:flutter_test/flutter_test.dart';
import 'package:macaque/features/assets/view_models/asset_view_model.dart';
import 'package:macaque/features/assets/services/asset_storage_service.dart';
import 'package:macaque/features/assets/models/asset.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'asset_view_model_test.mocks.dart';

@GenerateMocks([AssetStorageService])
void main() {
  late AssetViewModel viewModel;
  late MockAssetStorageService mockStorageService;

  setUp(() {
    mockStorageService = MockAssetStorageService();
    // We need to provide a default response for loadAssets since it's called in init
    when(mockStorageService.loadAssets()).thenAnswer((_) async => []);
    viewModel = AssetViewModel(storageService: mockStorageService);
  });

  group('AssetViewModel', () {
    test('initial state is empty', () {
      expect(viewModel.assets, isEmpty);
      expect(viewModel.isLoading, isFalse);
    });

    test('refreshAssets updates assets list', () async {
      final assets = [
        Asset(
          id: '1',
          filename: 'test.png',
          path: '/path/to/test.png',
          status: AssetStatus.available,
          lastModified: DateTime.now(),
        ),
      ];
      when(mockStorageService.loadAssets()).thenAnswer((_) async => assets);

      await viewModel.refreshAssets();

      expect(viewModel.assets.length, 1);
      expect(viewModel.assets.first.id, '1');
      verify(mockStorageService.loadAssets()).called(greaterThan(0));
    });

    test('deleteAsset removes asset and saves', () async {
      final asset = Asset(
        id: '1',
        filename: 'test.png',
        path: '/path/to/test.png',
        status: AssetStatus.available,
        lastModified: DateTime.now(),
      );

      // Inject asset into viewModel (normally done via refreshAssets or import)
      when(mockStorageService.loadAssets()).thenAnswer((_) async => [asset]);
      await viewModel.refreshAssets();
      expect(viewModel.assets.length, 1);

      when(mockStorageService.deleteAsset(asset)).thenAnswer((_) async => {});
      when(mockStorageService.saveAssets(any)).thenAnswer((_) async => {});

      await viewModel.deleteAsset(asset);

      expect(viewModel.assets, isEmpty);
      verify(mockStorageService.deleteAsset(asset)).called(1);
      verify(mockStorageService.saveAssets([])).called(1);
    });

    test('importAssets filters non-image files', () async {
      final paths = ['/path/to/test.png', '/path/to/test.txt'];

      when(
        mockStorageService.importAsset(
          any,
          targetFilename: anyNamed('targetFilename'),
        ),
      ).thenAnswer(
        (invocation) async => Asset(
          id: '1',
          filename: 'test.png',
          path: '/path/to/test.png',
          status: AssetStatus.available,
          lastModified: DateTime.now(),
        ),
      );
      when(mockStorageService.saveAssets(any)).thenAnswer((_) async => {});

      await viewModel.importAssets(paths);

      expect(viewModel.assets.length, 1);
      expect(viewModel.assets.first.filename, 'test.png');
      verify(
        mockStorageService.importAsset(
          '/path/to/test.png',
          targetFilename: 'test.png',
        ),
      ).called(1);
      verifyNever(
        mockStorageService.importAsset(
          '/path/to/test.txt',
          targetFilename: anyNamed('targetFilename'),
        ),
      );
    });

    test('importAssets handles rename on collision', () async {
      final existingAsset = Asset(
        id: '1',
        filename: 'test.png',
        path: '/path/to/test.png',
        status: AssetStatus.available,
        lastModified: DateTime.now(),
      );

      when(
        mockStorageService.loadAssets(),
      ).thenAnswer((_) async => [existingAsset]);
      await viewModel.refreshAssets();

      final paths = ['/new/test.png'];

      when(
        mockStorageService.generateUniqueFilename('test.png'),
      ).thenAnswer((_) async => 'test_1.png');
      when(
        mockStorageService.importAsset(
          '/new/test.png',
          targetFilename: 'test_1.png',
        ),
      ).thenAnswer(
        (_) async => Asset(
          id: '2',
          filename: 'test_1.png',
          path: '/path/to/test_1.png',
          status: AssetStatus.available,
          lastModified: DateTime.now(),
        ),
      );
      when(mockStorageService.saveAssets(any)).thenAnswer((_) async => {});

      await viewModel.importAssets(
        paths,
        onDuplicate: (filename) async => DuplicateResolution.rename,
      );

      expect(viewModel.assets.length, 2);
      expect(viewModel.assets[1].filename, 'test_1.png');
      verify(mockStorageService.generateUniqueFilename('test.png')).called(1);
    });
  });
}
