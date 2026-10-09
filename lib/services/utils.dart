import 'package:flutter/material.dart';

class AppUtils {
  static IconData getCategoryIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'food':
      case 'dining':
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'travel':
      case 'transport':
      case 'fuel':
        return Icons.directions_car_rounded;
      case 'bills':
      case 'electricity':
      case 'water':
      case 'internet':
        return Icons.receipt_long_rounded;
      case 'shopping':
      case 'grocery':
      case 'groceries':
        return Icons.shopping_bag_rounded;
      case 'salary':
      case 'income':
      case 'bonus':
        return Icons.payments_rounded;
      case 'health':
      case 'medical':
      case 'pharmacy':
        return Icons.health_and_safety_rounded;
      case 'education':
      case 'books':
      case 'school':
        return Icons.school_rounded;
      case 'entertainment':
      case 'movies':
      case 'games':
        return Icons.movie_filter_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  static Color getCategoryColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'food': return const Color(0xFF38BDF8);
      case 'travel': return const Color(0xFF00FF88);
      case 'bills': return const Color(0xFFFF5252);
      case 'shopping': return const Color(0xFFFBBF24);
      case 'salary': return const Color(0xFF818CF8);
      case 'other': return const Color(0xFFF472B6);
      default:
        final List<Color> colors = [
          const Color(0xFF38BDF8), const Color(0xFF00FF88), const Color(0xFFFF5252),
          const Color(0xFFFBBF24), const Color(0xFF818CF8), const Color(0xFFF472B6)
        ];
        return colors[cat.hashCode.abs() % colors.length];
    }
  }
}
