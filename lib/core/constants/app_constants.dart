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

  // Map category to icon
  static IconData getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'salary':
      case 'income':
      case 'other income':
        return Icons.attach_money_rounded;
      case 'freelance':
      case 'work':
        return Icons.work_outline_rounded;
      case 'investments':
        return Icons.trending_up_rounded;
      case 'food & dining':
      case 'groceries':
        return Icons.restaurant_rounded;
      case 'shopping':
        return Icons.shopping_bag_outlined;
      case 'transportation':
      case 'travel':
        return Icons.directions_car_rounded;
      case 'utilities & bills':
      case 'housing':
      case 'home':
        return Icons.home_work_outlined;
      case 'entertainment':
        return Icons.movie_outlined;
      case 'healthcare':
      case 'health':
        return Icons.medical_services_outlined;
      case 'education':
      case 'study':
        return Icons.school_outlined;
      default:
        return Icons.category_outlined;
    }
  }
}

