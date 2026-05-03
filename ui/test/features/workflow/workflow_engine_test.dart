import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ui/core/api_client.dart';
import 'package:ui/features/tasks/task_command.dart';
import 'package:ui/features/workflow/models/workflow_models.dart';
import 'package:ui/features/workflow/services/workflow_engine.dart';
import 'package:ui/features/workflow/models/execution_result.dart';

import 'workflow_engine_test.mocks.dart';

@GenerateMocks([ApiClient])
void main() {
  late WorkflowEngine engine;
  late MockApiClient mockApiClient;

  setUp(() {
    mockApiClient = MockApiClient();
    engine = WorkflowEngine(apiClient: mockApiClient);
  });

  test('WorkflowEngine executes sequential actions', () async {
    final command = const TaskCommand(
      name: 'Test Task',
      referenceImagePath: 'path/to/image.png',
      profile: TaskProfile(
        mode: 'STANDARD',
        standardAction: 'CLICK',
        confidenceThreshold: 0.8,
        timeoutSeconds: 30,
      ),
    );

    final startNode = StartNode(id: 'start', position: Offset.zero);
    final actionNode = VdaActionNode(id: 'action', position: Offset.zero, command: command);
    final endNode = EndNode(id: 'end', position: Offset.zero);

    final workflow = Workflow(
      id: 'wf1',
      name: 'Test Workflow',
      nodes: [startNode, actionNode, endNode],
      connections: [
        const ConnectionData(sourceNodeId: 'start', sourcePortId: 'out', targetNodeId: 'action', targetPortId: 'in'),
        const ConnectionData(sourceNodeId: 'action', sourcePortId: 'out', targetNodeId: 'end', targetPortId: 'in'),
      ],
    );

    when(mockApiClient.executeTask(any)).thenAnswer((_) async => const ExecutionResult(
      success: true,
      message: 'Success',
      executionDetails: ExecutionDetails(mode: 'standard', exitCode: 0, stdout: '', stderr: ''),
    ));

    await engine.run(workflow);

    verify(mockApiClient.executeTask(command)).called(1);
    expect(engine.status, WorkflowStatus.completed);
    expect(engine.nodeExecutionCounts['action'], 1);
  });
}
