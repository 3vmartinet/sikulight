import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ui/features/assets/view_models/asset_view_model.dart';
import 'package:ui/features/assets/widgets/drag_and_drop_overlay.dart';

import 'package:ui/features/assets/widgets/asset_item_tile.dart';

class AssetRegistryPanel extends StatefulWidget {
  const AssetRegistryPanel({super.key});

  @override
  State<AssetRegistryPanel> createState() => _AssetRegistryPanelState();
}

class _AssetRegistryPanelState extends State<AssetRegistryPanel> {
  bool _isGridView = false;

  @override
  Widget build(BuildContext context) {
    return DragAndDropOverlay(
      child: Column(
        children: [
          _Toolbar(
            isGridView: _isGridView,
            onToggleView: () => setState(() => _isGridView = !_isGridView),
          ),
          Expanded(
            child: _AssetList(isGridView: _isGridView),
          ),
        ],
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  final bool isGridView;
  final VoidCallback onToggleView;

  const _Toolbar({
    required this.isGridView,
    required this.onToggleView,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      height: 40,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<AssetViewModel>().repairRegistry(),
            tooltip: 'Repair Registry',
            iconSize: 20,
          ),
          IconButton(
            icon: Icon(isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: onToggleView,
            tooltip: isGridView ? 'Switch to List' : 'Switch to Grid',
            iconSize: 20,
          ),
        ],
      ),
    );
  }
}

class _AssetList extends StatelessWidget {
  final bool isGridView;

  const _AssetList({required this.isGridView});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AssetViewModel>();
    
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.assets.isEmpty) {
      return const Center(
        child: Text('No assets. Drag images here.'),
      );
    }

    if (isGridView) {
      return GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.8,
        ),
        itemCount: viewModel.assets.length,
        itemBuilder: (context, index) => AssetItemTile(
          asset: viewModel.assets[index],
          isGridView: true,
        ),
      );
    }

    return ListView.builder(
      itemCount: viewModel.assets.length,
      itemBuilder: (context, index) => AssetItemTile(
        asset: viewModel.assets[index],
        isGridView: false,
      ),
    );
  }
}
