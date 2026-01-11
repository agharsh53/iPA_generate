import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../models/category_model.dart';
import '../models/data_item.dart';


class TransactionService {


  /// INSERT TRANSACTION
  Future<bool> insertTransaction(DataItem item) async {
    final user = supabase.auth.currentUser;
    if (user == null) return false;

    try {
      await supabase
          .from('transactions')
          .insert({
        'user_id': user.id,
        'category_id': item.category.id,
        'amount': item.amount,
        'note': item.note,
        'transaction_time': item.dateTime.toIso8601String(),
        'data_type': item.dataType,
      })
          .select(); // 👈 IMPORTANT

      return true;
    } catch (e) {
      debugPrint('Insert transaction error: $e');
      return false;
    }
  }

  /// FETCH ALL TRANSACTIONS (USED IN HOME SCREEN)
  Future<List<DataItem>> fetchAllTransactions(
      List<Category> categories) async {

    final user = supabase.auth.currentUser;
    if (user == null) return [];

    final response = await supabase
        .from('transactions')
        .select()
        .eq('user_id', user.id)
        .order('transaction_time', ascending: false);

    final List data = response as List;

    return data.map((row) {
      final category = categories.firstWhere(
            (c) => c.id == row['category_id'],
        orElse: () => Category(
          id: row['category_id'],
          name: 'Unknown',
          icon: Icons.category,
          color: Colors.grey,
          categoryType: CategoryType.expense,
        ),
      );

      return DataItem(
        id: row['id'],
        category: category,
        amount: (row['amount'] as num).toDouble(),
        note: row['note'] ?? '',
        dateTime: DateTime.parse(row['transaction_time']),
        dataType: row['data_type'],
      );
    }).toList();
  }


  /// DELETE TRANSACTION
  Future<void> deleteTransaction(String id) async {
    await supabase.from('transactions').delete().eq('id', id);
  }

  /// UPDATE TRANSACTION
  Future<bool> updateTransaction(DataItem item) async {
    final user = supabase.auth.currentUser;
    if (user == null) return false;

    try {
      await supabase
          .from('transactions')
          .update({
        'amount': item.amount,
        'note': item.note,
        'transaction_time': item.dateTime.toIso8601String(),
        'category_id': item.category.id,
        'data_type': item.dataType,
      })
          .eq('id', item.id.toString())
          .eq('user_id', user.id);

      return true;
    } catch (e) {
      debugPrint('Update transaction error: $e');
      return false;
    }
  }


  // ---------------- FETCH CATEGORIES ----------------
  Future<List<Category>> fetchCategories(CategoryType type) async {
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) {
      throw Exception('User not logged in');
    }

    final response = await supabase
        .from('categories')
        .select()
        .eq('category_type', type.name)
        .order('id');

    final List data = response as List;

    return data.map<Category>((json) {
      return Category(
        id: json['id'],
        name: json['name'],
        icon: Category.fromSupabase(json).icon,
        color: Color(json['color']),
        categoryType: CategoryType.values.firstWhere(
              (e) => e.name == json['category_type'],
        ),
      );
    }).toList();
  }
}
