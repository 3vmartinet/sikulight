import 'package:flutter/foundation.dart';

class AppLogger {
  static void info(String message, [String? category]) {
    final prefix = category != null ? '[$category] ' : '';
    debugPrint('$prefix$message');
  }

  static void error(String message, [Object? error, StackTrace? stackTrace, String? category]) {
    final prefix = category != null ? '[$category] ' : '';
    debugPrint('$prefix ERROR: $message');
    if (error != null) {
      debugPrint('$prefix DETAIL: $error');
    }
    if (stackTrace != null) {
      debugPrint('$prefix STACKTRACE:\n$stackTrace');
    }
  }

  static void warning(String message, [String? category]) {
    final prefix = category != null ? '[$category] ' : '';
    debugPrint('$prefix WARNING: $message');
  }
}
