import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


import '../../../common/color/colors.dart';
import '../../../common/widgets/header_text.dart';
import '../../../common/widgets/table_text.dart';
import '../../../models/category_model.dart';
import '../../../models/data_item.dart';
import '../../../services/transaction_service.dart';
class StatisticDetail extends StatefulWidget {
  const StatisticDetail({super.key});

  @override
  State<StatisticDetail> createState() => _StatisticDetailState();
}

class _StatisticDetailState extends State<StatisticDetail> {
  final TransactionService _transactionService = TransactionService();
  int _selectedYear = DateTime.now().year;
  late Future<List<DataItem>> _transactionsFuture;


  double _totalExpense = 0;
  double _totalIncome = 0;

  @override
  void initState() {
    super.initState();
    _transactionsFuture = _initStatisticScreen();

  }
  Future<List<DataItem>> _initStatisticScreen() async {
    final expenseCategories =
    await _transactionService.fetchCategories(CategoryType.expense);
    final incomeCategories =
    await _transactionService.fetchCategories(CategoryType.income);
    final loanCategories =
    await _transactionService.fetchCategories(CategoryType.loan);

    final allCategories = <Category>[
      ...expenseCategories,
      ...incomeCategories,
      ...loanCategories,
    ];

    final items =
    await _transactionService.fetchAllTransactions(allCategories);

    _calculateTotals(items);
    return items;
  }



  void _calculateTotals(List<DataItem> items) {
    double expense = 0;
    double income = 0;

    for (final item in items) {
      if (item.dateTime.year == _selectedYear) {
        if (item.dataType == 'expense') expense += item.amount;
        if (item.dataType == 'income') income += item.amount;
      }
    }

    setState(() {
      _totalExpense = expense;
      _totalIncome = income;
    });
  }


  // Future<void> _loadTransactions() async {
  //   setState(() {
  //     _transactionsFuture = _transactionsFuture;
  //   });// Trigger a rebuild to show the updated data
  //   await _calculateTotals();
  //
  // }
  void _showYearPicker() async {
    final selected = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Year'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: YearPicker(
              firstDate: DateTime(DateTime.now().year - 10),
              lastDate: DateTime(DateTime.now().year + 10),
              selectedDate: DateTime(_selectedYear),
              onChanged: (DateTime dateTime) {
                Navigator.pop(context, dateTime.year);
              },
            ),
          ),
        );
      },
    );

    if (selected != null && selected != _selectedYear) {
      setState(() {
        _selectedYear = selected;
        _transactionsFuture=_initStatisticScreen();
      });

    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              const SizedBox(height: 20,),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(onPressed: () {
                    Navigator.pop(context);
                  },
                    child: const Icon(Icons.keyboard_arrow_left, size: 40,
                      color: Colors.black,),),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(onPressed: _showYearPicker,
                      style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11),),
                          backgroundColor: Coloors.blueLight),
                      child: Text( _selectedYear.toString(), style: TextStyle(
                          color: Coloors.backgroundLight,
                          fontWeight: FontWeight.bold),),),

                  ),

                ],
              ),
              const SizedBox(height: 40,),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Coloors.blueDark, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Total balance", style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(NumberFormat.currency(locale: 'en_IN', symbol: '₹',decimalDigits: 0).format(_totalIncome - _totalExpense), style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Expenses: ${NumberFormat.currency(locale: 'en_IN', symbol: '₹',decimalDigits: 0).format( _totalExpense)}', style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500)),
                  Text("Income: ${NumberFormat.currency(locale: 'en_IN', symbol: '₹',decimalDigits: 0).format(_totalIncome)}", style: const TextStyle(fontSize: 16,
                      fontWeight: FontWeight.w500,)),
                ],
              ),
              const SizedBox(height: 40),

              // Table Header with Gradient
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Coloors.blueDark, Colors.blueAccent],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                    vertical: 12, horizontal: 8),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    HeaderText("Month"),
                    HeaderText("Expend"),
                    HeaderText("Income"),
                    HeaderText("Loan"),
                    HeaderText("Borrow"),
                    HeaderText("Balance"),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              Expanded(
                child: FutureBuilder<List<DataItem>>(
                  future: _transactionsFuture,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.data!.isEmpty) {
                      return const Center(child: Text("No data found."));
                    }

                    final items = snapshot.data!;
                    final Map<int, Map<String, double>> monthly = {};

                    for (final item in items) {
                      if (item.dateTime.year != _selectedYear) continue;

                      final m = item.dateTime.month;
                      monthly.putIfAbsent(m, () => {
                        'expense': 0,
                        'income': 0,
                      });

                      if (item.dataType == 'expense') {
                        monthly[m]!['expense'] =
                            monthly[m]!['expense']! + item.amount;
                      } else if (item.dataType == 'income') {
                        monthly[m]!['income'] =
                            monthly[m]!['income']! + item.amount;
                      }
                    }

                    return ListView(
                      children: monthly.entries.map((e) {
                        final monthName =
                        DateFormat.MMMM().format(DateTime(0, e.key));
                        final expense = e.value['expense']!;
                        final income = e.value['income']!;
                        final balance = income - expense;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  monthName,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              TableText(expense),
                              TableText(income),
                              TableText(balance),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

