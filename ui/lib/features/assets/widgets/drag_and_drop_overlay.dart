import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui/features/assets/view_models/asset_view_model.dart';
import 'package:ui/features/assets/widgets/duplicate_dialog.dart';

class DragAndDropOverlay extends StatefulWidget {
  final Widget child;

  const DragAndDropOverlay({super.key, required this.child});

  @override
  State<DragAndDropOverlay> createState() => _DragAndDropOverlayState();
}

class _DragAndDropOverlayState extends State<DragAndDropOverlay> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragDone: (detail) async {
        final paths = detail.files.map((f) => f.path).toList();
        if (!mounted) return;
        
        await context.read<AssetViewModel>().importAssets(
          paths,
          onDuplicate: (filename) async {
            return await showDialog<DuplicateResolution>(
              context: context,
              builder: (context) => DuplicateDialog(filename: filename),
            );
          },
        );
        
        if (mounted) {
          setState(() => _isDragging = false);
        }
      },
      onDragEntered: (detail) {
        setState(() => _isDragging = true);
      },
      onDragExited: (detail) {
        setState(() => _isDragging = false);
      },
      child: Stack(
        children: [
          widget.child,
          if (_isDragging)
            Container(
              color: Colors.blue.withValues(alpha: 0.3),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.file_download, size: 64, color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Drop images here to import',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
