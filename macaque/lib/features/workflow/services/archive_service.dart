import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:macaque/core/logger.dart';

class ArchiveService {
  static const String _logCategory = 'ArchiveService';

  /// Bundles a workflow JSON and its referenced assets into a .macaque (ZIP) file.
  Future<void> bundleWorkflow({
    required File workflowFile,
    required List<File> assets,
    required String outputPath,
  }) async {
    try {
      AppLogger.info('Bundling workflow to $outputPath', _logCategory);
      final archive = Archive();
      
      // Add workflow JSON
      final workflowBytes = await workflowFile.readAsBytes();
      archive.addFile(ArchiveFile('workflow.json', workflowBytes.length, workflowBytes));

      // Add assets into a sub-directory
      for (final asset in assets) {
        if (await asset.exists()) {
          final assetBytes = await asset.readAsBytes();
          // Always use forward slashes for ZIP internal paths
          final archivePath = 'assets/${p.basename(asset.path)}';
          archive.addFile(ArchiveFile(archivePath, assetBytes.length, assetBytes));
          AppLogger.info('Added asset to bundle: $archivePath', _logCategory);
        } else {
          AppLogger.warning('Asset not found, skipping: ${asset.path}', _logCategory);
        }
      }
      
      final zipData = ZipEncoder().encode(archive);
      if (zipData == null) {
        throw Exception('Failed to encode ZIP data');
      }
      
      await File(outputPath).writeAsBytes(zipData);
      AppLogger.info('Successfully bundled workflow with ${archive.files.length} files', _logCategory);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to bundle workflow', e, stackTrace, _logCategory);
      rethrow;
    }
  }

  /// Extracts a .macaque (ZIP) file to the specified isolated directory.
  Future<void> extractWorkflow({
    required File archiveFile,
    required String destinationPath,
  }) async {
    try {
      AppLogger.info('Extracting archive ${archiveFile.path} to $destinationPath', _logCategory);
      final bytes = await archiveFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      for (final file in archive) {
        final filename = file.name;
        if (file.isFile) {
          final data = file.content as List<int>;
          final outFile = File(p.join(destinationPath, filename));
          await outFile.create(recursive: true);
          await outFile.writeAsBytes(data);
          AppLogger.info('Extracted file: $filename', _logCategory);
        } else {
          await Directory(p.join(destinationPath, filename)).create(recursive: true);
          AppLogger.info('Created directory: $filename', _logCategory);
        }
      }
      AppLogger.info('Successfully extracted ${archive.files.length} files', _logCategory);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to extract workflow', e, stackTrace, _logCategory);
      rethrow;
    }
  }

  /// Deletes an isolated asset store directory.
  Future<void> deleteIsolatedStore(String path) async {
    try {
      AppLogger.info('Deleting isolated store at $path', _logCategory);
      final dir = Directory(path);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        AppLogger.info('Successfully deleted isolated store', _logCategory);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete isolated store', e, stackTrace, _logCategory);
      rethrow;
    }
  }
}
