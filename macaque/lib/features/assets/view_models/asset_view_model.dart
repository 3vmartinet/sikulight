import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:watcher/watcher.dart';
import 'package:path/path.dart' as p;
import 'package:macaque/features/assets/models/asset.dart';
import 'package:macaque/features/assets/services/asset_storage_service.dart';
import 'package:macaque/core/constants.dart';

enum DuplicateResolution { overwrite, rename, skip }

class AssetViewModel extends ChangeNotifier {
  final AssetStorageService _storageService;

  List<Asset> _assets = [];
  List<Asset> _isolatedAssets = [];
  bool _isLoading = false;
  StreamSubscription<WatchEvent>? _watcherSubscription;

  AssetViewModel({required AssetStorageService storageService})
    : _storageService = storageService {
    _init();
  }

  List<Asset> get assets => _assets;
  List<Asset> get isolatedAssets => _isolatedAssets;
  bool get isLoading => _isLoading;

  Future<void> _init() async {
    await refreshAssets();
    _startWatching();
  }

  Future<void> refreshAssets() async {
    _isLoading = true;
    notifyListeners();

    _assets = await _storageService.loadAssets();

    // Validate existence
    for (var i = 0; i < _assets.length; i++) {
      final asset = _assets[i];
      final file = File(asset.path);
      if (!await file.exists()) {
        _assets[i] = asset.copyWith(status: AssetStatus.missing);
      } else {
        _assets[i] = asset.copyWith(status: AssetStatus.available);
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Refreshes isolated assets from a specific directory (used for workflow assets)
  Future<void> refreshIsolatedAssets(String directoryPath) async {
    final dir = Directory(directoryPath);
    if (!await dir.exists()) {
      _isolatedAssets = [];
      notifyListeners();
      return;
    }

    final files = dir.listSync().whereType<File>();
    final newAssets = <Asset>[];

    for (final file in files) {
      final filename = p.basename(file.path);
      final extension = filename.split('.').last.toLowerCase();

      if (AppConstants.supportedImageExtensions.contains(extension)) {
        newAssets.add(Asset(
          id: filename, // Using filename as ID for isolated assets
          filename: filename,
          path: file.path,
          status: AssetStatus.available,
          lastModified: (await file.lastModified()),
        ));
      }
    }

    _isolatedAssets = newAssets;
    notifyListeners();
  }

  void _startWatching() async {
    // This is simplified, in a real app we'd get the path from service
    // For now we assume a standard path or get it from first asset if available
    // Better: service exposes the directory path
  }

  Future<void> importAssets(
    List<String> paths, {
    Future<DuplicateResolution?> Function(String)? onDuplicate,
  }) async {
    for (final path in paths) {
      final file = File(path);
      final filename = file.uri.pathSegments.last;
      final extension = filename.split('.').last.toLowerCase();

      if (!AppConstants.supportedImageExtensions.contains(extension)) {
        continue;
      }

      String finalFilename = filename;

      // Check for existence
      final existingIndex = _assets.indexWhere((a) => a.filename == filename);
      if (existingIndex != -1 && onDuplicate != null) {
        final resolution = await onDuplicate(filename);
        if (resolution == null || resolution == DuplicateResolution.skip) {
          continue;
        }

        if (resolution == DuplicateResolution.overwrite) {
          await _storageService.deleteAsset(_assets[existingIndex]);
          _assets.removeAt(existingIndex);
        } else if (resolution == DuplicateResolution.rename) {
          finalFilename = await _storageService.generateUniqueFilename(
            filename,
          );
        }
      }

      final asset = await _storageService.importAsset(
        path,
        targetFilename: finalFilename,
      );
      if (asset != null) {
        _assets.add(asset);
      }
    }
    await _storageService.saveAssets(_assets);
    notifyListeners();
  }

  Future<void> deleteAsset(Asset asset) async {
    await _storageService.deleteAsset(asset);
    _assets.removeWhere((a) => a.id == asset.id);
    await _storageService.saveAssets(_assets);
    notifyListeners();
  }

  Future<void> renameAsset(Asset asset, String newFilename) async {
    final updatedAsset = await _storageService.renameAsset(asset, newFilename);
    final index = _assets.indexWhere((a) => a.id == asset.id);
    if (index != -1) {
      _assets[index] = updatedAsset;
    }
    await _storageService.saveAssets(_assets);
    notifyListeners();
  }

  Future<void> repairRegistry() async {
    _isLoading = true;
    notifyListeners();

    final scannedAssets = await _storageService.scanDirectory();

    // Merge: keep existing IDs for matching filenames
    final newAssets = <Asset>[];
    for (final scanned in scannedAssets) {
      final existing = _assets
          .where((a) => a.filename == scanned.filename)
          .firstOrNull;
      if (existing != null) {
        newAssets.add(
          existing.copyWith(
            path: scanned.path,
            status: AssetStatus.available,
            lastModified: scanned.lastModified,
          ),
        );
      } else {
        newAssets.add(scanned);
      }
    }

    _assets = newAssets;
    await _storageService.saveAssets(_assets);

    _isLoading = false;
    notifyListeners();
  }

  Future<String> getThumbnailPath(Asset asset) async {
    return _storageService.getThumbnailPath(asset);
  }

  @override
  void dispose() {
    _watcherSubscription?.cancel();
    super.dispose();
  }
}
