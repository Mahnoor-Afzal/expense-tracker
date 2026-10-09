import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'home_page.dart';
import 'categories_page.dart';
import 'graph_page.dart';
import 'settings_page.dart';
import 'add_transaction_page.dart';
import 'package:expense_tracker/services/translation_service.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const CategoriesPage(),
    const GraphPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final settingsBox = Hive.box('settings');

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: ValueListenableBuilder(
        valueListenable: settingsBox.listenable(keys: ['language']),
        builder: (context, Box box, _) {
          final String lang = box.get('language', defaultValue: 'English');
          final bool isDark = Theme.of(context).brightness == Brightness.dark;
          
          return BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9), // Theme-aware
            selectedItemColor: const Color(0xFF38BDF8), // Sky Blue
            unselectedItemColor: isDark ? Colors.white38 : const Color(0xFF64748B),
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.dashboard_rounded), 
                label: TranslationService.t('dashboard', lang)
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.category_rounded), 
                label: TranslationService.t('categories', lang)
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.analytics_rounded), 
                label: TranslationService.t('analysis', lang)
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.settings_rounded), 
                label: TranslationService.t('settings', lang)
              ),
            ],
          );
        },
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddTransactionPage()),
                );
              },
              backgroundColor: const Color(0xFF38BDF8),
              child: const Icon(Icons.add, size: 30, color: Colors.white),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
