import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:macaque/core/server_view_model.dart';
import '../features/workflow/workflow_engine_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  late MockApiClient mockApiClient;

  setUp(() {
    mockApiClient = MockApiClient();
  });

  test('ServerViewModel starts and adopts already running server', () async {
    // Mock getStatus to return a successful response (simulating running server)
    when(mockApiClient.getStatus()).thenAnswer(
      (_) async => {'status': 'ok'},
    );

    final viewModel = ServerViewModel(apiClient: mockApiClient);

    // Wait a brief moment for the async startServer call to run
    await Future.delayed(const Duration(milliseconds: 100));

    expect(viewModel.status, ServerStatus.started);
    verify(mockApiClient.getStatus()).called(1);

    await viewModel.stopServer();
    expect(viewModel.status, ServerStatus.stopped);
  });

  test('ServerViewModel transitions to failedToStart when no python found and no running server', () async {
    // Mock getStatus to throw an error (simulating server not running)
    when(mockApiClient.getStatus()).thenThrow(
      Exception('Connection refused'),
    );

    final viewModel = ServerViewModel(
      apiClient: mockApiClient,
      pythonFinder: () async => null,
    );

    // Wait for the async startServer probe process to complete (failedToStart status expected)
    await Future.delayed(const Duration(milliseconds: 500));

    expect(viewModel.status, ServerStatus.failedToStart);
  });
}
