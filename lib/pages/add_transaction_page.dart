import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:function_tree/function_tree.dart';
import '../models/transaction.dart';
import '../services/translation_service.dart';

class AddTransactionPage extends StatefulWidget {
  final Transaction? transaction;

  const AddTransactionPage({super.key, this.transaction});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final titleController = TextEditingController();
  final amountController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  
  String? selectedCategory;
  bool isExpense = true;

  final List<String> currencies = ['Rs.', r'$', '€', '£', '¥', 'PKR', 'INR'];
  String? selectedCurrency;

  String get currentLang {
    try {
      return Hive.box('settings').get('language', defaultValue: 'English');
    } catch (_) {
      return 'English';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    final settingsBox = Hive.box('settings');
    final categoryBox = Hive.box('categories');
    
    selectedCurrency = settingsBox.get('currency', defaultValue: 'Rs.');
    
    if (widget.transaction != null) {
      titleController.text = widget.transaction!.title;
      amountController.text = widget.transaction!.amount.toString();
      selectedDate = widget.transaction!.date;
      selectedTime = TimeOfDay.fromDateTime(widget.transaction!.date);
      selectedCategory = widget.transaction!.category;
      isExpense = widget.transaction!.isExpense;
    } else if (categoryBox.isNotEmpty) {
      selectedCategory = categoryBox.getAt(0);
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(context: context, initialTime: selectedTime);
    if (picked != null) setState(() => selectedTime = picked);
  }

  Future<void> saveTransaction() async {
    String amountText = amountController.text.trim().replaceAll(',', '');
    
    // Simple Calculator Logic: Solve math expressions
    double? amount;
    try {
      // function_tree library will parse 100+50-10 etc.
      num evaluated = amountText.interpret();
      amount = evaluated.toDouble();
    } catch (e) {
      amount = double.tryParse(amountText);
    }
    
    if (titleController.text.isEmpty || amount == null || amount <= 0 || selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(TranslationService.t('validTitleAmount', currentLang)),
          backgroundColor: const Color(0xFFFF5252),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final finalDateTime = DateTime(
      selectedDate.year, selectedDate.month, selectedDate.day,
      selectedTime.hour, selectedTime.minute,
    );

    try {
      // Use existing box instance
      final box = Hive.box('transactions');
      final sBox = Hive.box('settings');
          
      final tx = Transaction(
        id: widget.transaction?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: titleController.text.trim(),
        amount: amount,
        date: finalDateTime,
        category: selectedCategory!,
        isExpense: isExpense,
      );

      // Web safe saving
      if (widget.transaction != null) {
        await box.put(widget.transaction!.key, tx);
      } else {
        await box.add(tx);
      }

      await sBox.put('currency', selectedCurrency);
      await sBox.put('selectedMonth', DateTime(finalDateTime.year, finalDateTime.month).toIso8601String());

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(TranslationService.t('recordSaved', currentLang)),
            backgroundColor: const Color(0xFF38BDF8),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print("SAVE ERROR: $e");
      // If error occurs, try to reopen box and save (Web fix)
      try {
        await Hive.openBox('transactions');
        await saveTransaction(); // Recursive call once
      } catch (retryError) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Connection lost. Please refresh the browser (F5)."),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(TranslationService.t('deleteRecord', currentLang), style: const TextStyle(color: Color(0xFFFF5252))),
        content: Text(TranslationService.t('confirmDelete', currentLang)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(TranslationService.t('cancel', currentLang))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5252)),
            onPressed: () async {
              if (widget.transaction != null) {
                await widget.transaction!.delete();
                if (mounted) {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                }
              }
            },
            child: Text(TranslationService.t('delete', currentLang)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transaction == null ? TranslationService.t('addRecord', currentLang) : TranslationService.t('editRecord', currentLang)),
        actions: widget.transaction != null ? [IconButton(icon: const Icon(Icons.delete_forever, color: Color(0xFFFF5252)), onPressed: _confirmDelete)] : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildTypeToggle(),
            const SizedBox(height: 25),
            TextField(controller: titleController, decoration: InputDecoration(labelText: TranslationService.t('whatWasThisFor', currentLang), prefixIcon: const Icon(Icons.edit))),
            const SizedBox(height: 20),
            _buildAmountRow(),
            const SizedBox(height: 20),
            _buildCategoryDropdown(),
            const SizedBox(height: 20),
            _buildDateTimePickers(),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF38BDF8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: saveTransaction,
                child: Text(widget.transaction == null ? TranslationService.t('saveRecord', currentLang) : TranslationService.t('updateRecord', currentLang), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeToggle() {
    return Container(
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Expanded(child: _buildTypeBtn(TranslationService.t('expenses', currentLang), isExpense, const Color(0xFFFF5252), () => setState(() => isExpense = true))),
          Expanded(child: _buildTypeBtn(TranslationService.t('income', currentLang), !isExpense, const Color(0xFF00FF88), () => setState(() => isExpense = false))),
        ],
      ),
    );
  }

  Widget _buildTypeBtn(String label, bool active, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: active ? color : Colors.transparent, borderRadius: BorderRadius.circular(12)),
        child: Center(child: Text(label.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: active ? Colors.white : Colors.grey))),
      ),
    );
  }

  Widget _buildAmountRow() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<String>(
            value: currencies.contains(selectedCurrency) ? selectedCurrency : currencies[0],
            items: currencies.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(color: Color(0xFF38BDF8))))).toList(),
            onChanged: (v) => setState(() => selectedCurrency = v),
            decoration: InputDecoration(labelText: TranslationService.t('currency', currentLang)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 3,
          child: TextField(
            controller: amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.+\-*/]')),
            ],
            decoration: InputDecoration(
              labelText: TranslationService.t('amount', currentLang),
              prefixIcon: const Icon(Icons.money, color: Color(0xFF38BDF8)),
              suffixIcon: IconButton(
                icon: const Icon(Icons.calculate, color: Color(0xFF38BDF8)),
                onPressed: () {
                  try {
                    String text = amountController.text.trim();
                    if (text.isNotEmpty) {
                      num val = text.interpret();
                      amountController.text = val.toString();
                    }
                  } catch (e) {
                    // Invalid expression
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return ValueListenableBuilder(
      valueListenable: Hive.box('categories').listenable(),
      builder: (context, Box box, _) {
        final categories = box.values.toList();
        if (selectedCategory != null && !categories.contains(selectedCategory)) categories.add(selectedCategory!);
        return DropdownButtonFormField<String>(
          value: selectedCategory,
          items: categories.map((c) => DropdownMenuItem(value: c.toString(), child: Text(c.toString()))).toList(),
          onChanged: (v) => setState(() => selectedCategory = v),
          decoration: InputDecoration(labelText: TranslationService.t('categories', currentLang), prefixIcon: const Icon(Icons.category, color: Color(0xFF38BDF8))),
        );
      },
    );
  }

  Widget _buildDateTimePickers() {
    return Row(
      children: [
        Expanded(child: InkWell(onTap: _pickDate, child: InputDecorator(decoration: InputDecoration(labelText: TranslationService.t('date', currentLang)), child: Text(DateFormat('dd MMM yyyy').format(selectedDate))))),
        const SizedBox(width: 15),
        Expanded(child: InkWell(onTap: _pickTime, child: InputDecorator(decoration: InputDecoration(labelText: TranslationService.t('time', currentLang)), child: Text(selectedTime.format(context))))),
      ],
    );
  }
}
