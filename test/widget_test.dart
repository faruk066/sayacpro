import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sayac_pro/main.dart';
import 'package:sayac_pro/providers/device_provider.dart';
import 'package:sayac_pro/providers/cloud_provider.dart';
import 'package:sayac_pro/providers/app_data_provider.dart';
import 'package:sayac_pro/providers/theme_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  testWidgets('SayacPro app smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});

    await tester.pumpWidget(
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
    await tester.pumpAndSettle();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
