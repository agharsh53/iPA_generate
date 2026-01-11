import 'category_model.dart';

class DataItem {
  final String? id;
  final Category category;
  final double amount;
  final String note;
  final DateTime dateTime;
  final String dataType;

  DataItem({
    this.id,
    required this.category,
    required this.amount,
    required this.note,
    required this.dateTime,
    required this.dataType,
  });

  Map<String, dynamic> toSupabase(String userId) {
    return {
      'user_id': userId,
      'category_id': category.id,
      'amount': amount,
      'note': note,
      'transaction_time': dateTime.toIso8601String(),
      'data_type': dataType,
    };
  }
}
