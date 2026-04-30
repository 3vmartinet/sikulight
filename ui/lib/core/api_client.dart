import 'dart:convert';
import 'package:http/http.dart' as http;

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

  Future<Map<String, dynamic>> executeTask(Map<String, dynamic> task) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/execute'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(task),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to execute task: ${response.body}');
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
}
