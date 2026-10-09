import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart'; 
import 'package:expense_tracker/models/transaction.dart';
import 'package:expense_tracker/pages/add_transaction_page.dart';
import 'package:expense_tracker/pages/notifications_page.dart';
import 'package:expense_tracker/services/utils.dart';
import 'package:expense_tracker/services/translation_service.dart';
import 'package:expense_tracker/pages/debt_tracker_page.dart';
import 'package:expense_tracker/pages/savings_goals_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Use getters instead of final variables to avoid stale connections on Web
  Box get myBox => Hive.box('transactions');
  Box get settingsBox => Hive.box('settings');

  DateTime get _selectedMonth {
    try {
      String? saved = settingsBox.get('selectedMonth');
      return saved != null ? DateTime.parse(saved) : DateTime.now();
    } catch (e) {
      return DateTime.now();
    }
  }

  void _updateMonth(int delta) {
    try {
      DateTime current = _selectedMonth;
      DateTime newMonth = DateTime(current.year, current.month + delta);
      settingsBox.put('selectedMonth', newMonth.toIso8601String());
    } catch (e) {
      print("Update month error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ValueListenableBuilder(
          valueListenable: settingsBox.listenable(keys: ['language']),
          builder: (context, Box box, _) {
            final lang = box.get('language', defaultValue: 'English');
            return Text(TranslationService.t('dashboard', lang));
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const NotificationsPage())),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: settingsBox.listenable(keys: ['selectedMonth', 'currency', 'language', 'userName']),
        builder: (context, Box settings, _) {
          final String lang = settings.get('language', defaultValue: 'English');
          final String currency = settings.get('currency', defaultValue: 'Rs.');
          final String userName = settings.get('userName', defaultValue: 'Wealth Manager');
          final DateTime currentMonth = _selectedMonth;

          return ValueListenableBuilder(
            valueListenable: myBox.listenable(),
            builder: (context, Box box, _) {
              // Redefine isDark inside the builder to ensure it's available in this scope
              final bool isDark = Theme.of(context).brightness == Brightness.dark;
              
              final filteredList = box.values.where((item) {
                DateTime? date;
                if (item is Transaction) {
                  date = item.date;
                } else if (item is Map) {
                  date = item['date'] != null ? DateTime.tryParse(item['date'].toString()) : null;
                }
                return date != null && date.month == currentMonth.month && date.year == currentMonth.year;
              }).toList();

              filteredList.sort((a, b) {
                DateTime dateA = a is Transaction ? a.date : (DateTime.tryParse(a['date'].toString()) ?? DateTime.now());
                DateTime dateB = b is Transaction ? b.date : (DateTime.tryParse(b['date'].toString()) ?? DateTime.now());
                return dateB.compareTo(dateA);
              });

              double income = 0;
              double expense = 0;
              for (var item in filteredList) {
                double amount = 0;
                bool isExp = true;
                if (item is Transaction) {
                  amount = item.amount;
                  isExp = item.isExpense;
                } else if (item is Map) {
                  amount = (item['amount'] as num? ?? 0.0).toDouble();
                  isExp = item['isExpense'] ?? true;
                }
                
                if (isExp) expense += amount;
                else income += amount;
              }

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: const Color(0xFF38BDF8).withOpacity(0.1), // Bohot halka blue background
                              shape: BoxShape.circle,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10.0), // Icon ko darmyan mein space dene ke liye
                              child: Image.asset(
                                'assets/icon/app_icon.png',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF38BDF8), size: 30),
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                TranslationService.t('welcome', lang), 
                                style: TextStyle(color: isDark ? Colors.white60 : Colors.black45, fontSize: 14)
                              ),
                              Text(
                                userName, 
                                style: TextStyle(
                                  color: isDark ? Colors.white : const Color(0xFF334155), 
                                  fontSize: 26, 
                                  fontWeight: FontWeight.w900, 
                                  letterSpacing: 0.5
                                )
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(onPressed: () => _updateMonth(-1), icon: const Icon(Icons.chevron_left, color: Color(0xFF38BDF8))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF38BDF8).withOpacity(0.1), 
                              borderRadius: BorderRadius.circular(20)
                            ),
                            child: Text(
                              DateFormat('MMMM yyyy').format(currentMonth), 
                              style: TextStyle(
                                fontSize: 16, 
                                fontWeight: FontWeight.w900, 
                                color: isDark ? Colors.white : const Color(0xFF334155)
                              )
                            ),
                          ),
                          IconButton(onPressed: () => _updateMonth(1), icon: const Icon(Icons.chevron_right, color: Color(0xFF38BDF8))),
                        ],
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft, 
                          end: Alignment.bottomRight, 
                          colors: [Color(0xFF38BDF8), Color(0xFF0EA5E9)]
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF38BDF8).withOpacity(0.3), 
                            blurRadius: 15, 
                            offset: const Offset(0, 8)
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            TranslationService.t('totalBalance', lang), 
                            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "$currency ${(income - expense).toStringAsFixed(2)}", 
                            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)
                          ),
                          const SizedBox(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildSummaryItem(TranslationService.t('income', lang), "+$currency ${income.toStringAsFixed(0)}", Icons.south_west_rounded, const Color(0xFF00FF88)),
                              Container(width: 1, height: 30, color: Colors.white24),
                              _buildSummaryItem(TranslationService.t('expenses', lang), "-$currency ${expense.toStringAsFixed(0)}", Icons.north_east_rounded, const Color(0xFFFF5252)),
                            ],
                          )
                        ],
                      ),
                    ),

                    // Quick Actions Row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                      child: Row(
                        children: [
                          _buildQuickAction(
                            context, 
                            TranslationService.t('debtTracker', lang), 
                            Icons.handshake_outlined, 
                            const Color(0xFF38BDF8), 
                            const DebtTrackerPage(), 
                            isDark
                          ),
                          const SizedBox(width: 12),
                          _buildQuickAction(
                            context, 
                            TranslationService.t('savingsGoals', lang), 
                            Icons.stars_rounded, 
                            const Color(0xFF00FF88), 
                            const SavingsGoalsPage(), 
                            isDark
                          ),
                        ],
                      ),
                    ),

                    _buildBudgetSection(lang, currency, expense, isDark),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 25, 20, 10),
                      child: Text(
                        TranslationService.t('recentActivity', lang), 
                        style: TextStyle(
                          fontWeight: FontWeight.w900, 
                          fontSize: 18, 
                          color: isDark ? Colors.white : const Color(0xFF334155)
                        )
                      ),
                    ),

                    if (filteredList.isEmpty) 
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 60.0), 
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 80,
                                color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                TranslationService.t('noRecords', lang), 
                                style: TextStyle(
                                  color: isDark ? Colors.white38 : Colors.black38,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                )
                              ),
                            ],
                          )
                        )
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredList.length,
                        itemBuilder: (context, i) {
                          var item = filteredList[i];
                          return _buildTransactionItem(item, currency, isDark);
                        },
                      ),
                    const SizedBox(height: 100),
                  ],
                ),
              );
            }
          );
        }
      ),
    );
  }

  Widget _buildBudgetSection(String lang, String currency, double expense, bool isDark) {
    double budget = 0;
    try {
      budget = double.tryParse(Hive.box('settings').get('monthlyBudget', defaultValue: '0')) ?? 0;
    } catch (_) {}
    if (budget <= 0) return const SizedBox.shrink();
    double percent = (expense / budget).clamp(0.0, 1.0);
    Color progressColor = percent > 0.9 ? const Color(0xFFFF5252) : const Color(0xFF38BDF8);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(TranslationService.t('monthlyBudget', lang), style: TextStyle(color: isDark ? Colors.white : const Color(0xFF334155), fontWeight: FontWeight.bold, fontSize: 14)),
              Text("${(percent * 100).toStringAsFixed(0)}%", style: TextStyle(color: progressColor, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: percent, backgroundColor: progressColor.withOpacity(0.1), color: progressColor, minHeight: 8, borderRadius: BorderRadius.circular(10)),
          const SizedBox(height: 8),
          Text("$currency ${expense.toStringAsFixed(0)} ${TranslationService.t('usedOf', lang)} $currency ${budget.toStringAsFixed(0)}", style: TextStyle(color: isDark ? Colors.white70 : Colors.black45, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(dynamic item, String currency, bool isDark) {
    final String id = item is Transaction ? item.id : (item['id'] ?? '').toString();
    final String title = item is Transaction ? item.title : (item['title'] ?? '').toString();
    final String category = item is Transaction ? item.category : (item['category'] ?? '').toString();
    final double amount = item is Transaction ? item.amount : (item['amount'] as num? ?? 0.0).toDouble();
    final bool isExpense = item is Transaction ? item.isExpense : (item['isExpense'] ?? true);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
      child: Dismissible(
        key: Key(id),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async {
          final lang = Hive.box('settings').get('language', defaultValue: 'English');
          return await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(TranslationService.t('deleteRecord', lang)),
              content: Text(TranslationService.t('confirmDelete', lang)),
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(TranslationService.t('cancel', lang))),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true), 
                  child: Text(TranslationService.t('delete', lang), style: const TextStyle(color: Color(0xFFFF5252), fontWeight: FontWeight.bold))
                ),
              ],
            ),
          );
        },
        onDismissed: (_) async {
          if (item is Transaction) {
            try {
              await item.delete();
            } catch (_) {
              final index = Hive.box('transactions').values.toList().indexOf(item);
              if (index != -1) await Hive.box('transactions').deleteAt(index);
            }
          } else {
            // Find index and delete
            final index = Hive.box('transactions').values.toList().indexOf(item);
            if (index != -1) await Hive.box('transactions').deleteAt(index);
          }
          final lang = Hive.box('settings').get('language', defaultValue: 'English');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(TranslationService.t('deletedSuccessfully', lang)),
                backgroundColor: const Color(0xFFFF5252),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
        },
        background: Container(
          alignment: Alignment.centerRight, 
          padding: const EdgeInsets.only(right: 20), 
          decoration: BoxDecoration(color: const Color(0xFFFF5252), borderRadius: BorderRadius.circular(16)), 
          child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 28)
        ),
        child: InkWell(
          onTap: () {
            if (item is Transaction) {
              Navigator.push(context, MaterialPageRoute(builder: (c) => AddTransactionPage(transaction: item)));
            } else {
              // Map migration to Transaction object when editing
              final tx = Transaction(
                id: id,
                title: title,
                amount: amount,
                date: item['date'] != null ? DateTime.tryParse(item['date'].toString()) ?? DateTime.now() : DateTime.now(),
                category: category,
                isExpense: isExpense,
              );
              Navigator.push(context, MaterialPageRoute(builder: (c) => AddTransactionPage(transaction: tx)));
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                Icon(AppUtils.getCategoryIcon(category), color: isExpense ? const Color(0xFFFF5252) : const Color(0xFF00FF88)),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, 
                    children: [
                      Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)), 
                      Text(category, style: TextStyle(color: isDark ? Colors.white60 : Colors.black45, fontSize: 12))
                    ]
                  )
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("${isExpense ? '-' : '+'} $currency $amount", style: TextStyle(color: isExpense ? const Color(0xFFFF5252) : const Color(0xFF00FF88), fontWeight: FontWeight.w900)),
                    const SizedBox(height: 5),
                    GestureDetector(
                      onTap: () async {
                        final lang = Hive.box('settings').get('language', defaultValue: 'English');
                        final bool? confirmed = await showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: Text(TranslationService.t('deleteRecord', lang)),
                            content: Text(TranslationService.t('confirmDelete', lang)),
                            actions: [
                              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(TranslationService.t('cancel', lang))),
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(true), 
                                child: Text(TranslationService.t('delete', lang), style: const TextStyle(color: Color(0xFFFF5252), fontWeight: FontWeight.bold))
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          if (item is Transaction) {
                            try {
                              await item.delete();
                            } catch (_) {
                              final index = Hive.box('transactions').values.toList().indexOf(item);
                              if (index != -1) await Hive.box('transactions').deleteAt(index);
                            }
                          } else {
                            final index = Hive.box('transactions').values.toList().indexOf(item);
                            if (index != -1) await Hive.box('transactions').deleteAt(index);
                          }
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(TranslationService.t('deletedSuccessfully', lang)),
                                backgroundColor: const Color(0xFFFF5252),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5252).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFFF5252)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String amount, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ), 
        const SizedBox(width: 12), 
        Column(
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [
            Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)), 
            Text(amount, style: TextStyle(
              color: Colors.white, 
              fontWeight: FontWeight.w900, 
              fontSize: 18,
            )),
          ]
        )
      ]
    );
  }

  Widget _buildQuickAction(BuildContext context, String title, IconData icon, Color color, Widget page, bool isDark) {
    return Expanded(
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => page)),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
            border: Border.all(color: color.withOpacity(0.1), width: 1),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                title, 
                style: TextStyle(
                  fontSize: 12, 
                  fontWeight: FontWeight.bold, 
                  color: isDark ? Colors.white70 : const Color(0xFF334155)
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
