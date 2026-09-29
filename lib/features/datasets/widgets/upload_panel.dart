import 'package:flutter/material.dart';

/// Empty-state panel that triggers a local file import.
class UploadPanel extends StatelessWidget {
  const UploadPanel({
    super.key,
    required this.isLoadingFile,
    required this.onPickFile,
  });

  final bool isLoadingFile;
  final Future<void> Function() onPickFile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FilledButton.icon(
          onPressed: isLoadingFile ? null : onPickFile,
          icon: const Icon(Icons.upload_file),
          label: Text(isLoadingFile ? 'Loading...' : 'Upload document'),
        ),
        const SizedBox(height: 10),
        const Text(
          'Upload a CSV, TSV, or TXT document to inspect its rows and '
          'columns. Supported files are imported as separate tabs for easy '
          'review and export.',
        ),
      ],
    );
  }
}
