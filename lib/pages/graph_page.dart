import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:expense_tracker/services/utils.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import 'package:expense_tracker/services/translation_service.dart';

class GraphPage extends StatefulWidget {
  const GraphPage({super.key});

  @override
  State<GraphPage> createState() => _GraphPageState();
}

class _GraphPageState extends State<GraphPage> {
  final myBox = Hive.box('transactions');
  final settingsBox = Hive.box('settings');

  DateTime get _displayMonth {
    String? savedMonth = settingsBox.get('selectedMonth');
    return savedMonth != null ? DateTime.parse(savedMonth) : DateTime.now();
  }

  void _updateMonth(DateTime newMonth) {
    settingsBox.put('selectedMonth', DateTime(newMonth.year, newMonth.month).toIso8601String());
  }

  List<PieChartSectionData> getSections(List<dynamic> transactions, bool isDark) {
    Map<String, double> data = {};
    for (var item in transactions) {
      double amount = 0;
      bool isExp = true;
      String category = 'Other';
      
      if (item is Transaction) {
        amount = item.amount;
        isExp = item.isExpense;
        category = item.category;
      } else if (item is Map) {
        amount = (item['amount'] as num? ?? 0.0).toDouble();
        isExp = item['isExpense'] ?? true;
        category = (item['category'] ?? 'Other').toString();
      }

      if (isExp) {
        data[category] = (data[category] ?? 0) + amount;
      }
    }
    if (data.isEmpty) return [];

    final List<Color> chartColors = [
      const Color(0xFF38BDF8),
      const Color(0xFF00FF88),
      const Color(0xFFFF5252),
      const Color(0xFFFBBF24),
      const Color(0xFF818CF8),
      const Color(0xFFF472B6),
    ];

    return data.entries.map((entry) {
      final index = data.keys.toList().indexOf(entry.key);
      return PieChartSectionData(
        color: chartColors[index % chartColors.length],
        value: entry.value,
        title: '', // Hiding titles to prevent "shopping line" overlapping
        radius: 50,
        showTitle: false,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ValueListenableBuilder(
      valueListenable: settingsBox.listenable(keys: ['language', 'selectedMonth', 'currency']),
      builder: (context, Box settings, _) {
        DateTime currentMonth = _displayMonth;
        String currency = settings.get('currency', defaultValue: 'Rs.');
        String lang = settings.get('language', defaultValue: 'English');

        return Scaffold(
          appBar: AppBar(
            title: Text(TranslationService.t('analysis', lang)),
          ),
          body: ValueListenableBuilder(
            valueListenable: myBox.listenable(),
            builder: (context, Box box, _) {
              final filteredList = box.values
                  .where((item) {
                    DateTime? date;
                    if (item is Transaction) {
                      date = item.date;
                    } else if (item is Map) {
                      date = item['date'] != null ? DateTime.tryParse(item['date'].toString()) : null;
                    }
                    return date != null && date.month == currentMonth.month && date.year == currentMonth.year;
                  })
                  .toList();
              
              final sections = getSections(filteredList, isDark);
              
              double totalExpense = 0;
              for (var item in filteredList) {
                if (item is Transaction && item.isExpense) {
                  totalExpense += item.amount;
                } else if (item is Map && (item['isExpense'] ?? true)) {
                  totalExpense += (item['amount'] as num? ?? 0.0).toDouble();
                }
              }

              return Column(
                children: [
                  // Month Selector
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => _updateMonth(DateTime(currentMonth.year, currentMonth.month - 1)),
                          icon: const Icon(Icons.chevron_left, color: Color(0xFF38BDF8))
                        ),
                        Text(
                          DateFormat('MMMM yyyy').format(currentMonth),
                          style: TextStyle(
                            fontSize: 18, 
                            fontWeight: FontWeight.w900, 
                            color: isDark ? Colors.white : const Color(0xFF334155)
                          ),
                        ),
                        IconButton(
                          onPressed: () => _updateMonth(DateTime(currentMonth.year, currentMonth.month + 1)),
                          icon: const Icon(Icons.chevron_right, color: Color(0xFF38BDF8))
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: sections.isEmpty
                        ? Center(child: Text(TranslationService.t('noRecords', lang), style: const TextStyle(color: Colors.black38)))
                        : ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            children: [
                              const SizedBox(height: 20),
                              // Centered Pie Chart with Total Expense in Middle
                              SizedBox(
                                height: 220,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    PieChart(
                                      PieChartData(
                                        sections: sections,
                                        centerSpaceRadius: 80,
                                        sectionsSpace: 4,
                                        pieTouchData: PieTouchData(enabled: true),
                                      ),
                                    ),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          TranslationService.t('expenses', lang).toUpperCase(), 
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.black45, letterSpacing: 1.2)
                                        ),
                                        Text(
                                          "$currency ${totalExpense.toStringAsFixed(0)}", 
                                          style: TextStyle(
                                            fontSize: 24, 
                                            fontWeight: FontWeight.w900, 
                                            color: isDark ? Colors.white : const Color(0xFF334155)
                                          )
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 40),
                              // Premium Category Legend
                              ...filteredList
                                  .where((item) => item is Transaction ? item.isExpense : (item['isExpense'] ?? true))
                                  .map((item) => item is Transaction ? item.category : (item['category'] ?? 'Other').toString())
                                  .toSet()
                                  .map((cat) {
                                    double catTotal = 0;
                                    for (var item in filteredList) {
                                      String itemCat = item is Transaction ? item.category : (item['category'] ?? 'Other').toString();
                                      bool isExp = item is Transaction ? item.isExpense : (item['isExpense'] ?? true);
                                      if (itemCat == cat && isExp) {
                                        catTotal += item is Transaction ? item.amount : (item['amount'] as num? ?? 0.0).toDouble();
                                      }
                                    }
                                    double percentage = totalExpense > 0 ? (catTotal / totalExpense) * 100 : 0;
                                    
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(isDark ? 0.3 : 0.04), 
                                            blurRadius: 10, 
                                            offset: const Offset(0, 4)
                                          )
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 14,
                                            height: 14,
                                            decoration: BoxDecoration(
                                              color: AppUtils.getCategoryColor(cat),
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Colors.white.withOpacity(0.2), width: 2)
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  cat, 
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold, 
                                                    color: isDark ? Colors.white : const Color(0xFF334155),
                                                    fontSize: 15
                                                  )
                                                ),
                                                Text(
                                                  "${percentage.toStringAsFixed(1)}%",
                                                  style: const TextStyle(color: Colors.grey, fontSize: 12)
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            "$currency ${catTotal.toStringAsFixed(0)}",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w900, 
                                              color: Color(0xFF38BDF8),
                                              fontSize: 16
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                              const SizedBox(height: 100),
                            ],
                          ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

}
