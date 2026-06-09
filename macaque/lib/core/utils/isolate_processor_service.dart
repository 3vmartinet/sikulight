import 'dart:isolate';
import 'package:flutter/foundation.dart';

/// A service that offloads heavy computations to a separate Isolate.
/// 
/// This ensures that the UI thread remains responsive for smooth transitions.
class IsolateProcessorService {
  /// Runs the provided [computation] in a separate isolate.
  /// 
  /// Wraps [Isolate.run] for simple one-off heavy tasks.
  Future<T> run<T>(T Function() computation) async {
    return await Isolate.run<T>(computation);
  }

  /// Specialized method for computing something that needs to be passed back
  /// from an isolate, providing a standard way to handle heavy tasks.
  static Future<T> computeTask<T>(ComputeCallback<void, T> callback) async {
    return await compute(callback, null);
  }
}
