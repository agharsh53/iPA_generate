import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../common/color/colors.dart';
import '../../../common/widgets/button_row.dart';
import '../../../models/category_model.dart';
import '../../../models/data_item.dart';
import '../../../provider/transaction_provider.dart';


class EditExpenseScreen extends StatefulWidget {
  final DataItem dataItem;

  const EditExpenseScreen({super.key, required this.dataItem});

  @override
  _EditExpenseScreenState createState() => _EditExpenseScreenState();
}

class _EditExpenseScreenState extends State<EditExpenseScreen> {
  final TextEditingController amountController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  Category? _selectedCategory;
  String _selectedButton = 'Expense';


  @override
  void initState() {
    super.initState();

    final item = widget.dataItem;
    print("Editing item received in EditExpenseScreen: ${item}"); // DEBUG

    amountController.text = item.amount.toString();
    noteController.text = item.note ?? '';
    _selectedDate = item.dateTime;
    _selectedTime = TimeOfDay.fromDateTime(item.dateTime);
    _selectedButton = item.dataType == 'expense'
        ? 'Expense'
        : item.dataType == 'income'
        ? 'Income'
        : 'Loan';
    _selectedCategory = item.category;
  }

  CategoryType _getCategoryType(String buttonText) {
    switch (buttonText.toLowerCase()) {
      case 'expense':
        return CategoryType.expense;
      case 'income':
        return CategoryType.income;
      case 'loan':
        return CategoryType.loan;
      default:
        return CategoryType.expense;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _saveDataItem() async {
    if (_selectedCategory == null || amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Category and amount are required")),
      );
      return;
    }

    final updatedDataItem = DataItem(
      id: widget.dataItem.id,
      category: _selectedCategory!,
      amount: double.tryParse(amountController.text) ?? 0,
      note: noteController.text,
      dateTime: DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      ),
      dataType: _selectedCategory!.categoryType.name,
    );

    print("DataItem object being updated: ${updatedDataItem}"); // DEBUG

    final success = await context.read<TransactionProvider>().updateTransaction(updatedDataItem);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
        Text(success ? 'Transaction updated' : 'Update failed'),
      ),
    );
    Navigator.pop(context,success);
  }

  Widget _buildCategoryGrid() {
    final categories =
    context.watch<TransactionProvider>().categoriesForType(_selectedButton);

    if (categories.isEmpty) {
      return const Text('No categories found');
    }
    return  Wrap(
            alignment: WrapAlignment.spaceEvenly,
            children: categories.map((category) {
              return InkWell(
                onTap: () {
                  setState(() => _selectedCategory = category);
                },
                child: Container(
                  margin: const EdgeInsets.all(2.0),
                  padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    border: _selectedCategory == category
                        ? Border.all(color: Coloors.blueLight)
                        : Border.all(color: Colors.transparent),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: SizedBox(
                    height: 38,
                    width: 99,
                    child: Row(
                      children: [
                        Container(
                          height: 30,
                          width: 30,
                          decoration: BoxDecoration(
                            color: category.color.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            category.icon,
                            color: category.color,
                            size: 20.0,
                          ),
                        ),
                        const SizedBox(width: 3.0),
                        Text(
                          category.name,
                          style: const TextStyle(fontSize: 10.0),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(fontSize: 22, color: Coloors.backgroundDark)),
                ),
                TextButton(
                  onPressed: _saveDataItem,
                  child: const Text('Update', style: TextStyle(fontSize: 22, color: Coloors.blueDark)),
                ),
              ],
            ),
            ButtonRow(
              selectedButton: _selectedButton,
              onButtonChanged: (value) {
                setState(() {
                  _selectedButton = value;
                  _selectedCategory = null;
                });
              },
            ),
            const SizedBox(height: 16),
            Container(
              height: 100,
              color: Colors.grey[200],
              child: const Center(child: Text('Ad Placeholder')),
            ),
            const SizedBox(height: 20),
            const Text('Amount', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 2),
            TextFormField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'INR',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                prefixIcon: const Icon(Icons.keyboard_arrow_down, color: Coloors.blueLight),
                hintStyle: const TextStyle(color: Coloors.blueLight),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Category', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 2),
            _buildCategoryGrid(),
            const SizedBox(height: 20),
            const Text('Note', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 2),
            TextField(
              controller: noteController,
              decoration: InputDecoration(
                hintText: 'Add a note',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                hintStyle: const TextStyle(color: Coloors.greyLight),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Time', style: TextStyle(fontSize: 18)),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _selectDate(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Coloors.greyLight),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                    ),
                    child: Text(DateFormat('MMM d, yyyy').format(_selectedDate)),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _selectTime(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Coloors.greyLight),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                    ),
                    child: Text(_selectedTime.format(context)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
