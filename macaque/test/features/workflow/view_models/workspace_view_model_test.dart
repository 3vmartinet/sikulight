import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:macaque/features/workflow/view_models/workspace_view_model.dart';
import 'package:macaque/features/workflow/services/workflow_engine.dart';
import 'package:macaque/features/workflow/services/workflow_persistence.dart';
import 'package:macaque/core/api_client.dart';
import 'package:macaque/features/assets/services/asset_storage_service.dart';

import 'package:macaque/features/workflow/services/session_persistence_service.dart';
import 'workspace_view_model_test.mocks.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  @override
  Future<String?> getTemporaryPath() async => '.';
  @override
  Future<String?> getApplicationDocumentsPath() async => '.';
}

@GenerateMocks([
  SessionPersistenceService,
  WorkflowEngine,
  WorkflowPersistence,
  ApiClient,
  AssetStorageService,
])
void main() {
  late WorkspaceViewModel workspaceVM;
  late MockSessionPersistenceService mockSessionService;
  late MockWorkflowEngine mockEngine;
  late MockWorkflowPersistence mockPersistence;
  late MockApiClient mockApiClient;
  late MockAssetStorageService mockAssetStorage;

  setUp(() {
    PathProviderPlatform.instance = MockPathProviderPlatform();

    mockSessionService = MockSessionPersistenceService();
    mockEngine = MockWorkflowEngine();
    mockPersistence = MockWorkflowPersistence();
    mockApiClient = MockApiClient();
    mockAssetStorage = MockAssetStorageService();

    when(mockPersistence.importWorkflow(any)).thenAnswer((_) async => null);
    when(mockPersistence.loadWorkflow(any, any)).thenAnswer((_) async => null);
    when(mockPersistence.getAbsoluteFilePath(any, filePath: anyNamed('filePath')))
        .thenAnswer((invocation) async => invocation.namedArguments[#filePath] ?? 'mock_path');

    workspaceVM = WorkspaceViewModel(
      sessionService: mockSessionService,
      engine: mockEngine,
      persistence: mockPersistence,
      apiClient: mockApiClient,
      assetStorage: mockAssetStorage,
    );
  });

  group('WorkspaceViewModel', () {
    test('openWorkflow should add a new tab if not already open', () async {
      const filePath = '/path/to/workflow.macaque';

      await workspaceVM.openWorkflow(filePath);

      expect(workspaceVM.tabs.length, 1);
      expect(workspaceVM.tabs.first.filePath, filePath);
      expect(workspaceVM.activeTabIndex, 0);
    });

    test('openWorkflow should focus existing tab if already open', () async {
      const filePath = '/path/to/workflow.macaque';
      await workspaceVM.openWorkflow(filePath);
      await workspaceVM.openWorkflow('/path/to/other.macaque');
      expect(workspaceVM.activeTabIndex, 1);

      await workspaceVM.openWorkflow(filePath);

      expect(workspaceVM.tabs.length, 2);
      expect(workspaceVM.activeTabIndex, 0);
    });

    test(
      'closeTab should remove tab and shift focus to previous active',
      () async {
        await workspaceVM.openWorkflow('/path/1.macaque'); // Index 0
        await workspaceVM.openWorkflow('/path/2.macaque'); // Index 1
        await workspaceVM.openWorkflow('/path/3.macaque'); // Index 2

        workspaceVM.selectTab(0); // Focus 1.macaque
        workspaceVM.selectTab(2); // Focus 3.macaque, previous is 0

        final tabIdToClose = workspaceVM.tabs[2].id;
        await workspaceVM.closeTab(tabIdToClose);

        expect(workspaceVM.tabs.length, 2);
        expect(workspaceVM.tabs.any((t) => t.id == tabIdToClose), isFalse);
        expect(
          workspaceVM.activeTabIndex,
          0,
        ); // Focus should go to previous active
      },
    );

    test('reorderTabs should update tabs list correctly', () async {
      await workspaceVM.openWorkflow('/path/1.macaque');
      await workspaceVM.openWorkflow('/path/2.macaque');

      workspaceVM.reorderTabs(1, 0);

      expect(workspaceVM.tabs[0].filePath, '/path/2.macaque');
      expect(workspaceVM.tabs[1].filePath, '/path/1.macaque');
    });
  });
}
