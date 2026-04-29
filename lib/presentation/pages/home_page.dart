import 'package:flutter/material.dart';
import '../../core/app_config.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppConfig.appName)),
      body: const Center(child: Text('Welcome — dashboard coming soon')),
    );
  }
}
