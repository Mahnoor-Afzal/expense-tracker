import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../services/translation_service.dart';
import '../models/debt.dart';

class DebtTrackerPage extends StatefulWidget {
  const DebtTrackerPage({super.key});

  @override
  State<DebtTrackerPage> createState() => _DebtTrackerPageState();
}

class _DebtTrackerPageState extends State<DebtTrackerPage> {
  String get currentLang {
    try {
      return Hive.box('settings').get('language', defaultValue: 'English');
    } catch (_) {
      return 'English';
    }
  }

  String get currency {
    try {
      return Hive.box('settings').get('currency', defaultValue: 'Rs.');
    } catch (_) {
      return 'Rs.';
    }
  }

  String t(String key) => TranslationService.t(key, currentLang);

  void _showAddDebtDialog({dynamic debt, int? index}) {
    final String initialName = debt is Debt ? debt.personName : (debt?['name'] ?? '');
    final String initialAmount = debt is Debt ? debt.amount.toString() : (debt?['amount']?.toString() ?? '');
    bool isIOwe = debt is Debt ? debt.isIOweThem : (debt?['isIOwe'] ?? true);

    final nameController = TextEditingController(text: initialName);
    final amountController = TextEditingController(text: initialAmount);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(debt == null ? t('debtTracker') : t('editRecord')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController, 
                decoration: InputDecoration(labelText: t('personName'), prefixIcon: const Icon(Icons.person_outline))
              ),
              const SizedBox(height: 10),
              TextField(
                controller: amountController, 
                decoration: InputDecoration(labelText: t('amount'), prefixIcon: const Icon(Icons.calculate_outlined)), 
                keyboardType: TextInputType.number
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setDialogState(() => isIOwe = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isIOwe ? Colors.redAccent : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(child: Text(t('iOweThem'), style: TextStyle(color: isIOwe ? Colors.white : Colors.black54, fontWeight: FontWeight.bold, fontSize: 12))),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setDialogState(() => isIOwe = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !isIOwe ? Colors.green : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(child: Text(t('theyOweMe'), style: TextStyle(color: !isIOwe ? Colors.white : Colors.black54, fontWeight: FontWeight.bold, fontSize: 12))),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(t('cancel'))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF38BDF8), foregroundColor: Colors.white),
              onPressed: () async {
                if (nameController.text.isEmpty || amountController.text.isEmpty) return;
                
                final String id = debt is Debt ? debt.id : (debt?['id'] ?? DateTime.now().millisecondsSinceEpoch.toString());
                final double amount = double.tryParse(amountController.text) ?? 0.0;
                final bool isSettled = debt is Debt ? debt.isSettled : (debt?['isSettled'] ?? false);
                final DateTime date = debt is Debt ? debt.date : (debt?['date'] != null ? DateTime.parse(debt['date']) : DateTime.now());

                final newDebt = Debt(
                  id: id,
                  personName: nameController.text,
                  amount: amount,
                  isIOweThem: isIOwe,
                  date: date,
                  isSettled: isSettled,
                );

                try {
                  final box = Hive.box('debts');
                  if (index == null) await box.add(newDebt);
                  else await box.putAt(index, newDebt);
                  if (mounted) {
                    Navigator.pop(context);
                    setState(() {});
                  }
                } catch (e) {
                  try {
                    final box = await Hive.openBox('debts');
                    if (index == null) await box.add(newDebt);
                    else await box.putAt(index, newDebt);
                    if (mounted) {
                      Navigator.pop(context);
                      setState(() {});
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
              child: Text(t('add')),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t('debtTracker'))),
      body: ValueListenableBuilder(
        valueListenable: Hive.box('debts').listenable(),
        builder: (context, Box box, _) {
          double totalToPay = 0;
          double totalToReceive = 0;
          
          final list = box.values.toList();
          for (var item in list) {
            final bool isSettled = item is Debt ? item.isSettled : (item?['isSettled'] ?? false);
            final bool isIOwe = item is Debt ? item.isIOweThem : (item?['isIOwe'] ?? true);
            final double amount = item is Debt ? item.amount : (item?['amount'] as num? ?? 0.0).toDouble();

            if (!isSettled) {
              if (isIOwe) totalToPay += amount;
              else totalToReceive += amount;
            }
          }

          return Column(
            children: [
              // Summary Header
              Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF334155), Color(0xFF1E293B)]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(t('toPay').toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                          Text("$currency ${totalToPay.toStringAsFixed(0)}", style: const TextStyle(color: Color(0xFFFF5252), fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 30, color: Colors.white10),
                    Expanded(
                      child: Column(
                        children: [
                          Text(t('toReceive').toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                          Text("$currency ${totalToReceive.toStringAsFixed(0)}", style: const TextStyle(color: Color(0xFF00FF88), fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: box.isEmpty 
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.handshake_outlined,
                          size: 80,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.black.withOpacity(0.05),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          t('noRecords'),
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white38 : Colors.black38,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    itemCount: box.length,
                    itemBuilder: (context, index) {
                      final dynamic item = box.getAt(index);
                      
                      final String name = item is Debt ? item.personName : (item?['name'] ?? '');
                      final double amount = item is Debt ? item.amount : (item?['amount'] as num? ?? 0.0).toDouble();
                      final bool isIOwe = item is Debt ? item.isIOweThem : (item?['isIOwe'] ?? true);
                      final bool isSettled = item is Debt ? item.isSettled : (item?['isSettled'] ?? false);
                      final DateTime date = item is Debt ? item.date : (item?['date'] != null ? DateTime.tryParse(item['date'].toString()) ?? DateTime.now() : DateTime.now());

                      return Opacity(
                        opacity: isSettled ? 0.5 : 1.0,
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isSettled ? Colors.grey.withOpacity(0.1) : (isIOwe ? const Color(0xFFFF5252).withOpacity(0.1) : const Color(0xFF00FF88).withOpacity(0.1)),
                              child: Icon(
                                isSettled ? Icons.check_circle : (isIOwe ? Icons.arrow_downward : Icons.arrow_upward), 
                                color: isSettled ? Colors.grey : (isIOwe ? const Color(0xFFFF5252) : const Color(0xFF00FF88))
                              ),
                            ),
                            title: Text(name, style: TextStyle(fontWeight: FontWeight.bold, decoration: isSettled ? TextDecoration.lineThrough : null)),
                            subtitle: Text(isSettled ? t('settled') : (isIOwe ? t('iOweThem') : t('theyOweMe'))),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text("$currency $amount", style: TextStyle(fontWeight: FontWeight.bold, color: isSettled ? Colors.grey : (isIOwe ? const Color(0xFFFF5252) : const Color(0xFF00FF88)), fontSize: 16)),
                                Text(DateFormat('dd MMM').format(date), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                              ],
                            ),
                            onTap: () async {
                              if (!isSettled) {
                                showModalBottomSheet(
                                  context: context,
                                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                                  builder: (c) => Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(height: 10),
                                      ListTile(
                                        leading: const Icon(Icons.check_circle_outline, color: Colors.green),
                                        title: Text(t('settled')), // Changed from t('useAmount')
                                        onTap: () async {
                                          try {
                                            final box = Hive.box('debts');
                                            if (item is Debt) {
                                              item.isSettled = true;
                                              await box.putAt(index, item);
                                            } else if (item != null) {
                                              final newDebt = Debt(
                                                id: (item['id'] ?? DateTime.now().millisecondsSinceEpoch.toString()).toString(),
                                                personName: (item['name'] ?? '').toString(),
                                                amount: (item['amount'] as num? ?? 0.0).toDouble(),
                                                isIOweThem: item['isIOwe'] ?? true,
                                                date: item['date'] != null ? DateTime.tryParse(item['date'].toString()) ?? DateTime.now() : DateTime.now(),
                                                isSettled: true,
                                              );
                                              await box.putAt(index, newDebt);
                                            }
                                            if (c.mounted) Navigator.pop(c);
                                            setState(() {});
                                          } catch (e) {
                                            try {
                                              final box = await Hive.openBox('debts');
                                              if (item is Debt) {
                                                item.isSettled = true;
                                                await box.putAt(index, item);
                                              }
                                              if (c.mounted) Navigator.pop(c);
                                              setState(() {});
                                            } catch (_) {}
                                          }
                                        },
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.edit_outlined),
                                        title: Text(t('editRecord')),
                                        onTap: () {
                                          Navigator.pop(c);
                                          _showAddDebtDialog(debt: item, index: index);
                                        },
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.delete_outline, color: Colors.red),
                                        title: Text(t('deleteRecord')),
                                        onTap: () async {
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
                                              await Hive.box('debts').deleteAt(index);
                                              if (c.mounted) Navigator.pop(c);
                                              setState(() {});
                                            } catch (e) {
                                              try {
                                                await Hive.openBox('debts');
                                                await Hive.box('debts').deleteAt(index);
                                                if (c.mounted) Navigator.pop(c);
                                                setState(() {});
                                              } catch (_) {}
                                            }
                                          }
                                        },
                                      ),
                                      const SizedBox(height: 20),
                                    ],
                                  ),
                                );
                              } else {
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
                                    await Hive.box('debts').deleteAt(index);
                                    setState(() {});
                                  } catch (e) {
                                    try {
                                      await Hive.openBox('debts');
                                      await Hive.box('debts').deleteAt(index);
                                      setState(() {});
                                    } catch (_) {}
                                  }
                                }
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDebtDialog(),
        backgroundColor: const Color(0xFF38BDF8),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
