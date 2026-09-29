import 'package:flutter/material.dart';

/// Two-dimensionally scrollable data grid for one dataset.
class DatasetRowsTable extends StatelessWidget {
  const DatasetRowsTable({
    super.key,
    required this.headers,
    required this.rows,
    required this.emptyMessage,
  });

  final List<String> headers;
  final List<Map<String, String>>? rows;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (rows == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (headers.isEmpty) {
      return const Center(child: Text('No header row found in CSV.'));
    }

    if (rows!.isEmpty) {
      return Center(child: Text(emptyMessage));
    }

    final List<Map<String, String>> visibleRows = rows!;

    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: headers
                .map(
                  (h) => DataColumn(
                    label: Text(h, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            rows: visibleRows
                .map(
                  (row) => DataRow(
                    cells: headers
                        .map(
                          (header) => DataCell(
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 260),
                              child: Text(
                                row[header] ?? '',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}
