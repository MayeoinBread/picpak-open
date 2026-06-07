import 'package:flutter/material.dart';
import 'package:flutter_app/app/services/ble_service.dart';
import 'package:flutter_app/app/services/device_session_service.dart';
import 'package:flutter_app/app/state/device_session_state.dart';
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
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("AppShell build");
    
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
                  child: RepaintBoundary(
                    child: IndexedStack(
                      index: selectedIndex,
                      children: [
                        Builder(
                          builder: (context) {
                            debugPrint("DASHBOARD BUILDER ENTERED");
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              debugPrint("DASHBOARD FIRST FRAME");
                            });
                            
                            return const DashboardPage();
                          }
                        ),
                        Builder(
                          builder: (context) {
                            debugPrint("DEV BUILDER ENTERED");
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              debugPrint("DEV FIRST FRAME");
                            });
                            
                            return const DevWorkbenchPage();
                          }
                        ),
                        Builder(
                          builder: (context) {
                            debugPrint("LIB BUILDER ENTERED");
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              debugPrint("LIB FIRST FRAME");
                            });
                            
                            return const LibraryPage();
                          }
                        )
                        // const DashboardPage(),
                        // const DevWorkbenchPage(),
                        // const LibraryPage()
                      ],
                    ),
                  )
                ),
              ],
            ),
          ),

          ValueListenableBuilder<DeviceSessionState>(
            valueListenable: session,
            builder: (context, state, _) {
              return StatusBar(
                state: state
              );
            }
          )
        ],
      ),
    );
  }
}