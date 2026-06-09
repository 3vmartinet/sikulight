import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class IsolatedAssetStore {
  final String workflowId;
  late final String rootPath;

  IsolatedAssetStore({required this.workflowId});

  /// Initializes the storage path: ${tempDir}/sikulite_imports/${workflowId}/assets/
  Future<void> init() async {
    final tempDir = await getTemporaryDirectory();
    rootPath = p.join(tempDir.path, 'sikulite_imports', workflowId, 'assets');
  }

  String get assetPath => rootPath;

  /// Returns the absolute path for a specific asset within this store.
  String getPathForAsset(String assetFileName) {
    return p.join(rootPath, assetFileName);
  }

  /// Checks if the store exists on disk.
  Future<bool> exists() async {
    return Directory(rootPath).exists();
  }
}
