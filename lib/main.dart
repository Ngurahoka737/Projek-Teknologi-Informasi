import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/splash_screen.dart';

import 'data/services/notification_service.dart';

import 'di/injection.dart';

// Provider
import 'providers/debt_provider.dart';

// Navigation

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // INIT DEPENDENCIES (DI)
  await initDependencies();

  // INIT FORMAT INDONESIA
  await initializeDateFormatting('id_ID', null);

  // INIT NOTIFIKASI
  await NotificationService.init();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => DebtProvider())],

      child: MaterialApp(
        debugShowCheckedModeBanner: false,

        title: 'Debt Manager',

        theme: ThemeData(
          useMaterial3: true,

          colorSchemeSeed: Colors.indigo,

          scaffoldBackgroundColor: const Color(0xfff5f7fb),

          appBarTheme: const AppBarTheme(
            centerTitle: true,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
          ),

          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 3,
            shadowColor: Colors.black12,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),

          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),

          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,

            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.black12),
            ),
          ),
        ),

        home: const SplashScreen(),
      ),
    );
  }
}
