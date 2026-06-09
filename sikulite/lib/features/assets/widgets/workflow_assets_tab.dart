import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sikulite/features/assets/view_models/asset_view_model.dart';
import 'package:sikulite/features/assets/widgets/asset_item_tile.dart';

class WorkflowAssetsTab extends StatelessWidget {
  final bool isGridView;

  const WorkflowAssetsTab({super.key, required this.isGridView});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AssetViewModel>();

    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.isolatedAssets.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No workflow-specific assets found in this bundle.',
            textAlign: TextAlign.center,
          ),
        ),
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
        itemCount: viewModel.isolatedAssets.length,
        itemBuilder: (context, index) =>
            AssetItemTile(asset: viewModel.isolatedAssets[index], isGridView: true),
      );
    }

    return ListView.builder(
      itemCount: viewModel.isolatedAssets.length,
      itemBuilder: (context, index) =>
          AssetItemTile(asset: viewModel.isolatedAssets[index], isGridView: false),
    );
  }
}
