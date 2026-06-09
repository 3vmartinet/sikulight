import 'package:flutter/material.dart';
import '../models/asset_node.dart';

class AssetNodeWidget extends StatelessWidget {
  final AssetNode node;

  const AssetNodeWidget({super.key, required this.node});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).primaryColor),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Text(node.action.value),
          // Placeholder for thumbnail logic: T005 thumbnail implementation
          const Icon(Icons.image, size: 50), 
        ],
      ),
    );
  }
}
