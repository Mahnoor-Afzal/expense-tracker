import 'dart:io' show File;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import '../models/transaction.dart';
import 'categories_page.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/services/translation_service.dart';
import 'debt_tracker_page.dart';
import 'savings_goals_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final nameController = TextEditingController();
  final budgetController = TextEditingController();
  
  final List<String> currencies = ['Rs.', r'$', '€', '£', '¥', 'PKR', 'INR'];
  final List<String> themes = ['light', 'dark'];
  final List<String> languages = ['English', 'Urdu', 'Arabic', 'Hindi'];

  @override
  void initState() {
    super.initState();
    try {
      final box = Hive.box('settings');
      nameController.text = box.get('userName', defaultValue: 'Wealth Manager');
      budgetController.text = box.get('monthlyBudget', defaultValue: '0');
    } catch (_) {}
  }

  Future<void> _exportToCSV() async {
    try {
      final box = Hive.box('transactions');
      final transactions = box.values.toList();
      if (transactions.isEmpty) return;
      List<List<dynamic>> rows = [["Date", "Title", "Category", "Type", "Amount"]];
      for (var item in transactions) {
        DateTime date = DateTime.now();
        String title = "";
        String category = "Other";
        bool isExpense = true;
        double amount = 0;

        if (item is Transaction) {
          date = item.date;
          title = item.title;
          category = item.category;
          isExpense = item.isExpense;
          amount = item.amount;
        } else if (item is Map) {
          date = item['date'] != null ? DateTime.tryParse(item['date'].toString()) ?? DateTime.now() : DateTime.now();
          title = item['title']?.toString() ?? "";
          category = item['category']?.toString() ?? "Other";
          isExpense = item['isExpense'] ?? true;
          amount = (item['amount'] as num? ?? 0.0).toDouble();
        }
        
        rows.add([DateFormat('yyyy-MM-dd').format(date), title, category, isExpense ? "Expense" : "Income", amount]);
      }
      String csvData = const ListToCsvConverter().convert(rows);
      
      if (kIsWeb) {
        final bytes = utf8.encode(csvData);
        await Share.shareXFiles(
          [XFile.fromData(bytes, name: 'report_${DateTime.now().millisecondsSinceEpoch}.csv', mimeType: 'text/csv')],
          text: 'My Expense Report'
        );
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final path = "${directory.path}/report_${DateTime.now().millisecondsSinceEpoch}.csv";
        File file = File(path);
        await file.writeAsString(csvData);
        await Share.shareXFiles([XFile(path)], text: 'My Expense Report');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _importCSV() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom, 
        allowedExtensions: ['csv'],
        withData: true
      );
      
      if (result != null) {
        List<List<dynamic>> fields;
        if (kIsWeb || result.files.single.path == null) {
          final bytes = result.files.single.bytes;
          if (bytes == null) return;
          final csvString = utf8.decode(bytes);
          fields = const CsvToListConverter().convert(csvString);
        } else {
          File file = File(result.files.single.path!);
          final input = file.openRead();
          fields = await input.transform(utf8.decoder).transform(const CsvToListConverter()).toList();
        }

        final txBox = Hive.box('transactions');
        for (int i = 1; i < fields.length; i++) {
          final row = fields[i];
          if (row.length < 5) continue;
          
          DateTime date;
          try {
            date = DateFormat('yyyy-MM-dd').parse(row[0].toString());
          } catch (_) {
            date = DateTime.now();
          }

          final tx = Transaction(
            id: DateTime.now().millisecondsSinceEpoch.toString() + i.toString(),
            title: row[1].toString(),
            category: row[2].toString(),
            isExpense: row[3].toString().toLowerCase() == 'expense',
            amount: double.tryParse(row[4].toString()) ?? 0.0,
            date: date,
          );
          
          try {
            await txBox.add(tx);
          } catch (e) {
            final box = await Hive.openBox('transactions');
            await box.add(tx);
          }
        }
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Import completed successfully!"), backgroundColor: Colors.green)
          );
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final sBox = Hive.box('settings');

    return ValueListenableBuilder(
      valueListenable: sBox.listenable(keys: ['themeMode', 'language', 'currency', 'userName', 'monthlyBudget']),
      builder: (context, Box box, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        String currentCurrency = box.get('currency', defaultValue: 'Rs.');
        String currentTheme = box.get('themeMode', defaultValue: 'light');
        String currentLang = box.get('language', defaultValue: 'English');
        String userName = box.get('userName', defaultValue: 'Wealth Manager');
        String monthlyBudget = box.get('monthlyBudget', defaultValue: '0');

        // Update controllers only if they are not being edited
        if (nameController.text != userName && !FocusScope.of(context).hasFocus) {
          nameController.text = userName;
        }
        if (budgetController.text != monthlyBudget && !FocusScope.of(context).hasFocus) {
          budgetController.text = monthlyBudget;
        }

        String t(String key) => TranslationService.t(key, currentLang);

        return Scaffold(
          appBar: AppBar(title: Text(t('settings'))),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(t('account'), isDark),
                _buildInputCard(Icons.person_outline, t('userName'), nameController, (v) => box.put('userName', v), isDark),
                _buildInputCard(Icons.account_balance_wallet_outlined, t('budget'), budgetController, (v) => box.put('monthlyBudget', v), isDark, isNumeric: true),

                const SizedBox(height: 25),

                _buildSectionHeader(t('preferences'), isDark),
                _buildSettingCard(
                  isDark: isDark,
                  icon: Icons.palette_outlined,
                  title: t('theme'),
                  trailing: _buildDropdown(currentTheme, themes, (v) => box.put('themeMode', v)),
                ),
                _buildSettingCard(
                  isDark: isDark,
                  icon: Icons.language_outlined,
                  title: t('language'),
                  trailing: _buildDropdown(currentLang, languages, (v) => box.put('language', v)),
                ),
                _buildSettingCard(
                  isDark: isDark,
                  icon: Icons.currency_exchange_rounded,
                  title: t('currency'),
                  trailing: _buildDropdown(currentCurrency, currencies, (v) => box.put('currency', v)),
                ),

                const SizedBox(height: 25),

                _buildSectionHeader(t('data'), isDark),
                _buildSettingCard(isDark: isDark, icon: Icons.category_outlined, title: t('categories'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const CategoriesPage()))),
                _buildSettingCard(isDark: isDark, icon: Icons.account_balance_wallet_outlined, title: "Debt & Loan Tracker", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const DebtTrackerPage()))),
                _buildSettingCard(isDark: isDark, icon: Icons.stars_rounded, title: "Savings Goals", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const SavingsGoalsPage()))),
                _buildSettingCard(isDark: isDark, icon: Icons.file_download_outlined, title: t('export'), onTap: _exportToCSV),
                _buildSettingCard(isDark: isDark, icon: Icons.file_upload_outlined, title: t('import'), onTap: _importCSV),

                const SizedBox(height: 25),

                _buildSectionHeader(t('supportInfo'), isDark),
                _buildSettingCard(isDark: isDark, icon: Icons.share_rounded, title: t('share'), onTap: () => Share.share(t('appShareText'))),
                _buildSettingCard(isDark: isDark, icon: Icons.info_outline, title: t('about'), onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: t('wealthManager'),
                    applicationVersion: t('version'),
                    applicationIcon: const Icon(Icons.account_balance_wallet, color: Color(0xFF38BDF8), size: 40),
                    children: [Text(t('aboutText'))],
                  );
                }),

                const SizedBox(height: 25),

                _buildSectionHeader(t('dangerZone'), isDark),
                _buildSettingCard(
                  isDark: isDark,
                  icon: Icons.delete_sweep_outlined,
                  title: t('deleteData'),
                  titleColor: const Color(0xFFFF5252),
                  onTap: () => _showDeleteDialog(context),
                ),

                const SizedBox(height: 40),
                Center(child: Text(t('version'), style: const TextStyle(color: Colors.black26, fontSize: 12))),
                const SizedBox(height: 50),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(title.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: isDark ? Colors.white70 : const Color(0xFF334155), letterSpacing: 1.2)),
    );
  }

  Widget _buildInputCard(IconData icon, String label, TextEditingController controller, Function(String) onChanged, bool isDark, {bool isNumeric = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
      child: TextField(
        controller: controller,
        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        onChanged: onChanged,
        decoration: InputDecoration(
          icon: Icon(icon, color: const Color(0xFF38BDF8), size: 20),
          labelText: label,
          labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.black45),
          border: InputBorder.none
        ),
      ),
    );
  }

  Widget _buildSettingCard({required bool isDark, required IconData icon, required String title, Widget? trailing, Color? titleColor, VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
      child: ListTile(
        leading: Icon(icon, color: titleColor ?? const Color(0xFF38BDF8), size: 22),
        title: Text(title, style: TextStyle(color: titleColor ?? (isDark ? Colors.white : const Color(0xFF334155)), fontWeight: FontWeight.bold, fontSize: 15)),
        trailing: trailing ?? const Icon(Icons.chevron_right, size: 20, color: Colors.black26),
        onTap: onTap,
      ),
    );
  }

  Widget _buildDropdown(String value, List<String> items, Function(String?) onChanged) {
    return DropdownButton<String>(
      value: items.contains(value) ? value : items[0],
      dropdownColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
      underline: const SizedBox(),
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold)))).toList(),
      onChanged: (v) { onChanged(v); setState(() {}); },
    );
  }

  void _showDeleteDialog(BuildContext context) {
    String currentLang = 'English';
    try {
      currentLang = Hive.box('settings').get('language', defaultValue: 'English');
    } catch (_) {}
    String t(String key) => TranslationService.t(key, currentLang);
    
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(t('resetData'), style: const TextStyle(color: Color(0xFFFF5252), fontWeight: FontWeight.bold)),
        content: Text(t('confirmReset')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c), 
            child: Text(t('cancel'), style: const TextStyle(color: Colors.grey))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5252),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              try {
                await Hive.box('transactions').clear();
              } catch (e) {
                final box = await Hive.openBox('transactions');
                await box.clear();
              }
              if (context.mounted) {
                Navigator.pop(c);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(t('deletedSuccessfully')),
                    backgroundColor: const Color(0xFFFF5252),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            },
            child: Text(t('delete').toUpperCase()),
          ),
        ],
      ),
    );
  }
}
