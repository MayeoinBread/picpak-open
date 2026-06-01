import 'package:flutter/material.dart';
import 'package:flutter_app/app/services/ble_service.dart';
import 'package:flutter_app/app/services/device_session_service.dart';
import 'package:flutter_app/app/widgets/common/status_bar.dart';

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
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: session,
      builder: (context, state, _) {
        return Scaffold(
          body: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    NavigationRail(
                      selectedIndex: selectedIndex,
                      onDestinationSelected: (index) {
                        setState(() => selectedIndex = index);
                      },
                      labelType: NavigationRailLabelType.all,
                      trailing: IconButton(
                        icon: const Icon(Icons.dark_mode),
                        onPressed: widget.onToggleTheme,
                      ),
                      destinations: const [
                        NavigationRailDestination(
                          icon: Icon(Icons.dashboard_outlined),
                          selectedIcon: Icon(Icons.dashboard),
                          label: Text('Dashboard'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.build_outlined),
                          selectedIcon: Icon(Icons.build),
                          label: Text('Dev Tools'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.library_books_outlined),
                          selectedIcon: Icon(Icons.library_books),
                          label: Text('Library'),
                        ),
                      ],
                    ),

                    const VerticalDivider(width: 1),

                    Expanded(
                      child: IndexedStack(
                        index: selectedIndex,
                        children: const [
                          DashboardPage(),
                          DevWorkbenchPage(),
                          LibraryPage(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              StatusBar(
                state: state,
                progressListenable: ble.uploadProgress,
              ),
            ],
          ),
        );
      },
    );
  }
}