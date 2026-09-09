import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'Actividata';
  static const int autoLockTimeoutSeconds = 120; // 2 minutes auto-lock timeout
  static const int pinLength = 6;

  // Predefined Finance Categories
  static const List<String> incomeCategories = [
    'Salary',
    'Freelance',
    'Investments',
    'Gift',
    'Refund',
    'Other Income',
  ];

  static const List<String> expenseCategories = [
    'Food & Dining',
    'Groceries',
    'Shopping',
    'Transportation',
    'Utilities & Bills',
    'Housing',
    'Entertainment',
    'Healthcare',
    'Education',
    'Personal Care',
    'Travel',
    'Other Expense',
  ];

  // Predefined Task Categories
  static const List<String> taskCategories = [
    'General',
    'Work',
    'Personal',
    'Shopping',
    'Finance',
    'Study',
    'Health',
    'Home',
  ];

  // Map category to icon (Pure Vector Icons - Zero Emojis)
  static IconData getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'salary':
        return Icons.account_balance_wallet_outlined;
      case 'income':
      case 'other income':
        return Icons.arrow_downward_rounded;
      case 'freelance':
      case 'work':
        return Icons.work_outline_rounded;
      case 'investments':
        return Icons.pie_chart_outline_rounded;
      case 'gift':
        return Icons.card_giftcard_outlined;
      case 'refund':
        return Icons.replay_rounded;
      case 'food & dining':
        return Icons.restaurant_outlined;
      case 'groceries':
        return Icons.local_grocery_store_outlined;
      case 'shopping':
        return Icons.shopping_bag_outlined;
      case 'transportation':
        return Icons.directions_car_outlined;
      case 'travel':
        return Icons.flight_takeoff_rounded;
      case 'utilities & bills':
        return Icons.receipt_long_outlined;
      case 'housing':
      case 'home':
        return Icons.home_outlined;
      case 'entertainment':
        return Icons.movie_outlined;
      case 'healthcare':
      case 'health':
        return Icons.medical_services_outlined;
      case 'education':
      case 'study':
        return Icons.school_outlined;
      case 'personal care':
        return Icons.spa_outlined;
      case 'other expense':
        return Icons.arrow_upward_rounded;
      default:
        return Icons.category_outlined;
    }
  }
}

