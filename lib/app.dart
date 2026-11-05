import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import 'controller.dart';
import 'screens/home_screen.dart';

class NexusLoopApp extends StatelessWidget {
  const NexusLoopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NexusController()..init(),
      child: MaterialApp(
        title: 'NEXUS LOOP',
        debugShowCheckedModeBanner: false,
        theme: nexusTheme(),
        home: const HomeScreen(),
      ),
    );
  }
}