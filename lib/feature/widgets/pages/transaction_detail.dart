import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/category_model.dart';
import '../../../models/data_item.dart';
import '../../../services/transaction_service.dart';
import 'edit_expense_screen.dart';

class TransactionDetail extends StatefulWidget {
  final String title;
  final double amount;
  final DateTime date;
  final IconData categoryIcon;
  final Color categoryColor;
  final String note;
  final int categoryId;
  final String dataType;
  final String itemId;

  const TransactionDetail({
    super.key,
    required this.title,
    required this.amount,
    required this.date,
    required this.categoryIcon,
    required this.categoryColor,
    required this.note,
    required this.categoryId,
    required this.dataType,
    required this.itemId,
  });

  @override
  State<TransactionDetail> createState() => _TransactionDetailState();
}

class _TransactionDetailState extends State<TransactionDetail> {
  final TransactionService _transactionService = TransactionService();

  bool get _isExpense => widget.dataType == 'expense';


  CategoryType get _categoryType {
    if (widget.dataType == 'expense') return CategoryType.expense;
    if (widget.dataType == 'income') return CategoryType.income;
    return CategoryType.loan;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_left, size: 40),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Transactions',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _onEditPressed,
            child: const Text(
              'Edit',
              style: TextStyle(
                fontSize: 18,
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 16),
          _buildHeader(),
          const SizedBox(height: 32),
          _buildCategory(),
          const SizedBox(height: 24),
          _buildNote(),
          const Spacer(),
          _buildDeleteButton(),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _buildHeader() {
    return Center(
      child: Column(children: [
        Text(
          DateFormat('EEE, dd MMM').format(widget.date),
          style: const TextStyle(fontSize: 18, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Text(
          (_isExpense ? '-' : '') +
              NumberFormat.currency(
                locale: 'en_IN',
                symbol: '₹',
                decimalDigits: 0,
              ).format(widget.amount),
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: _isExpense ? Colors.red : Colors.green,
          ),
        ),
      ]),
    );
  }

  Widget _buildCategory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Category',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.categoryColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(widget.categoryIcon,
                color: widget.categoryColor, size: 24),
          ),
          const SizedBox(width: 12),
          Text(widget.title, style: const TextStyle(fontSize: 16)),
        ])
      ],
    );
  }

  Widget _buildNote() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Note',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(widget.note.isEmpty ? '-' : widget.note),
      ],
    );
  }

  Widget _buildDeleteButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red),
          foregroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: _onDeletePressed,
        child:
        const Text('Delete Transaction', style: TextStyle(fontSize: 16)),
      ),
    );
  }

  /// EDIT
  Future<void> _onEditPressed() async {
    final category = Category(
      id: widget.categoryId,
      name: widget.title,
      icon: widget.categoryIcon,
      color: widget.categoryColor,
      categoryType: _categoryType,
    );

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditExpenseScreen(
          dataItem: DataItem(
            id: widget.itemId,
            amount: widget.amount,
            note: widget.note,
            dateTime: widget.date,
            category: category,
            dataType: widget.dataType,
          ),
        ),
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction updated')),
      );
      Navigator.pop(context, true); // 🔥 IMPORTANT
    }
  }

  /// DELETE
  Future<void> _onDeletePressed() async {
    await _transactionService.deleteTransaction(widget.itemId);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaction deleted')),
    );

    Navigator.pop(context, true); // 🔥 IMPORTANT
  }
}
