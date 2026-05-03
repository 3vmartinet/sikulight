import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ui/features/tasks/task_command.dart';
import 'package:ui/features/workflow/models/execution_result.dart';

class ApiClient {
  final String baseUrl;
  final http.Client _client;

  ApiClient({this.baseUrl = 'http://127.0.0.1:8000', http.Client? client})
    : _client = client ?? http.Client();

  Future<Map<String, dynamic>> getStatus() async {
    final response = await _client.get(Uri.parse('$baseUrl/status'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load status');
    }
  }

  Future<ExecutionResult> executeTask(TaskCommand task) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/execute'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(task.toJson()),
    );
    if (response.statusCode == 200) {
      return ExecutionResult.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to execute task: ${response.body}');
    }
  }

  Future<ExecutionResult> checkTask(TaskCommand task) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/check'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(task.toJson()),
    );
    if (response.statusCode == 200) {
      return ExecutionResult.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to check task: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> abortTask() async {
    final response = await _client.post(Uri.parse('$baseUrl/abort'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to abort task');
    }
  }

  Future<Map<String, dynamic>> getCursorPosition() async {
    final response = await _client.get(Uri.parse('$baseUrl/cursor-position'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to get cursor position');
    }
  }
}
