import 'package:flutter/material.dart';
import 'package:flutter_app/app/services/ble_service.dart';

import 'app/app_shell.dart';

void main() {
  final ble = BleService.instance;

  ble.manager.uploadProgress.addListener(() {
    ble.uploadProgress.value = ble.manager.uploadProgress.value;
  });

  runApp(const PicPakApp());
}

class PicPakApp extends StatefulWidget {
  const PicPakApp({super.key});

  @override
  State<PicPakApp> createState() => _PicPakAppState();
}

class _PicPakAppState extends State<PicPakApp> {
  ThemeMode themeMode = ThemeMode.dark;

  void toggleTheme() {
    setState(() {
      themeMode = themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PicPak Open',
      debugShowCheckedModeBanner: false,
      
      themeMode: themeMode,

      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: Color.fromARGB(255, 255, 127, 0)
      ),

      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Color.fromARGB(255, 0, 127, 255)
      ),

      home: AppShell(
        onToggleTheme: toggleTheme
      )
    );
  }
}
