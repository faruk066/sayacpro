import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/device_provider.dart';
import 'providers/cloud_provider.dart';
import 'providers/app_data_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/main_layout.dart';
import 'theme/app_theme.dart';
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "dummy_key",
        appId: "dummy_id",
        messagingSenderId: "dummy_sender",
        projectId: "dummy_project",
      )
    );
  } catch (e) {
    debugPrint("Firebase init failed: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DeviceProvider()),
        ChangeNotifierProvider(create: (_) => CloudProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Builder(
        builder: (context) {
          return ChangeNotifierProvider<AppDataProvider>.value(
            value: kIsWeb ? context.read<CloudProvider>() : context.read<DeviceProvider>(),
            child: const SayacProApp(),
          );
        },
      ),
    ),
  );
}

class SayacProApp extends StatelessWidget {
  const SayacProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'Sayaç Pro',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          home: const MainLayout(),
        );
      },
    );
  }
}
