import 'package:flutter/material.dart';
import 'package:picpak_open/app/services/ble_service.dart';
import 'package:picpak_open/app/services/device_session_service.dart';
import 'package:picpak_open/app/state/device_session_state.dart';
import 'package:picpak_open/app/widgets/common/status_bar.dart';

import 'pages/dashboard_page.dart';
import 'pages/dev_workbench_page.dart';
import 'pages/library_page.dart';

class AppShell extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const AppShell({
    super.key,
    required this.onToggleTheme
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int selectedIndex = 0;

  final session = DeviceSessionService.instance;
  final ble = BleService.instance.manager;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  static const _railDestinations = [
    NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Dashboard')),
    NavigationRailDestination(icon: Icon(Icons.library_books_outlined), selectedIcon: Icon(Icons.library_books), label: Text('Library')),
    NavigationRailDestination(icon: Icon(Icons.build_outlined), selectedIcon: Icon(Icons.build), label: Text('Dev Tools'))
  ];

  static const _barDestinations = [
    NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
    NavigationDestination(icon: Icon(Icons.library_books_outlined), selectedIcon: Icon(Icons.library_books), label: 'Library'),
    NavigationDestination(icon: Icon(Icons.build_outlined), selectedIcon: Icon(Icons.build), label: 'Dev')
  ];

  void _onDestinationSelected(int index) {
    setState(() => selectedIndex = index);
  }

  Widget _pageStack() {
    return RepaintBoundary(
      child: IndexedStack(
        index: selectedIndex,
        children: const [
          DashboardPage(),
          LibraryPage(),
          DevWorkbenchPage()
        ]
      )
    );
  }

  Widget _statusBar() {
    return ValueListenableBuilder<DeviceSessionState>(
      valueListenable: session,
      builder: (context, state, _) => StatusBar(state: state)
    );
  }

  Widget _buildMobileScaffold(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("PicPak Open"),
        actions: [
          IconButton(
            icon: const Icon(Icons.dark_mode),
            onPressed: widget.onToggleTheme,
          )
        ]
      ),

      body: Column(
        children: [
          Expanded(child: _pageStack()),

          _statusBar()
        ]
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: _barDestinations
      ),
    );
  }

  Widget _buildDesktopScaffold(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("PicPak Open"),
        actions: [
          IconButton(
            icon: const Icon(Icons.dark_mode),
            onPressed: widget.onToggleTheme,
          )
        ]
      ),
      
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                NavigationRail(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: _onDestinationSelected,
                  labelType: NavigationRailLabelType.all,
                  trailing: IconButton(
                    icon: const Icon(Icons.dark_mode),
                    onPressed: widget.onToggleTheme,
                  ),
                  destinations: _railDestinations,
                ),

                const VerticalDivider(width: 1),

                Expanded(child: _pageStack())
              ],
            ),
          ),

          _statusBar()

        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 700;

    return isMobile
      ? _buildMobileScaffold(context)
      : _buildDesktopScaffold(context);
  }
}