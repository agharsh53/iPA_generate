class TransactionModel {
  final double amount;
  final String dataType;
  final DateTime dateTime;
  final int categoryId;

  TransactionModel({
    required this.amount,
    required this.dataType,
    required this.dateTime,
    required this.categoryId,
  });
}
