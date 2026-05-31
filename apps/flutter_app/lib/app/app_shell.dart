import 'package:flutter/material.dart';
import 'package:flutter_app/app/pages/crash_test_page.dart';

import 'pages/dashboard_page.dart';
import 'pages/dev_workbench_page.dart';

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

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(),
      DevWorkbenchPage()
      // CrashTestPage()
    ];

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            labelType: NavigationRailLabelType.all,
            onDestinationSelected: (index) {
              setState(() {
                selectedIndex = index;
              });
            },
            trailing: IconButton(
              icon: const Icon(Icons.dark_mode),
              onPressed: widget.onToggleTheme,
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Dashboard')
              ),
              NavigationRailDestination(
                icon: Icon(Icons.build_outlined),
                selectedIcon: Icon(Icons.build),
                label: Text('Dev Tools')
              )
            ]
          ),

          const VerticalDivider(width: 1),

          Expanded(
            child: pages[selectedIndex]
          )
        ],
      )
    );
  }
}