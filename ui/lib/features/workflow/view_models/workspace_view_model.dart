import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ui/core/api_client.dart';
import 'package:ui/features/assets/services/asset_storage_service.dart';
import 'package:ui/features/workflow/models/workspace_models.dart';
import 'package:ui/features/workflow/services/session_persistence_service.dart';
import 'package:ui/features/workflow/services/workflow_engine.dart';
import 'package:ui/features/workflow/services/workflow_persistence.dart';
import 'package:ui/features/workflow/view_models/workflow_view_model.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;

class WorkspaceViewModel extends ChangeNotifier {
  final SessionPersistenceService _sessionService;
  final WorkflowEngine _engine;
  final WorkflowPersistence _persistence;
  final ApiClient _apiClient;
  final AssetStorageService _assetStorage;

  final List<TabMetadata> _tabs = [];
  int _activeTabIndex = -1;
  final List<int> _focusHistory = [];

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
  TabMetadata? get activeTab => _activeTabIndex >= 0 && _activeTabIndex < _tabs.length ? _tabs[_activeTabIndex] : null;

  Future<void> openWorkflow(String filePath) async {
    // Basic validation
    if (!filePath.startsWith('new://') && 
        !(filePath.endsWith('.swflow') || filePath.endsWith('.json'))) {
      debugPrint('Invalid file type: $filePath');
      return;
    }

    final existingIndex = _tabs.indexWhere((t) => t.filePath == filePath);
    if (existingIndex != -1) {
      selectTab(existingIndex);
      return;
    }

    final workflowVM = WorkflowViewModel(
      engine: _engine,
      persistence: _persistence,
      apiClient: _apiClient,
      assetStorage: _assetStorage,
      initialFilePath: filePath,
    );

    final newTab = TabMetadata(
      id: const Uuid().v4(),
      name: filePath.contains('new://') ? 'New Workflow' : p.basenameWithoutExtension(filePath),
      filePath: filePath,
      viewModel: workflowVM,
    );

    _tabs.add(newTab);
    selectTab(_tabs.length - 1);
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
    if (tab.filePath != null && File(tab.filePath!).existsSync()) {
      await tab.viewModel.saveToFile();
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
    if (session == null) return;

    // Restore tabs (but only active one for now as per Q1: A)
    if (session.activeWorkflowPath != null) {
      final file = File(session.activeWorkflowPath!);
      if (await file.exists()) {
        await openWorkflow(file.path);
      }
    }
    notifyListeners();
  }

  void _saveSession() {
    final session = WorkspaceSession(
      activeWorkflowPath: activeTab?.filePath,
      openFilePaths: _tabs.map((t) => t.filePath).whereType<String>().toList(),
      lastUpdated: DateTime.now(),
    );
    _sessionService.saveSession(session);
  }
}
