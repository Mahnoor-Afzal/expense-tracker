import 'package:flutter/material.dart';
import 'package:expense_tracker/services/notification_service.dart';
import 'package:expense_tracker/services/translation_service.dart';
import 'package:hive_flutter/hive_flutter.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    String currentLang = 'English';
    try {
      currentLang = Hive.box('settings').get('language', defaultValue: 'English');
    } catch (_) {}

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    String t(String key) => TranslationService.t(key, currentLang);

    return Scaffold(
      appBar: AppBar(
        title: Text(t('notifications')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(15),
        children: [
          // Empty State Illustration or Text
          const SizedBox(height: 50),
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.notifications_off_outlined,
                  size: 80,
                  color: isDark ? Colors.white10 : Colors.black12,
                ),
                const SizedBox(height: 15),
                Text(
                  t('noMoreNotifications'),
                  style: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
