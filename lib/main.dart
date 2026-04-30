import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:google_fonts/google_fonts.dart';

import 'data/services/notification_service.dart';

import 'di/injection.dart';
import 'presentation/auth/auth_gate.dart';

// Providers migrated to Riverpod

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
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'Debt Manager',

      theme: ThemeData(
        useMaterial3: true,

        colorScheme:
            ColorScheme.fromSeed(
              seedColor: const Color(0xff0f766e),
              brightness: Brightness.light,
            ).copyWith(
              primary: const Color(0xff0f766e),
              secondary: const Color(0xfff59e0b),
              tertiary: const Color(0xff14b8a6),
              surface: Colors.white,
              background: const Color(0xfff6f4f0),
            ),

        textTheme: () {
          final base = ThemeData.light().textTheme;
          final body = GoogleFonts.manropeTextTheme(base);
          final display = GoogleFonts.spaceGroteskTextTheme(base);

          return body.copyWith(
            displayLarge: display.displayLarge,
            displayMedium: display.displayMedium,
            displaySmall: display.displaySmall,
            headlineLarge: display.headlineLarge,
            headlineMedium: display.headlineMedium,
            headlineSmall: display.headlineSmall,
            titleLarge: display.titleLarge,
          );
        }(),

        scaffoldBackgroundColor: const Color(0xfff6f4f0),

        appBarTheme: AppBarTheme(
          centerTitle: true,
          backgroundColor: Colors.transparent,
          foregroundColor: const Color(0xff0b1b1a),
          elevation: 0,
          titleTextStyle: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xff0b1b1a),
          ),
        ),

        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shadowColor: const Color(0x1a0f172a),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),

        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xff0f766e),
          foregroundColor: Colors.white,
        ),

        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xff0f766e),
          unselectedItemColor: Color(0xff6b7280),
          showUnselectedLabels: true,
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xffe5e7eb)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xff0f766e), width: 1.4),
          ),
        ),
      ),

      home: const AuthGate(),
    );
  }
}
