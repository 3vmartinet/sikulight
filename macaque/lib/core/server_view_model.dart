import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import 'package:macaque/core/api_client.dart';
import 'package:macaque/core/logger.dart';

enum ServerStatus {
  starting,
  started,
  failedToStart,
  stopped,
}

class ServerViewModel extends ChangeNotifier {
  final ApiClient _apiClient;
  final Future<String?> Function()? _pythonFinder;
  ServerStatus _status = ServerStatus.stopped;
  Process? _process;

  ServerViewModel({
    required ApiClient apiClient,
    Future<String?> Function()? pythonFinder,
  }) : _apiClient = apiClient,
       _pythonFinder = pythonFinder {
    startServer();
  }

  ServerStatus get status => _status;

  Future<void> startServer() async {
    if (_status == ServerStatus.starting || _status == ServerStatus.started) {
      return;
    }

    _status = ServerStatus.starting;
    notifyListeners();

    // 1. Check if server is already running
    final isAlreadyRunning = await _isServerResponding();
    if (isAlreadyRunning) {
      AppLogger.info('Server is already responding on port 8000. Adopting it.', 'PythonServer');
      _status = ServerStatus.started;
      notifyListeners();
      return;
    }

    // 2. Locate Python executable
    final pythonPath = await _findPythonExecutable();
    if (pythonPath == null) {
      AppLogger.error('Failed to locate Python executable with required dependencies.', null, null, 'PythonServer');
      _status = ServerStatus.failedToStart;
      notifyListeners();
      return;
    }

    AppLogger.info('Using Python executable: $pythonPath', 'PythonServer');

    // 3. Resolve directory and script paths
    final currentDir = Directory.current;
    String projectRootPath;
    String scriptPath;

    if (Directory(p.join(currentDir.path, 'engine')).existsSync()) {
      projectRootPath = currentDir.path;
      scriptPath = p.join('engine', 'src', 'api', 'app.py');
    } else if (Directory(p.join(currentDir.parent.path, 'engine')).existsSync()) {
      projectRootPath = currentDir.parent.path;
      scriptPath = p.join('engine', 'src', 'api', 'app.py');
    } else {
      projectRootPath = currentDir.path;
      scriptPath = p.join('engine', 'src', 'api', 'app.py');
    }

    final fullScriptPath = p.join(projectRootPath, scriptPath);
    AppLogger.info('Starting python server at $fullScriptPath', 'PythonServer');

    try {
      _process = await Process.start(
        pythonPath,
        [scriptPath],
        workingDirectory: projectRootPath,
        environment: {
          'PYTHONPATH': projectRootPath,
        },
      );

      // Listen to stdout
      _process!.stdout.transform(utf8.decoder).listen((data) {
        AppLogger.info(data.trim(), 'PythonServer');
      });

      // Listen to stderr
      _process!.stderr.transform(utf8.decoder).listen((data) {
        AppLogger.info('STDERR: ${data.trim()}', 'PythonServer');
      });

      // Handle premature process termination
      _process!.exitCode.then((exitCode) {
        AppLogger.info('Python process exited with code $exitCode', 'PythonServer');
        _process = null;
        if (_status == ServerStatus.starting || _status == ServerStatus.started) {
          _status = ServerStatus.stopped;
          notifyListeners();
        }
      });

      // 4. Probe port 8000
      final started = await _probePort(15); // Wait up to 15 seconds
      if (started) {
        _status = ServerStatus.started;
      } else {
        AppLogger.error('Failed to connect to Python server after timeout.', null, null, 'PythonServer');
        _status = ServerStatus.failedToStart;
        await stopServer();
      }
      notifyListeners();
    } catch (e, stackTrace) {
      AppLogger.error('Exception while starting python server', e, stackTrace, 'PythonServer');
      _status = ServerStatus.failedToStart;
      _process = null;
      notifyListeners();
    }
  }

  Future<void> stopServer() async {
    if (_process != null) {
      AppLogger.info('Stopping python server...', 'PythonServer');
      _process!.kill();
      _process = null;
    }
    _status = ServerStatus.stopped;
    notifyListeners();
  }

  Future<bool> _isServerResponding() async {
    try {
      final response = await _apiClient.getStatus();
      return response.containsKey('status') || response.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _probePort(int maxAttempts) async {
    for (int i = 0; i < maxAttempts; i++) {
      if (_process == null) return false;
      final responding = await _isServerResponding();
      if (responding) return true;
      await Future.delayed(const Duration(milliseconds: 1000));
    }
    return false;
  }

  Future<String?> _findPythonExecutable() async {
    if (_pythonFinder != null) {
      return _pythonFinder!();
    }

    // 1. Check SharedPreferences for user-defined python path
    try {
      final prefs = await SharedPreferences.getInstance();
      final customPath = prefs.getString('custom_python_path');
      if (customPath != null && customPath.isNotEmpty) {
        if (await _verifyPython(customPath)) {
          return customPath;
        }
      }
    } catch (e) {
      AppLogger.warning('Failed to load custom python path from SharedPreferences: $e', 'PythonServer');
    }

    // 2. Check candidate list
    final candidates = [
      '/Users/valentin.martinet/dev/py/bin/python',
      'python3',
      'python',
      '../.venv/bin/python',
      '../venv/bin/python',
      '../../.venv/bin/python',
      '../../venv/bin/python',
    ];

    for (final candidate in candidates) {
      if (await _verifyPython(candidate)) {
        return candidate;
      }
    }

    return null;
  }

  Future<bool> _verifyPython(String path) async {
    try {
      final result = await Process.run(path, ['-c', 'import fastapi; import uvicorn']);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    stopServer();
    super.dispose();
  }
}
