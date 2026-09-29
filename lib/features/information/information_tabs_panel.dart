import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/widgets/scrollable_equal_tabs.dart';

/// Index of the Information > Form sub-tab.
const int kFormTabIndex = 0;

/// Index of the Information > Server Data sub-tab.
const int kServerDataTabIndex = 1;

/// Toggles between the contact form and the remote submissions browser.
///
/// The selected sub-tab is persisted so it survives restarts.
class InformationTabsPanel extends StatefulWidget {
  const InformationTabsPanel({
    super.key,
    required this.formContent,
    required this.serverDataContent,
  });

  final Widget formContent;
  final Widget serverDataContent;

  @override
  State<InformationTabsPanel> createState() => _InformationTabsPanelState();
}

class _InformationTabsPanelState extends State<InformationTabsPanel> {
  static const String _selectedInfoTabKey = 'selected_information_tab_index';
  int _selectedIndex = kFormTabIndex;

  @override
  void initState() {
    super.initState();
    _restoreSelectedInformationTab();
  }

  /// Restores the previously selected information sub-tab.
  Future<void> _restoreSelectedInformationTab() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int savedIndex = prefs.getInt(_selectedInfoTabKey) ?? kFormTabIndex;
    final int normalizedIndex = savedIndex.clamp(
      kFormTabIndex,
      kServerDataTabIndex,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedIndex = normalizedIndex;
    });
  }

  /// Saves the selected information sub-tab for the next session.
  Future<void> _persistSelectedInformationTab(int index) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_selectedInfoTabKey, index);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ScrollableEqualTabs(
          labels: const <String>['Form', 'Server Data'],
          selectedIndex: _selectedIndex,
          onSelected: (int index) {
            setState(() {
              _selectedIndex = index;
            });
            _persistSelectedInformationTab(index);
          },
        ),
        const SizedBox(height: 12),
        if (_selectedIndex == kFormTabIndex)
          widget.formContent
        else if (_selectedIndex == kServerDataTabIndex)
          widget.serverDataContent,
      ],
    );
  }
}
