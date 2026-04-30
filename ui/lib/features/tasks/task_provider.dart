import 'package:flutter/material.dart';
import 'package:ui/core/api_client.dart';

class TaskProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  
  bool _isBusy = false;
  Map<String, dynamic>? _engineStatus;

  bool get isBusy => _isBusy;
  Map<String, dynamic>? get engineStatus => _engineStatus;

  Future<void> fetchStatus() async {
    try {
      _engineStatus = await _apiClient.getStatus();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching status: $e');
    }
  }

  Future<Map<String, dynamic>> runTask(Map<String, dynamic> task) async {
    _isBusy = true;
    notifyListeners();
    
    try {
      final result = await _apiClient.executeTask(task);
      return result;
    } finally {
      _isBusy = false;
      notifyListeners();
      // Fetch status after execution to update IDLE/BUSY state
      await fetchStatus();
    }
  }

  Future<void> abort() async {
    try {
      await _apiClient.abortTask();
      await fetchStatus();
    } catch (e) {
      debugPrint('Error aborting task: $e');
    }
  }
}
