import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:expense_tracker/models/transaction.dart';
import 'package:expense_tracker/models/debt.dart';
import 'package:expense_tracker/models/goal.dart';
import 'package:expense_tracker/pages/splash_screen.dart';
import 'package:expense_tracker/services/notification_service.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Hive initialization
    await Hive.initFlutter();
    
    // Notification initialization (wrapped in try-catch)
    try {
      await NotificationService.init();
      await NotificationService.scheduleDailyReminder();
    } catch (e) {
      debugPrint("Notification Init Error: $e");
    }

    // Register adapters
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(TransactionAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(DebtAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(GoalAdapter());

    // Open boxes with error handling
    await Future.wait([
      Hive.openBox('transactions'),
      Hive.openBox('categories'),
      Hive.openBox('settings'),
      Hive.openBox('debts'),
      Hive.openBox('goals'),
    ]);

    final settingsBox = Hive.box('settings');
    if (settingsBox.get('currency') == null) await settingsBox.put('currency', 'Rs.');
    if (settingsBox.get('themeMode') == null) await settingsBox.put('themeMode', 'light');
    
    if (settingsBox.get('selectedMonth') == null) {
      final now = DateTime.now();
      await settingsBox.put('selectedMonth', DateTime(now.year, now.month).toIso8601String());
    }

    final categoryBox = Hive.box('categories');
    if (categoryBox.isEmpty) {
      await categoryBox.addAll(['Food', 'Travel', 'Bills', 'Shopping', 'Salary', 'Other']);
    }

    runApp(const MyApp());
  } catch (e) {
    debugPrint("Critical Init Error: $e");
    // Fallback to ensure app starts
    runApp(const MaterialApp(home: Scaffold(body: Center(child: Text("App Error. Please restart.")))));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsBox = Hive.box('settings');

    return ValueListenableBuilder(
      valueListenable: settingsBox.listenable(keys: ['themeMode', 'language']),
      builder: (context, Box box, _) {
        final String themeModeStr = box.get('themeMode', defaultValue: 'light');
        ThemeMode themeMode = themeModeStr == 'dark' ? ThemeMode.dark : ThemeMode.light;

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Expense Tracker',
          themeMode: themeMode,
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark),
          home: const SplashScreen(),
        );
      },
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    bool isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF38BDF8),
        brightness: brightness,
        primary: const Color(0xFF38BDF8),
        surface: isDark ? const Color(0xFF1E293B) : Colors.white,
        onSurface: isDark ? Colors.white : const Color(0xFF334155),
      ),
      scaffoldBackgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFF38BDF8),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w900,
        ),
      ),
      cardTheme: CardThemeData(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
      ),
    );
  }
}
