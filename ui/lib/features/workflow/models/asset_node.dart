import 'package:ui/features/tasks/task_command.dart';

// Initial structure for AssetNode to hold state
class AssetNode {
  final String id;
  final String assetId;
  final StandardAction action;
  final bool ignoreError;

  const AssetNode({
    required this.id,
    required this.assetId,
    this.action = StandardAction.click,
    this.ignoreError = false,
  });
}
