import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:sikulite/features/workflow/view_models/workflow_view_model.dart';
import 'package:sikulite/features/workflow/models/workflow_models.dart'
    as models;

// Reuse mocks from workspace_view_model_test
import 'workspace_view_model_test.mocks.dart';

void main() {
  late MockWorkflowEngine mockEngine;
  late MockWorkflowPersistence mockPersistence;
  late MockApiClient mockApiClient;
  late MockAssetStorageService mockAssetStorage;

  setUp(() {
    mockEngine = MockWorkflowEngine();
    mockPersistence = MockWorkflowPersistence();
    mockApiClient = MockApiClient();
    mockAssetStorage = MockAssetStorageService();

    when(mockPersistence.loadDraft(any)).thenAnswer((_) async => null);
    when(mockPersistence.getAbsoluteFilePath(any, filePath: anyNamed('filePath')))
        .thenAnswer((invocation) async => invocation.namedArguments[#filePath] ?? 'mock_path');
    when(mockEngine.variables).thenReturn({});
  });

  test('WorkflowViewModel should extract ID from new:// path', () async {
    WorkflowViewModel(
      engine: mockEngine,
      persistence: mockPersistence,
      apiClient: mockApiClient,
      assetStorage: mockAssetStorage,
      initialFilePath: 'new://workflow/123456',
    );

    // loadDraft is called in constructor
    verify(mockPersistence.loadDraft('123456')).called(1);
  });

  test(
    'WorkflowViewModel should use correct loading sequence to prevent draft overwriting',
    () async {
      // Setup a draft
      final draft = models.Workflow(
        id: '123',
        name: 'Test Draft',
        nodes: [],
        connections: [],
      );
      when(mockPersistence.loadDraft('123')).thenAnswer((_) async => draft);

      WorkflowViewModel(
        engine: mockEngine,
        persistence: mockPersistence,
        apiClient: mockApiClient,
        assetStorage: mockAssetStorage,
        initialFilePath: 'new://workflow/123',
      );

      // Wait for microtasks
      await Future.delayed(Duration.zero);

      // verifyNever saveDraft ensures that the empty graph wasn't auto-saved during loadDraft
      verifyNever(mockPersistence.saveDraft(any));
    },
  );

  test('WorkflowViewModel.exportWorkflow should use workflow name if no target provided', () async {
    final viewModel = WorkflowViewModel(
      engine: mockEngine,
      persistence: mockPersistence,
      apiClient: mockApiClient,
      assetStorage: mockAssetStorage,
    );

    viewModel.renameWorkflow('My Awesome Workflow');

    when(mockPersistence.getExportFile(fileName: anyNamed('fileName')))
        .thenAnswer((_) async => File('dummy.swflow'));

    await viewModel.exportWorkflow();

    verify(mockPersistence.getExportFile(fileName: 'My Awesome Workflow.swflow')).called(1);
  });
}
