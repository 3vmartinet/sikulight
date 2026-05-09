import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ui/core/constants.dart';
import 'package:ui/core/utils/isolate_processor_service.dart';
import 'package:ui/features/assets/models/asset.dart';
import 'package:uuid/uuid.dart';
import 'package:image/image.dart' as img;

class AssetStorageService {
  final IsolateProcessorService _isolateProcessor;
  final Uuid _uuid = const Uuid();
  final Directory? _testBaseDir;

  AssetStorageService({
    required IsolateProcessorService isolateProcessor,
    Directory? testBaseDir,
  }) : _isolateProcessor = isolateProcessor,
       _testBaseDir = testBaseDir;

  Future<Directory> get _assetsDirectory async {
    if (_testBaseDir != null) {
      final dir = Directory('${_testBaseDir.path}/Assets');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    }

    Directory baseDir;
    if (Platform.isMacOS) {
      baseDir = await getApplicationSupportDirectory();
    } else {
      baseDir = await getApplicationDocumentsDirectory();
    }
    final dir = Directory('${baseDir.path}/Assets');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<File> get _metadataFile async {
    final dir = await _assetsDirectory;
    return File('${dir.path}/${AppConstants.assetMetadataFileName}');
  }

  Future<Directory> get _thumbnailDirectory async {
    final dir = await _assetsDirectory;
    final thumbDir = Directory('${dir.path}/${AppConstants.thumbnailDirName}');
    if (!await thumbDir.exists()) {
      await thumbDir.create(recursive: true);
    }
    return thumbDir;
  }

  Future<List<Asset>> loadAssets() async {
    final file = await _metadataFile;
    if (!await file.exists()) {
      debugPrint('Asset metadata file not found at ${file.path}');
      return [];
    }

    try {
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      final assetsJson = data['assets'] as List;
      return assetsJson
          .map((j) => Asset.fromJson(jsonDecode(jsonEncode(j))))
          .toList();
    } catch (e) {
      debugPrint('Error loading assets from ${file.path}: $e');
      return [];
    }
  }

  Future<void> saveAssets(List<Asset> assets) async {
    try {
      final file = await _metadataFile;
      final list = assets.map((a) => a.toJson()).toList();
      await file.writeAsString(jsonEncode({'version': 1, 'assets': list}));
      debugPrint('Saved ${assets.length} assets to metadata.');
    } catch (e) {
      debugPrint('Error saving assets metadata: $e');
    }
  }

  Future<Asset?> importAsset(
    String sourcePath, {
    String? targetFilename,
  }) async {
    final dir = await _assetsDirectory;
    final sourceFile = File(sourcePath);
    final filename = targetFilename ?? sourceFile.uri.pathSegments.last;
    final targetPath = '${dir.path}/$filename';

    // Copy file
    await sourceFile.copy(targetPath);

    final id = _uuid.v4();
    final asset = Asset(
      id: id,
      filename: filename,
      path: targetPath,
      status: AssetStatus.available,
      lastModified: DateTime.now(),
    );

    // Generate thumbnail in Isolate
    await _generateThumbnail(asset);

    return asset;
  }

  Future<String> generateUniqueFilename(String originalFilename) async {
    final dir = await _assetsDirectory;
    final nameParts = originalFilename.split('.');
    final extension = nameParts.removeLast();
    final baseName = nameParts.join('.');

    int counter = 1;
    String newFilename = originalFilename;
    while (await File('${dir.path}/$newFilename').exists()) {
      newFilename = '${baseName}_$counter.$extension';
      counter++;
    }
    return newFilename;
  }

  Future<void> _generateThumbnail(Asset asset) async {
    final thumbDir = await _thumbnailDirectory;
    final thumbPath = '${thumbDir.path}/${asset.id}.png';

    final bytes = await File(asset.path).readAsBytes();

    await _isolateProcessor.run(() {
      final image = img.decodeImage(bytes);
      if (image == null) return;

      final thumbnail = img.copyResize(
        image,
        width: AppConstants.thumbnailSize.toInt(),
        height: AppConstants.thumbnailSize.toInt(),
        interpolation: img.Interpolation.average,
      );

      File(thumbPath).writeAsBytesSync(img.encodePng(thumbnail));
    });
  }

  Future<String> getThumbnailPath(Asset asset) async {
    final thumbDir = await _thumbnailDirectory;
    return '${thumbDir.path}/${asset.id}.png';
  }

  Future<void> deleteAsset(Asset asset) async {
    final file = File(asset.path);
    if (await file.exists()) {
      await file.delete();
    }

    final thumbFile = File(await getThumbnailPath(asset));
    if (await thumbFile.exists()) {
      await thumbFile.delete();
    }
  }

  Future<Asset> renameAsset(Asset asset, String newFilename) async {
    final dir = await _assetsDirectory;
    final oldFile = File(asset.path);
    final newPath = '${dir.path}/$newFilename';

    if (await oldFile.exists()) {
      await oldFile.rename(newPath);
    }

    return asset.copyWith(
      filename: newFilename,
      path: newPath,
      lastModified: DateTime.now(),
    );
  }

  Future<List<Asset>> scanDirectory() async {
    final dir = await _assetsDirectory;
    final List<Asset> foundAssets = [];

    await for (final entity in dir.list()) {
      if (entity is File) {
        final filename = entity.uri.pathSegments.last;
        final ext = filename.split('.').last.toLowerCase();

        if (AppConstants.supportedImageExtensions.contains(ext) &&
            filename != AppConstants.assetMetadataFileName) {
          foundAssets.add(
            Asset(
              id: _uuid.v4(),
              filename: filename,
              path: entity.path,
              status: AssetStatus.available,
              lastModified: await entity.lastModified(),
            ),
          );
        }
      }
    }
    return foundAssets;
  }
}
