import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui/features/assets/models/asset.dart';
import 'package:ui/features/assets/view_models/asset_view_model.dart';

class AssetItemTile extends StatefulWidget {
  final Asset asset;
  final bool isGridView;

  const AssetItemTile({
    super.key,
    required this.asset,
    this.isGridView = false,
  });

  @override
  State<AssetItemTile> createState() => _AssetItemTileState();
}

class _AssetItemTileState extends State<AssetItemTile> {
  bool _isEditing = false;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.asset.filename);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submitRename() {
    if (_controller.text.isNotEmpty &&
        _controller.text != widget.asset.filename) {
      context.read<AssetViewModel>().renameAsset(
        widget.asset,
        _controller.text,
      );
    }
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    final tile = widget.isGridView
        ? _buildGridItem(context)
        : _buildListItem(context);

    return Draggable<Asset>(
      data: widget.asset,
      feedback: Material(
        elevation: 4,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 200),
          child: tile,
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.5, child: tile),
      child: tile,
    );
  }

  Widget _buildListItem(BuildContext context) {
    return ListTile(
      leading: _Thumbnail(asset: widget.asset),
      title: _isEditing
          ? TextField(
              controller: _controller,
              autofocus: true,
              onSubmitted: (_) => _submitRename(),
              decoration: const InputDecoration(isDense: true),
            )
          : Text(
              widget.asset.filename,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'rename') {
            setState(() => _isEditing = true);
          } else if (value == 'delete') {
            _confirmDelete(context);
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'rename', child: Text('Rename')),
          const PopupMenuItem(value: 'delete', child: Text('Delete')),
        ],
      ),
      subtitle: widget.asset.status == AssetStatus.missing
          ? const Text('Missing', style: TextStyle(color: Colors.red))
          : null,
    );
  }

  Widget _buildGridItem(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _Thumbnail(asset: widget.asset)),
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: _isEditing
                ? TextField(
                    controller: _controller,
                    autofocus: true,
                    onSubmitted: (_) => _submitRename(),
                    style: const TextStyle(fontSize: 12),
                    decoration: const InputDecoration(isDense: true),
                  )
                : Text(
                    widget.asset.filename,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Asset?'),
        content: Text(
          'Are you sure you want to delete ${widget.asset.filename}? This will not remove references in workflows but the file will be gone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<AssetViewModel>().deleteAsset(widget.asset);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final Asset asset;

  const _Thumbnail({required this.asset});

  @override
  Widget build(BuildContext context) {
    // In a real app, we'd use a FutureBuilder or a cached image service
    // For now, let's use the thumbnail path if it exists
    return FutureBuilder<String>(
      future: context.read<AssetViewModel>().getThumbnailPath(asset),
      builder: (context, snapshot) {
        if (snapshot.hasData && File(snapshot.data!).existsSync()) {
          return Image.file(File(snapshot.data!), fit: BoxFit.fitHeight);
        }
        return const Icon(Icons.image);
      },
    );
  }
}
