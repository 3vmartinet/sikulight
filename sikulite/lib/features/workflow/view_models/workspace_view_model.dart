import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sikulite/core/api_client.dart';
import 'package:sikulite/features/assets/services/asset_storage_service.dart';
import 'package:sikulite/features/workflow/models/workspace_models.dart';
import 'package:sikulite/features/workflow/services/session_persistence_service.dart';
import 'package:sikulite/features/workflow/services/workflow_engine.dart';
import 'package:sikulite/features/workflow/services/workflow_persistence.dart';
import 'package:sikulite/features/workflow/services/archive_service.dart';
import 'package:sikulite/features/workflow/view_models/workflow_view_model.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class WorkspaceViewModel extends ChangeNotifier {
  final SessionPersistenceService _sessionService;
  final WorkflowEngine _engine;
  final WorkflowPersistence _persistence;
  final ApiClient _apiClient;
  final AssetStorageService _assetStorage;
  final ArchiveService _archiveService = ArchiveService();

  final List<TabMetadata> _tabs = [];
  int _activeTabIndex = -1;
  final List<int> _focusHistory = [];
  final List<String> _recentFilePaths = [];

  WorkspaceViewModel({
    required SessionPersistenceService sessionService,
    required WorkflowEngine engine,
    required WorkflowPersistence persistence,
    required ApiClient apiClient,
    required AssetStorageService assetStorage,
  }) : _sessionService = sessionService,
       _engine = engine,
       _persistence = persistence,
       _apiClient = apiClient,
       _assetStorage = assetStorage;

  List<TabMetadata> get tabs => List.unmodifiable(_tabs);
  int get activeTabIndex => _activeTabIndex;
  TabMetadata? get activeTab =>
      _activeTabIndex >= 0 && _activeTabIndex < _tabs.length
      ? _tabs[_activeTabIndex]
      : null;
  List<String> get recentFilePaths => List.unmodifiable(_recentFilePaths);

  Future<void> openWorkflow(String filePath) async {
    // Explicitly block internal configuration files
    if (filePath.endsWith('session_history.json')) {
      debugPrint('Blocked attempt to open internal config: $filePath');
      return;
    }

    // Basic validation
    final ext = p.extension(filePath).toLowerCase();
    if (!filePath.startsWith('new://') &&
        !(ext == '.swflow' || ext == '.json' || ext == '.macaque')) {
      debugPrint('Invalid file type: $filePath');
      return;
    }

    final existingIndex = _tabs.indexWhere((t) => t.filePath == filePath);
    if (existingIndex != -1) {
      selectTab(existingIndex);
      return;
    }

    final isNewWorkflow = filePath.startsWith('new://');
    final workflowVM = WorkflowViewModel(
      engine: _engine,
      persistence: _persistence,
      apiClient: _apiClient,
      assetStorage: _assetStorage,
      initialFilePath: filePath,
    );

    final newTab = TabMetadata(
      id: const Uuid().v4(),
      name: isNewWorkflow
          ? 'New Workflow'
          : p.basenameWithoutExtension(filePath),
      filePath: filePath,
      viewModel: workflowVM,
    );

    _tabs.add(newTab);
    debugPrint('Added tab: $filePath. Total tabs: ${_tabs.length}');
    selectTab(_tabs.length - 1);

    // Track as recent if it's a real file
    if (!isNewWorkflow) {
      _recentFilePaths.remove(filePath);
      _recentFilePaths.insert(0, filePath);
      if (_recentFilePaths.length > 10) {
        _recentFilePaths.removeLast();
      }
    }

    // Sync name if it's already loaded or when it loads
    if (workflowVM.workflowName != 'New Workflow') {
      final index = _tabs.indexOf(newTab);
      if (index != -1) {
        _tabs[index] = newTab.copyWith(name: workflowVM.workflowName);
        notifyListeners();
      }
    }

    // Listen for name changes in the VM to keep TabMetadata in sync
    workflowVM.addListener(() {
      final index = _tabs.indexWhere((t) => t.id == newTab.id);
      if (index != -1 && _tabs[index].name != workflowVM.workflowName) {
        _tabs[index] = _tabs[index].copyWith(name: workflowVM.workflowName);
        notifyListeners();
      }
    });

    _saveSession();
  }

  void selectTab(int index) {
    if (index < 0 || index >= _tabs.length) return;
    if (_activeTabIndex != -1) {
      _focusHistory.remove(_activeTabIndex);
      _focusHistory.add(_activeTabIndex);
    }
    _activeTabIndex = index;
    notifyListeners();
    _saveSession();
  }

  Future<void> closeTab(String id) async {
    final index = _tabs.indexWhere((t) => t.id == id);
    if (index == -1) return;

    final tab = _tabs[index];
    // FR-008: Auto-save on close (only if it has a file path)
    if (tab.filePath != null &&
        !tab.filePath!.startsWith('new://') &&
        File(tab.filePath!).existsSync()) {
      await tab.viewModel.saveToFile();
    }

    // Cleanup isolated assets for this tab (US3)
    final isolatedPath = tab.viewModel.isolatedAssetPath;
    if (isolatedPath != null) {
      // isolatedPath is usually .../assets, we want the parent which is the workflowId folder
      final workflowStoreRoot = p.dirname(isolatedPath);
      await _archiveService.deleteIsolatedStore(workflowStoreRoot);
    }

    _tabs.removeAt(index);
    _focusHistory.remove(index);

    // Adjust focus history indices
    for (int i = 0; i < _focusHistory.length; i++) {
      if (_focusHistory[i] > index) {
        _focusHistory[i]--;
      }
    }

    if (_tabs.isEmpty) {
      _activeTabIndex = -1;
    } else if (_activeTabIndex == index) {
      if (_focusHistory.isNotEmpty) {
        _activeTabIndex = _focusHistory.removeLast();
      } else {
        _activeTabIndex = index < _tabs.length ? index : _tabs.length - 1;
      }
    } else if (_activeTabIndex > index) {
      _activeTabIndex--;
    }

    notifyListeners();
    _saveSession();
  }

  void renameWorkflow(String id, String newName) {
    final index = _tabs.indexWhere((t) => t.id == id);
    if (index == -1) return;

    final tab = _tabs[index];
    tab.viewModel.renameWorkflow(newName);

    // Update the tab metadata with the new name
    _tabs[index] = tab.copyWith(name: newName);

    notifyListeners();
    _saveSession();
  }

  void removeRecentFile(String path) {
    _recentFilePaths.remove(path);
    notifyListeners();
    _saveSession();
  }

  void reorderTabs(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    if (oldIndex == newIndex) return;

    final TabMetadata item = _tabs.removeAt(oldIndex);
    _tabs.insert(newIndex, item);

    // Update active index if it moved
    if (_activeTabIndex == oldIndex) {
      _activeTabIndex = newIndex;
    } else if (_activeTabIndex > oldIndex && _activeTabIndex <= newIndex) {
      _activeTabIndex--;
    } else if (_activeTabIndex < oldIndex && _activeTabIndex >= newIndex) {
      _activeTabIndex++;
    }

    notifyListeners();
    _saveSession();
  }

  Future<void> restoreSession() async {
    final session = await _sessionService.loadSession();
    if (session == null) {
      debugPrint('No session found to restore.');
      await _cleanupOrphanedIsolatedStores([]);
      return;
    }

    debugPrint('Restoring session. Open paths: ${session.openFilePaths}');

    // Restore recent files list
    _recentFilePaths.clear();
    _recentFilePaths.addAll(session.recentFilePaths);

    // Restore all tabs (FR-013)
    for (final path in session.openFilePaths) {
      if (path.startsWith('new://')) {
        debugPrint('Restoring new workflow: $path');
        await openWorkflow(path);
      } else {
        final file = File(path);
        if (await file.exists()) {
          debugPrint('Restoring workflow file: $path');
          await openWorkflow(path);
        } else {
          debugPrint('Failed to restore workflow file: $path (file not found)');
        }
      }
    }

    // Restore active focus
    if (session.activeWorkflowPath != null) {
      final index = _tabs.indexWhere(
        (t) => t.filePath == session.activeWorkflowPath,
      );
      if (index != -1) {
        selectTab(index);
      }
    }

    // US3: Selective startup cleanup
    final activeWorkflowIds = _tabs.map((t) => t.viewModel.currentWorkflow.id).toList();
    await _cleanupOrphanedIsolatedStores(activeWorkflowIds);

    notifyListeners();
  }

  Future<void> _cleanupOrphanedIsolatedStores(List<String> activeIds) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final importsDir = Directory(p.join(tempDir.path, 'sikulite_imports'));
      if (!await importsDir.exists()) return;

      final entities = importsDir.listSync();
      for (final entity in entities) {
        if (entity is Directory) {
          final id = p.basename(entity.path);
          if (!activeIds.contains(id)) {
            debugPrint('Cleaning up orphaned isolated store: $id');
            await _archiveService.deleteIsolatedStore(entity.path);
          }
        }
      }
    } catch (e) {
      debugPrint('Error during startup cleanup: $e');
    }
  }

  void saveSession() {
    _saveSession();
  }

  void _saveSession() {
    final activePath = activeTab?.filePath;
    final paths = _tabs.map((t) => t.filePath).whereType<String>().toList();
    debugPrint(
      'Saving session with activePath: $activePath, openPaths: $paths',
    );
    final session = WorkspaceSession(
      activeWorkflowPath: activePath,
      openFilePaths: paths,
      recentFilePaths: _recentFilePaths,
      lastUpdated: DateTime.now(),
    );
    _sessionService.saveSession(session);
  }
}
