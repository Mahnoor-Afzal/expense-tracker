import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/translation_service.dart';
import '../models/goal.dart';

class SavingsGoalsPage extends StatefulWidget {
  const SavingsGoalsPage({super.key});

  @override
  State<SavingsGoalsPage> createState() => _SavingsGoalsPageState();
}

class _SavingsGoalsPageState extends State<SavingsGoalsPage> {
  String get currentLang {
    try {
      final box = Hive.box('settings');
      return box.get('language')?.toString() ?? 'English';
    } catch (_) {
      return 'English';
    }
  }

  String get currency {
    try {
      final box = Hive.box('settings');
      return box.get('currency')?.toString() ?? 'Rs.';
    } catch (_) {
      return 'Rs.';
    }
  }

  String t(String key) {
    try {
      return TranslationService.t(key, currentLang);
    } catch (_) {
      return key;
    }
  }

  void _showGoalDialog({dynamic goal, int? index}) {
    String initialTitle = '';
    String initialTarget = '';
    String initialSaved = '0';

    try {
      if (goal != null) {
        initialTitle = (goal is Goal ? goal.title : goal['title'])?.toString() ?? '';
        initialTarget = (goal is Goal ? goal.targetAmount : goal['target'])?.toString() ?? '';
        initialSaved = (goal is Goal ? goal.savedAmount : goal['saved'])?.toString() ?? '0';
      }
    } catch (_) {}

    final titleController = TextEditingController(text: initialTitle);
    final targetController = TextEditingController(text: initialTarget);
    final savedController = TextEditingController(text: initialSaved);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(goal == null ? t('savingsGoals') : t('editRecord')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: t('goalName'), prefixIcon: const Icon(Icons.stars_rounded))
            ),
            const SizedBox(height: 10),
            TextField(
              controller: targetController,
              decoration: InputDecoration(labelText: t('targetAmount'), prefixIcon: const Icon(Icons.flag_circle_rounded)),
              keyboardType: TextInputType.number
            ),
            const SizedBox(height: 10),
            TextField(
              controller: savedController,
              decoration: InputDecoration(labelText: t('savedAmount'), prefixIcon: const Icon(Icons.account_balance_wallet_rounded)),
              keyboardType: TextInputType.number
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(t('cancel'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF38BDF8), foregroundColor: Colors.white),
            onPressed: () async {
              final title = titleController.text.trim();
              final targetText = targetController.text.trim().replaceAll(',', '');
              final savedText = savedController.text.trim().replaceAll(',', '');

              if (title.isEmpty || targetText.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(t('validTitleAmount')),
                    backgroundColor: const Color(0xFFFF5252),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }

              final double target = double.tryParse(targetText) ?? 0.0;
              final double saved = double.tryParse(savedText) ?? 0.0;

              if (target <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Target amount must be greater than 0"),
                    backgroundColor: Color(0xFFFF5252),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }

              final String id = goal is Goal ? goal.id : (goal?['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString());

              final newGoal = Goal(
                id: id,
                title: title,
                targetAmount: target,
                savedAmount: saved,
                deadline: (goal is Goal) ? goal.deadline : DateTime.now(),
              );

              try {
                final box = Hive.box('goals');
                if (index == null) await box.add(newGoal);
                else await box.putAt(index, newGoal);

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(t('recordSaved')),
                      backgroundColor: const Color(0xFF38BDF8),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                try {
                  final box = await Hive.openBox('goals');
                  if (index == null) await box.add(newGoal);
                  else await box.putAt(index, newGoal);
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(t('recordSaved')),
                        backgroundColor: const Color(0xFF38BDF8),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (_) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Connection lost. Please refresh (F5)."), backgroundColor: Colors.red),
                    );
                  }
                }
              }
            },
            child: Text(t('saveGoal')),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(t('savingsGoals'))),
      body: ValueListenableBuilder(
        valueListenable: Hive.box('goals').listenable(),
        builder: (context, Box box, _) {
          if (box.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.stars_rounded,
                    size: 80,
                    color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    t('noRecords'),
                    style: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black38,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: box.length,
            itemBuilder: (context, index) {
              try {
                final dynamic item = box.getAt(index);
                if (item == null) return const SizedBox.shrink();

                final String title = (item is Goal ? item.title : item['title'])?.toString() ?? 'Unnamed Goal';
                final double target = (item is Goal ? item.targetAmount : (item['target'] as num?))?.toDouble() ?? 0.0;
                final double saved = (item is Goal ? item.savedAmount : (item['saved'] as num?))?.toDouble() ?? 0.0;

                final double percent = (target > 0) ? (saved / target).clamp(0.0, 1.0) : 0.0;
                final String usedText = t('usedOf');
                final String displayUsed = usedText.contains(' ') ? usedText.split(' ')[0] : usedText;

                return Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.all(20.0),
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
                          Expanded(child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? Colors.white : const Color(0xFF334155)), overflow: TextOverflow.ellipsis)),
                          Text("${(percent * 100).toInt()}%", style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF38BDF8))),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: percent,
                        backgroundColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                        color: const Color(0xFF38BDF8),
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("$currency $saved $displayUsed", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          Text("${t('targetAmount')}: $currency $target", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87)),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () async {
                              final bool? confirm = await showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  title: Text(t('deleteRecord')),
                                  content: Text(t('confirmDelete')),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t('cancel'))),
                                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t('delete'), style: const TextStyle(color: Colors.red))),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                try {
                                  await Hive.box('goals').deleteAt(index);
                                  setState(() {});
                                } catch (e) {
                                  try {
                                    await Hive.openBox('goals');
                                    await Hive.box('goals').deleteAt(index);
                                    setState(() {});
                                  } catch (_) {}
                                }
                              }
                            },
                            child: Text(t('delete'), style: const TextStyle(color: Color(0xFFF43F5E))),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF38BDF8).withOpacity(0.1),
                              foregroundColor: const Color(0xFF38BDF8),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => _showGoalDialog(goal: item, index: index),
                            child: Text(t('edit')),
                          ),
                        ],
                      )
                    ],
                  ),
                );
              } catch (e) {
                return Card(child: ListTile(title: const Text("Error loading goal record"), subtitle: Text(e.toString()), trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () => Hive.box('goals').deleteAt(index))));
              }
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showGoalDialog(),
        backgroundColor: const Color(0xFF38BDF8),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
