import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:sikulite/features/workflow/view_models/workspace_view_model.dart';
import 'package:sikulite/features/workflow/services/workflow_engine.dart';
import 'package:sikulite/features/workflow/services/workflow_persistence.dart';
import 'package:sikulite/core/api_client.dart';
import 'package:sikulite/features/assets/services/asset_storage_service.dart';

import 'package:sikulite/features/workflow/services/session_persistence_service.dart';
import 'workspace_view_model_test.mocks.dart';

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
    mockSessionService = MockSessionPersistenceService();
    mockEngine = MockWorkflowEngine();
    mockPersistence = MockWorkflowPersistence();
    mockApiClient = MockApiClient();
    mockAssetStorage = MockAssetStorageService();

    when(mockPersistence.importWorkflow(any)).thenAnswer((_) async => null);
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
      const filePath = '/path/to/workflow.swflow';

      await workspaceVM.openWorkflow(filePath);

      expect(workspaceVM.tabs.length, 1);
      expect(workspaceVM.tabs.first.filePath, filePath);
      expect(workspaceVM.activeTabIndex, 0);
    });

    test('openWorkflow should focus existing tab if already open', () async {
      const filePath = '/path/to/workflow.swflow';
      await workspaceVM.openWorkflow(filePath);
      await workspaceVM.openWorkflow('/path/to/other.swflow');
      expect(workspaceVM.activeTabIndex, 1);

      await workspaceVM.openWorkflow(filePath);

      expect(workspaceVM.tabs.length, 2);
      expect(workspaceVM.activeTabIndex, 0);
    });

    test(
      'closeTab should remove tab and shift focus to previous active',
      () async {
        await workspaceVM.openWorkflow('/path/1.swflow'); // Index 0
        await workspaceVM.openWorkflow('/path/2.swflow'); // Index 1
        await workspaceVM.openWorkflow('/path/3.swflow'); // Index 2

        workspaceVM.selectTab(0); // Focus 1.swflow
        workspaceVM.selectTab(2); // Focus 3.swflow, previous is 0

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
      await workspaceVM.openWorkflow('/path/1.swflow');
      await workspaceVM.openWorkflow('/path/2.swflow');

      workspaceVM.reorderTabs(1, 0);

      expect(workspaceVM.tabs[0].filePath, '/path/2.swflow');
      expect(workspaceVM.tabs[1].filePath, '/path/1.swflow');
    });
  });
}
