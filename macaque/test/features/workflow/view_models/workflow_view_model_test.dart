import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:macaque/features/workflow/view_models/workflow_view_model.dart';
import 'package:macaque/features/workflow/models/workflow_models.dart'
    as models;
import 'package:vyuh_node_flow/vyuh_node_flow.dart' as vnf;
import 'package:flutter/painting.dart';

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
    when(mockPersistence.getExportFile(fileName: anyNamed('fileName')))
        .thenAnswer((_) async => File('dummy.macaque'));
    when(mockAssetStorage.loadAssets()).thenAnswer((_) async => []);
    when(mockPersistence.saveWorkflow(
      workflow: anyNamed('workflow'),
      assets: anyNamed('assets'),
      targetFile: anyNamed('targetFile'),
    )).thenAnswer((_) async {});

    final viewModel = WorkflowViewModel(
      engine: mockEngine,
      persistence: mockPersistence,
      apiClient: mockApiClient,
      assetStorage: mockAssetStorage,
    );

    viewModel.renameWorkflow('My Awesome Workflow');

    await viewModel.exportWorkflow();

    verify(mockPersistence.getExportFile(fileName: 'My Awesome Workflow.macaque')).called(1);
  });

  test('WorkflowViewModel should prevent deletion of StartNode but allow others', () async {
    final viewModel = WorkflowViewModel(
      engine: mockEngine,
      persistence: mockPersistence,
      apiClient: mockApiClient,
      assetStorage: mockAssetStorage,
    );

    final onBeforeDelete = viewModel.controller.events.node?.onBeforeDelete;
    expect(onBeforeDelete, isNotNull);

    final startNode = vnf.Node<models.NodeData>(
      id: 'start',
      type: 'start',
      position: Offset.zero,
      data: models.StartNode(id: 'start', position: Offset.zero),
    );
    final preventDelete = await onBeforeDelete!(startNode);
    expect(preventDelete, isFalse);

    final waitNode = vnf.Node<models.NodeData>(
      id: 'wait',
      type: 'wait',
      position: Offset.zero,
      data: models.WaitNode(id: 'wait', position: Offset.zero, durationSeconds: 5),
    );
    final allowDelete = await onBeforeDelete(waitNode);
    expect(allowDelete, isTrue);
  });
}
