import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'app/app_shell.dart';

void main() {
  // debugPrintMarkNeedsLayoutStacks = true;
  runApp(const PicPakApp());

  FlutterError.onError = (details) {
    debugPrint("ERROR: ${details.exception}");
    debugPrintStack(stackTrace: details.stack);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
  debugPrint("PLATFORM ERROR: $error");
  debugPrint(stack.toString());
  return true;
};
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

      builder: (context, child) {
        return ExcludeSemantics(
          child: child ?? const SizedBox.shrink()
        );
      },

      home: AppShell(
        onToggleTheme: toggleTheme
      )
    );
  }
}
