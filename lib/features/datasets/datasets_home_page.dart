import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/layout/app_shell.dart';
import '../../core/layout/desktop_layout.dart';
import '../../core/layout/phone_layout.dart';
import '../../core/layout/tablet_layout.dart';
import '../contact/contact_page.dart';
import '../contact/submissions_csv_page.dart';
import '../information/information_tabs_panel.dart';
import 'data/csv_repository.dart';
import 'datasets_controller.dart';
import 'widgets/csv_tabs_section.dart';
import 'widgets/export_dialog.dart';

/// Contact endpoint used by the Information > Form tab.
const String kContactEndpoint = 'https://stefanronnkvist.com/contact.php';

/// Remote submissions CSV used by the Information > Server Data tab.
const String kSubmissionsCsvUrl = 'https://stefanronnkvist.com/submissions.csv';

/// Hosts the dataset workspace and wires [DatasetsController] to the UI.
class DatasetsHomePage extends StatelessWidget {
  const DatasetsHomePage({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DatasetsController>(
      create: (_) => DatasetsController()..loadDatasets(),
      child: _DatasetsHomeView(
        themeMode: themeMode,
        onThemeModeChanged: onThemeModeChanged,
      ),
    );
  }
}

class _DatasetsHomeView extends StatelessWidget {
  const _DatasetsHomeView({
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  void _showSnackBar(BuildContext context, String message) {
    if (message.isEmpty) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Prompts for a new unique name and persists it for [dataset].
  Future<void> _renameDataset(BuildContext context, CsvDataset dataset) async {
    final DatasetsController controller = context.read<DatasetsController>();
    final TextEditingController textController = TextEditingController(
      text: dataset.name,
    );

    final String? renamed = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Rename CSV Tab'),
          content: TextField(
            controller: textController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'New name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(textController.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    textController.dispose();

    if (renamed == null || renamed.isEmpty) {
      return;
    }

    await controller.renameDataset(dataset, renamed);
  }

  /// Confirms and permanently removes [dataset] and its cached rows.
  Future<void> _deleteDataset(BuildContext context, CsvDataset dataset) async {
    final DatasetsController controller = context.read<DatasetsController>();

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete CSV Tab'),
          content: Text('Delete ${dataset.name} and all stored rows?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await controller.deleteDataset(dataset);
  }

  Future<void> _pickLocalFile(BuildContext context) async {
    final DatasetsController controller = context.read<DatasetsController>();
    final ImportResult result = await controller.pickLocalFile();
    if (!context.mounted) {
      return;
    }
    _showSnackBar(context, result.message);
  }

  /// Generates the requested document and opens the shared export dialog.
  Future<void> _exportDataset(
    BuildContext context,
    CsvDataset dataset, {
    required bool asJson,
  }) async {
    final DatasetsController controller = context.read<DatasetsController>();
    final String formatLabel = asJson ? 'JSON' : 'XML';

    try {
      final String content = asJson
          ? await controller.exportDatasetAsJson(dataset)
          : await controller.exportDatasetAsXml(dataset);

      if (!context.mounted) {
        return;
      }

      await showExportDialog(
        context: context,
        title: '${dataset.name}.${formatLabel.toLowerCase()}',
        formatLabel: formatLabel,
        content: content,
        onShowSnackBar: (String message) {
          if (context.mounted) {
            _showSnackBar(context, message);
          }
        },
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      _showSnackBar(
        context,
        'Failed to export $formatLabel for ${dataset.name}.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DatasetsController>(
      builder: (BuildContext context, DatasetsController controller, _) {
        final Widget csvTabsSection = CsvTabsSection(
          datasets: controller.datasets,
          selectedTabIndex: controller.selectedTabIndex,
          isLoadingFile: controller.isLoadingFile,
          isLoadingDatasets: controller.isLoadingDatasets,
          activeRows: controller.activeRows,
          informationContent: InformationTabsPanel(
            formContent: ContactPage(
              serverUri: Uri.parse(kContactEndpoint),
              showAppBar: false,
              wrapInScaffold: false,
            ),
            serverDataContent: const SubmissionsCsvCardsView(
              csvUrl: kSubmissionsCsvUrl,
            ),
          ),
          onTabSelected: controller.selectTab,
          onPickFile: () => _pickLocalFile(context),
          onRenameDataset: (CsvDataset dataset) =>
              _renameDataset(context, dataset),
          onDeleteDataset: (CsvDataset dataset) =>
              _deleteDataset(context, dataset),
          onExportJson: (CsvDataset dataset) =>
              _exportDataset(context, dataset, asJson: true),
          onExportXml: (CsvDataset dataset) =>
              _exportDataset(context, dataset, asJson: false),
        );

        return _buildWithLayout(context, controller, csvTabsSection);
      },
    );
  }

  /// Picks a layout tier for the available width and applies the web notice.
  Widget _buildWithLayout(
    BuildContext context,
    DatasetsController controller,
    Widget csvTabsSection,
  ) {
    final Widget responsiveLayout = LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < kPhoneMaxWidth) {
          return PhoneLayout(
            csvTabsSection: csvTabsSection,
            themeMode: themeMode,
            onThemeModeChanged: onThemeModeChanged,
          );
        }

        if (constraints.maxWidth < kTabletMaxWidth) {
          return TabletLayout(
            csvTabsSection: csvTabsSection,
            themeMode: themeMode,
            onThemeModeChanged: onThemeModeChanged,
          );
        }

        return DesktopLayout(
          csvTabsSection: csvTabsSection,
          themeMode: themeMode,
          onThemeModeChanged: onThemeModeChanged,
        );
      },
    );

    if (!kIsWeb || !controller.showWebDatabaseNotice) {
      return responsiveLayout;
    }

    return Column(
      children: [
        Material(
          color: Colors.red.shade700,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'PWA notice: database functions are not available on web '
                      'builds. Data is temporary for this browser session only.',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Dismiss notice',
                    onPressed: controller.dismissWebDatabaseNotice,
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(child: responsiveLayout),
      ],
    );
  }
}
