import 'package:flutter_test/flutter_test.dart';
import 'package:ui/core/utils/isolate_processor_service.dart';

void main() {
  group('IsolateProcessorService', () {
    final service = IsolateProcessorService();

    test('run executes computation in separate isolate', () async {
      final result = await service.run(() => 1 + 1);
      expect(result, 2);
    });

    test('computeTask handles static callback', () async {
      final result = await IsolateProcessorService.computeTask((_) => 'success');
      expect(result, 'success');
    });
  });
}
