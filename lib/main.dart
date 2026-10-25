import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/generation_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/home_shell.dart';
import 'services/secure_settings.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final secure = SecureSettings();
  final settings = SettingsProvider(secure);
  await settings.load();

  final generation = GenerationProvider(secure);
  // Warm history cache in the background
  generation.loadHistory();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: generation),
      ],
      child: const TaglineApp(),
    ),
  );
}

class TaglineApp extends StatelessWidget {
  const TaglineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tagline',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const HomeShell(),
    );
  }
}
