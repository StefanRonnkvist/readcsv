import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../data/csv_repository.dart';
import 'dataset_rows_table.dart';

/// Sentinel value meaning "no specific column selected" in the filter dropdown.
const String kAllColumnsValue = '__all_columns__';

/// Sentinel value meaning "no specific value selected" in the filter dropdown.
const String kAllValues = '__all_values__';

/// Shows dataset metadata, export actions, the two filters, and the row table.
class DatasetPanel extends StatefulWidget {
  const DatasetPanel({
    super.key,
    required this.dataset,
    required this.rows,
    required this.onRenameDataset,
    required this.onDeleteDataset,
    required this.onExportJson,
    required this.onExportXml,
  });

  final CsvDataset dataset;
  final List<Map<String, String>>? rows;
  final Future<void> Function(CsvDataset dataset) onRenameDataset;
  final Future<void> Function(CsvDataset dataset) onDeleteDataset;
  final Future<void> Function(CsvDataset dataset) onExportJson;
  final Future<void> Function(CsvDataset dataset) onExportXml;

  @override
  State<DatasetPanel> createState() => _DatasetPanelState();
}

class _DatasetPanelState extends State<DatasetPanel> {
  String _selectedSearchValue = kAllValues;
  String _selectedHeader = kAllColumnsValue;
  String _textSearchQuery = '';

  /// Resets filters when the active dataset changes and repairs stale values.
  @override
  void didUpdateWidget(covariant DatasetPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.dataset.id != widget.dataset.id) {
      _selectedSearchValue = kAllValues;
      _selectedHeader = kAllColumnsValue;
      _textSearchQuery = '';
      return;
    }

    if (_selectedHeader != kAllColumnsValue &&
        !widget.dataset.headers.contains(_selectedHeader)) {
      _selectedHeader = kAllColumnsValue;
    }

    final List<String> options = _searchOptions();
    if (_selectedSearchValue != kAllValues &&
        !options.contains(_selectedSearchValue)) {
      _selectedSearchValue = kAllValues;
    }
  }

  /// Returns sorted, distinct non-empty values for the selected column.
  List<String> _searchOptions() {
    if (_selectedHeader == kAllColumnsValue || widget.rows == null) {
      return <String>[];
    }

    final Set<String> values = <String>{};
    for (final Map<String, String> row in widget.rows!) {
      final String value = (row[_selectedHeader] ?? '').trim();
      if (value.isNotEmpty) {
        values.add(value);
      }
    }

    return values.toList()..sort(
      (String a, String b) => a.toLowerCase().compareTo(b.toLowerCase()),
    );
  }

  /// Applies the exact-value filter followed by case-insensitive text search.
  ///
  /// Returns `null` while rows are still loading.
  List<Map<String, String>>? _filteredRows() {
    final List<Map<String, String>>? sourceRows = widget.rows;
    if (sourceRows == null) {
      return null;
    }

    Iterable<Map<String, String>> filtered = sourceRows;

    if (_selectedSearchValue != kAllValues &&
        _selectedHeader != kAllColumnsValue) {
      final String selected = _selectedSearchValue.toLowerCase();
      filtered = filtered.where((Map<String, String> row) {
        final String value = (row[_selectedHeader] ?? '').trim().toLowerCase();
        return value == selected;
      });
    }

    final String query = _textSearchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((Map<String, String> row) {
        for (final String header in widget.dataset.headers) {
          final String value = (row[header] ?? '').toLowerCase();
          if (value.contains(query)) {
            return true;
          }
        }
        return false;
      });
    }

    return filtered.toList();
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>>? filteredRows = _filteredRows();
    final List<String> searchOptions = _searchOptions();
    final bool hasSearch =
        _selectedSearchValue != kAllValues ||
        _textSearchQuery.trim().isNotEmpty;
    final int totalRows = widget.rows?.length ?? 0;
    final int shownRows = filteredRows?.length ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${widget.dataset.name} • ${widget.dataset.rowCount} rows',
                style: Theme.of(context).textTheme.titleMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton.icon(
              onPressed: () => widget.onRenameDataset(widget.dataset),
              icon: const Icon(Icons.edit),
              label: const Text('Rename'),
            ),
            TextButton.icon(
              onPressed: () => widget.onDeleteDataset(widget.dataset),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete'),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () => widget.onExportJson(widget.dataset),
              icon: const Icon(Icons.data_object),
              label: const Text('Export JSON'),
            ),
            OutlinedButton.icon(
              onPressed: () => widget.onExportXml(widget.dataset),
              icon: const Icon(Icons.code),
              label: const Text('Export XML'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Size: ${formatFileSize(widget.dataset.size)}'),
        const SizedBox(height: 8),
        Text('Search', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final Widget categoryField = DropdownButtonFormField<String>(
              initialValue: _selectedHeader,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: <DropdownMenuItem<String>>[
                const DropdownMenuItem<String>(
                  value: kAllColumnsValue,
                  child: Text('All Categories'),
                ),
                ...widget.dataset.headers.map(
                  (String header) => DropdownMenuItem<String>(
                    value: header,
                    child: Text(header, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
              onChanged: (String? value) {
                setState(() {
                  _selectedHeader = value ?? kAllColumnsValue;
                  _selectedSearchValue = kAllValues;
                });
              },
            );

            final Widget searchValueField = DropdownButtonFormField<String>(
              initialValue: _selectedSearchValue,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Search contents',
                hintText: _selectedHeader == kAllColumnsValue
                    ? 'Select category first'
                    : 'Select a value',
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              items: <DropdownMenuItem<String>>[
                const DropdownMenuItem<String>(
                  value: kAllValues,
                  child: Text('All Values'),
                ),
                ...searchOptions.map(
                  (String value) => DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
              onChanged: _selectedHeader == kAllColumnsValue
                  ? null
                  : (String? value) {
                      setState(() {
                        _selectedSearchValue = value ?? kAllValues;
                      });
                    },
            );

            if (constraints.maxWidth < 700) {
              return Column(
                children: [
                  categoryField,
                  const SizedBox(height: 8),
                  searchValueField,
                ],
              );
            }

            return Row(
              children: [
                Expanded(flex: 2, child: categoryField),
                const SizedBox(width: 8),
                Expanded(flex: 3, child: searchValueField),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Text search',
            hintText: 'Enter text to match rows',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: (String value) {
            setState(() {
              _textSearchQuery = value;
            });
          },
        ),
        const SizedBox(height: 8),
        Text(
          hasSearch
              ? 'Showing $shownRows of $totalRows rows'
              : '$totalRows rows',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 10),
        Text('Contents', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        SizedBox(
          height: 250,
          child: DatasetRowsTable(
            headers: widget.dataset.headers,
            rows: filteredRows,
            emptyMessage: hasSearch
                ? 'No matching rows found.'
                : 'No data rows found.',
          ),
        ),
      ],
    );
  }
}
