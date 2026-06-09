import 'package:flutter/material.dart';

class SaveWarningDialog extends StatelessWidget {
  final List<String> missingAssetIds;

  const SaveWarningDialog({super.key, required this.missingAssetIds});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange),
          SizedBox(width: 8),
          Text('Missing Assets'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'The following assets were not found and will not be included in the .macaque bundle. The workflow might not be fully portable.',
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            width: double.maxFinite,
            child: ListView.builder(
              itemCount: missingAssetIds.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Text(
                  '• ${missingAssetIds[index]}',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Save Anyway'),
        ),
      ],
    );
  }
}
