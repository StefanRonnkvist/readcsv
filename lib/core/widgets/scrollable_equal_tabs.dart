import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Horizontally scrollable row of equal-width choice chips.
class ScrollableEqualTabs extends StatelessWidget {
  const ScrollableEqualTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double minTabWidth = 120;
        final double width = constraints.maxWidth;
        final double tabWidth = math.max(minTabWidth, width / labels.length);

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List<Widget>.generate(labels.length, (int index) {
              return SizedBox(
                width: tabWidth,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    selected: selectedIndex == index,
                    label: SizedBox(
                      width: double.infinity,
                      child: Text(
                        labels[index],
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    onSelected: (_) => onSelected(index),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
