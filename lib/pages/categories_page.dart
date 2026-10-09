import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:expense_tracker/services/utils.dart';
import '../services/translation_service.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final categoryController = TextEditingController();

  String get currentLang {
    try {
      return Hive.box('settings').get('language', defaultValue: 'English');
    } catch (_) {
      return 'English';
    }
  }

  @override
  void dispose() {
    categoryController.dispose();
    super.dispose();
  }

  void addCategory() {
    categoryController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(TranslationService.t('newCategory', currentLang), style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold)),
        content: TextField(
          controller: categoryController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: TranslationService.t('categoryName', currentLang),
          ),
          style: const TextStyle(color: Color(0xFF38BDF8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(TranslationService.t('cancel', currentLang), style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF38BDF8),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              if (categoryController.text.trim().isNotEmpty) {
                final categoryName = categoryController.text.trim();
                try {
                  await Hive.box('categories').add(categoryName);
                  if (mounted) {
                    categoryController.clear();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(TranslationService.t('categoryAdded', currentLang)),
                        backgroundColor: const Color(0xFF38BDF8),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                } catch (e) {
                  try {
                    final box = await Hive.openBox('categories');
                    await box.add(categoryName);
                    if (mounted) {
                      categoryController.clear();
                      Navigator.pop(context);
                      setState(() {});
                    }
                  } catch (_) {}
                }
              }
            },
            child: Text(TranslationService.t('add', currentLang), style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box('settings').listenable(keys: ['language']),
      builder: (context, Box settings, _) {
        final lang = settings.get('language', defaultValue: 'English');
        
        return Scaffold(
          appBar: AppBar(
            title: Text(TranslationService.t('manageCategories', lang)),
            elevation: 0,
            actions: [
              IconButton(
                onPressed: addCategory,
                icon: const Icon(Icons.add_box_rounded, size: 28),
              ),
              const SizedBox(width: 10),
            ],
          ),
          body: ValueListenableBuilder(
            valueListenable: Hive.box('categories').listenable(),
            builder: (context, Box box, _) {
              if (box.isEmpty) {
                return Center(
                  child: Text(TranslationService.t('noCategories', lang), style: const TextStyle(color: Colors.black38, fontWeight: FontWeight.bold)),
                );
              }
              return Padding(
                padding: const EdgeInsets.all(10.0),
                child: ListView.builder(
                  itemCount: box.length,
                  itemBuilder: (context, index) {
                    final category = box.getAt(index);
                    return Card(
                      color: Theme.of(context).cardColor,
                      elevation: 4,
                      shadowColor: Colors.black12,
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF38BDF8).withOpacity(0.1),
                          child: Icon(AppUtils.getCategoryIcon(category ?? ""), color: const Color(0xFF38BDF8)),
                        ),
                        title: Text(
                          category ?? "",
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF334155),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Color(0xFFFF5252)),
                          onPressed: () {
                            // Confirm Delete
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: Theme.of(context).cardColor,
                                title: Text(TranslationService.t('deleteCategory', lang), style: const TextStyle(color: Color(0xFFFF5252), fontWeight: FontWeight.bold)),
                                content: Text(TranslationService.t('confirmDeleteCategory', lang)),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: Text(TranslationService.t('cancel', lang), style: const TextStyle(color: Colors.grey))),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFF5252), 
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    onPressed: () async {
                                      try {
                                        await Hive.box('categories').deleteAt(index);
                                        if (mounted) {
                                          Navigator.pop(ctx);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(TranslationService.t('categoryDeleted', lang)),
                                              backgroundColor: const Color(0xFFFF5252),
                                              behavior: SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        try {
                                          final box = await Hive.openBox('categories');
                                          await box.deleteAt(index);
                                          if (mounted) {
                                            Navigator.pop(ctx);
                                            setState(() {});
                                          }
                                        } catch (_) {}
                                      }
                                    },
                                    child: Text(TranslationService.t('delete', lang).toUpperCase()),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}

