import 'package:flutter/material.dart';
import 'package:ui/features/assets/view_models/asset_view_model.dart';

class DuplicateDialog extends StatelessWidget {
  final String filename;

  const DuplicateDialog({super.key, required this.filename});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Duplicate Asset'),
      content: Text('The file "$filename" already exists in the registry. What would you like to do?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(DuplicateResolution.skip),
          child: const Text('Skip'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(DuplicateResolution.rename),
          child: const Text('Rename'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(DuplicateResolution.overwrite),
          child: const Text('Overwrite'),
        ),
      ],
    );
  }
}
