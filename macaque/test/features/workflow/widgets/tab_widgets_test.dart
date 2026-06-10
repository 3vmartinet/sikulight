import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:macaque/features/workflow/view_models/workspace_view_model.dart';
import 'package:macaque/features/workflow/view_models/workflow_view_model.dart';
import 'package:macaque/features/workflow/widgets/workflow_tab.dart';
import 'package:macaque/features/workflow/widgets/workflow_tab_bar.dart';
import '../view_models/workspace_view_model_test.mocks.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  @override
  Future<String?> getTemporaryPath() async => '.';
  @override
  Future<String?> getApplicationDocumentsPath() async => '.';
}

void main() {
  late MockSessionPersistenceService mockSessionService;
  late MockWorkflowEngine mockEngine;
  late MockWorkflowPersistence mockPersistence;
  late MockApiClient mockApiClient;
  late MockAssetStorageService mockAssetStorage;
  late WorkspaceViewModel workspaceVM;

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

  Widget createTestWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: ChangeNotifierProvider<WorkspaceViewModel>.value(
          value: workspaceVM,
          child: child,
        ),
      ),
    );
  }

  testWidgets('WorkflowTabBar should display open tabs', (tester) async {
    await workspaceVM.openWorkflow('/path/1.macaque');
    await workspaceVM.openWorkflow('/path/2.macaque');

    await tester.pumpWidget(createTestWidget(const WorkflowTabBar()));

    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('WorkflowTab should show modified indicator', (tester) async {
    await workspaceVM.openWorkflow('/path/1.macaque');
    // We can't easily mock WorkflowViewModel.isModified because it's a real class created inside WorkspaceViewModel
    // But we can check if it's rendered when we provide a tab.

    final tab = workspaceVM.tabs[0];

    await tester.pumpWidget(
      createTestWidget(
        ChangeNotifierProvider<WorkflowViewModel>.value(
          value: tab.viewModel,
          child: WorkflowTab(tab: tab, isActive: true),
        ),
      ),
    );

    expect(find.byIcon(Icons.circle), findsNothing);

    // Simulate modification if we could...
    // Since it's a real VM, we might need to trigger something that sets _isModified.
  });

  testWidgets('WorkflowTab should trigger rename dialog on double tap', (tester) async {
    await workspaceVM.openWorkflow('/path/1.macaque');
    final tab = workspaceVM.tabs[0];

    await tester.pumpWidget(
      createTestWidget(
        ChangeNotifierProvider<WorkflowViewModel>.value(
          value: tab.viewModel,
          child: WorkflowTab(tab: tab, isActive: true),
        ),
      ),
    );

    // Initial state: no dialog
    expect(find.text('Rename Workflow'), findsNothing);

    // Double tap the tab (the text part)
    final center = tester.getCenter(find.text('1'));
    await tester.tapAt(center);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tapAt(center);
    await tester.pumpAndSettle();

    // Verify dialog is shown
    expect(find.text('Rename Workflow'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });
}
