import 'package:flutter/material.dart';

import '../../../core/widgets/scrollable_equal_tabs.dart';
import '../data/csv_repository.dart';
import '../datasets_controller.dart';
import 'dataset_panel.dart';
import 'help_panel.dart';
import 'upload_panel.dart';

/// Tab strip plus the body for whichever tab is currently selected.
///
/// This widget is purely presentational: every action is a callback owned by
/// [DatasetsController] or the page that hosts it.
class CsvTabsSection extends StatelessWidget {
  const CsvTabsSection({
    super.key,
    required this.datasets,
    required this.selectedTabIndex,
    required this.isLoadingFile,
    required this.isLoadingDatasets,
    required this.activeRows,
    required this.informationContent,
    required this.onTabSelected,
    required this.onPickFile,
    required this.onRenameDataset,
    required this.onDeleteDataset,
    required this.onExportJson,
    required this.onExportXml,
  });

  final List<CsvDataset> datasets;
  final int selectedTabIndex;
  final bool isLoadingFile;
  final bool isLoadingDatasets;
  final List<Map<String, String>>? activeRows;
  final Widget informationContent;
  final ValueChanged<int> onTabSelected;
  final Future<void> Function() onPickFile;
  final Future<void> Function(CsvDataset dataset) onRenameDataset;
  final Future<void> Function(CsvDataset dataset) onDeleteDataset;
  final Future<void> Function(CsvDataset dataset) onExportJson;
  final Future<void> Function(CsvDataset dataset) onExportXml;

  @override
  Widget build(BuildContext context) {
    final List<String> tabLabels = <String>[
      'Upload New Document',
      'Help',
      'Information',
      ...datasets.map((e) => e.name),
    ];

    final bool showsDatasetTab = selectedTabIndex >= kFirstDatasetTabIndex;
    final CsvDataset? activeDataset = !showsDatasetTab
        ? null
        : datasets[selectedTabIndex - kFirstDatasetTabIndex];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScrollableEqualTabs(
              labels: tabLabels,
              selectedIndex: selectedTabIndex,
              onSelected: onTabSelected,
            ),
            const SizedBox(height: 12),
            if (selectedTabIndex == kUploadTabIndex)
              UploadPanel(isLoadingFile: isLoadingFile, onPickFile: onPickFile)
            else if (selectedTabIndex == kHelpTabIndex)
              const HelpPanel()
            else if (selectedTabIndex == kInformationTabIndex)
              informationContent
            else if (isLoadingDatasets)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (activeDataset != null)
              DatasetPanel(
                dataset: activeDataset,
                rows: activeRows,
                onRenameDataset: onRenameDataset,
                onDeleteDataset: onDeleteDataset,
                onExportJson: onExportJson,
                onExportXml: onExportXml,
              ),
          ],
        ),
      ),
    );
  }
}
