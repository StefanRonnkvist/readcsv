import 'package:flutter/material.dart';

import 'help_section.dart';

/// Empty-state panel explaining how to use the application.
class HelpPanel extends StatelessWidget {
  const HelpPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Using Read CSV',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Import a tabular file, inspect and filter its rows, then copy the '
            'data as JSON or XML. Each imported file has its own dataset tab.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          const HelpSection(
            title: '1) Import a file',
            body:
                'Open Upload New Document and choose a CSV, TSV, or TXT file. '
                'Import is available on Android and Windows in this build. '
                'Comma, semicolon, tab, and pipe delimiters are detected '
                'automatically.',
          ),
          const SizedBox(height: 10),
          const HelpSection(
            title: '2) Check the imported data',
            body:
                'The first record is used as the header row. Blank header '
                'names receive a generated name, duplicate headers are made '
                'unique, and completely empty data rows are skipped. The '
                'dataset tab shows its row count, file size, and scrollable '
                'table.',
          ),
          const SizedBox(height: 10),
          const HelpSection(
            title: '3) Search and filter',
            body:
                'Choose a column and one of its values to find exact matches. '
                'Text search checks every column and is not case-sensitive. '
                'Both filters can be used together; the row summary shows how '
                'many records match.',
          ),
          const SizedBox(height: 10),
          const HelpSection(
            title: '4) Manage datasets',
            body:
                'Use Rename to change a dataset tab name. Duplicate names '
                'receive a numeric suffix. Use Delete to permanently remove a '
                'dataset and all of its stored rows after confirmation.',
          ),
          const SizedBox(height: 10),
          const HelpSection(
            title: '5) Copy JSON or XML',
            body:
                'Export JSON and Export XML open a preview of the complete '
                'dataset. Select Copy to place the generated text on the '
                'clipboard, then paste it into the app or file of your choice.',
          ),
          const SizedBox(height: 10),
          const HelpSection(
            title: '6) Storage and privacy',
            body:
                'Imported datasets are stored locally on your device and '
                'remain available after restarting the app. Importing, '
                'browsing, filtering, and exporting do not send your dataset '
                'contents to the contact server.',
          ),
          const SizedBox(height: 10),
          const HelpSection(
            title: '7) Information and network access',
            body:
                'Information > Form sends your name, return email, question, '
                'and basic app/device diagnostics to the configured contact '
                'server. Server Data uses the internet to retrieve inquiries '
                'associated with this app.',
          ),
          const SizedBox(height: 10),
          const HelpSection(
            title: '8) Appearance and layout',
            body:
                'Choose System, Dark, or Light from the theme control; your '
                'choice is remembered. The workspace adapts to phone, tablet, '
                'and desktop widths, and tab bars scroll when space is '
                'limited.',
          ),
        ],
      ),
    );
  }
}
