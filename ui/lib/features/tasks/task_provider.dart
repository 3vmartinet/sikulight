import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ui/core/api_client.dart';
import 'package:ui/features/tasks/task_command.dart';
import 'package:ui/features/workflow/models/execution_result.dart';
import 'dart:convert';

class TaskProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  bool _isBusy = false;
  Map<String, dynamic>? _engineStatus;
  List<TaskCommand> _persistedCommands = [];

  bool get isBusy => _isBusy;
  Map<String, dynamic>? get engineStatus => _engineStatus;
  List<TaskCommand> get persistedCommands => _persistedCommands;

  TaskProvider() {
    _loadPersistedCommands();
  }

  Future<void> _loadPersistedCommands() async {
    final prefs = await SharedPreferences.getInstance();
    final commandsString = prefs.getString('persisted_commands') ?? '[]';
    final List<dynamic> decoded = json.decode(commandsString);
    _persistedCommands = decoded
        .cast<Map<String, dynamic>>()
        .map(TaskCommand.fromJson)
        .toList();
    notifyListeners();
  }

  Future<void> saveCommand(TaskCommand command, {TaskCommand? oldCommand}) async {
    final newList = List<TaskCommand>.from(_persistedCommands);
    if (oldCommand != null) {
      final index = newList.indexOf(oldCommand);
      if (index != -1) {
        newList[index] = command;
      } else {
        if (!newList.contains(command)) newList.add(command);
      }
    } else {
      if (!newList.contains(command)) {
        newList.add(command);
      }
    }
    _persistedCommands = newList;
    await _persistCommands();
  }

  Future<void> deleteCommand(TaskCommand command) async {
    final newList = List<TaskCommand>.from(_persistedCommands);
    newList.remove(command);
    _persistedCommands = newList;
    await _persistCommands();
  }

  Future<void> _persistCommands() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'persisted_commands',
      json.encode(_persistedCommands.map((e) => e.toJson()).toList()),
    );
    notifyListeners();
  }

  Future<void> fetchStatus() async {
    try {
      _engineStatus = await _apiClient.getStatus();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching status: $e');
    }
  }

  Future<ExecutionResult> runTask(TaskCommand task) async {
    _isBusy = true;
    notifyListeners();

    try {
      final result = await _apiClient.executeTask(task);
      return result;
    } finally {
      _isBusy = false;
      notifyListeners();
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
