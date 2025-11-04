import 'package:bellezza_pos/pages/main_webview_page.dart';
import 'package:flutter/material.dart';
import 'package:bellezza_pos/services/shared_preferences_service.dart';
import 'package:bellezza_pos/pages/initial_setup_page.dart';

import 'config/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferencesService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConfig.appName,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: _getInitialPage(),
    );
  }

  Widget _getInitialPage() {
    final currentUrl = SharedPreferencesService.getBaseUrl();
    final isConfigured = SharedPreferencesService.isConfigured;

    if (isConfigured && currentUrl != AppConfig.defaultBaseUrl) {
      return const MainWebViewPage();
    } else {
      return const InitialSetupPage();
    }
  }
}