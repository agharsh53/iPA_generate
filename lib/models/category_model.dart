import 'package:flutter/material.dart';

enum CategoryType { expense, income, loan }

class Category {
  final int id;
  final String name;
  final IconData icon;
  final Color color;
  final CategoryType categoryType;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.categoryType,
  });

  factory Category.fromSupabase(Map<String, dynamic> map) {
    return Category(
      id: map['id'] ,
      name: map['name'],
      icon: _iconFromString(map['icon']),
      color: Color(map['color']),
      categoryType: CategoryType.values.firstWhere(
            (e) => e.name == map['category_type'],
      ),
    );
  }

  static IconData _iconFromString(String name) {
    switch (name) {
      case 'restaurant': return Icons.restaurant;
      case 'people': return Icons.people;
      case 'directions_car': return Icons.directions_car;
      case 'shopping_bag': return Icons.shopping_bag;
      case 'shopping_cart': return Icons.shopping_cart;
      case 'book_outlined': return Icons.book_outlined;
      case 'receipt': return Icons.receipt;
      case 'home': return Icons.home;
      case 'local_hospital': return Icons.local_hospital;
      case 'show_chart': return Icons.show_chart;
      case 'card_giftcard': return Icons.card_giftcard;
      case 'attach_money': return Icons.attach_money;
      case 'trending_up': return Icons.trending_up;
      case 'business': return Icons.business;
      case 'account_balance': return Icons.account_balance;
      case 'monetization_on': return Icons.monetization_on;
      case 'trending_down': return Icons.trending_down;
      default: return Icons.category;
    }
  }
}
