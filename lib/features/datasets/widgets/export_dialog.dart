import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shows a generated export document and offers a copy-to-clipboard action.
Future<void> showExportDialog({
  required BuildContext context,
  required String title,
  required String formatLabel,
  required String content,
  required void Function(String message) onShowSnackBar,
}) async {
  await showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text('Export $formatLabel'),
        content: SizedBox(
          width: 700,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(dialogContext).textTheme.labelLarge),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 340),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(dialogContext).dividerColor,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(child: SelectableText(content)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: content));
              if (!dialogContext.mounted) {
                return;
              }
              Navigator.of(dialogContext).pop();
              onShowSnackBar('$formatLabel copied to clipboard.');
            },
            child: const Text('Copy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}
