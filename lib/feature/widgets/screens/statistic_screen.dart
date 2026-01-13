import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:money_tracker/common/color/colors.dart';

import 'package:money_tracker/common/widgets/line_graph_widget.dart';
import 'package:money_tracker/feature/widgets/pages/statistic_detail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../common/widgets/bar_chart_widget.dart';
import '../../../common/widgets/button_row.dart';

import '../../../common/widgets/chart_button_row.dart';
import '../../../common/widgets/month_picker.dart';
import '../../../common/widgets/pie_chart_widget.dart';
import '../../../common/widgets/statistic_list_tile.dart';

import 'dart:ui';


import '../../../models/aggregated_category_data.dart';
import '../../../models/category_model.dart';
import '../../../models/data_item.dart';
import '../../../services/transaction_service.dart';
import '../pages/transaction_detail.dart';
class StatisticScreen extends StatefulWidget {

  const StatisticScreen({super.key,  });

  @override
  State<StatisticScreen> createState() => _StatisticScreenState();
}

class _StatisticScreenState extends State<StatisticScreen> {
  final TransactionService _transactionService = TransactionService();
  var time = DateTime.now();
  String _selectedMonth = DateFormat('MMM yyyy').format(DateTime.now());
  String _selectedButton = 'Expense';
  String _selectedChart = 'pie';
  double _totalExpense = 0;
  double _totalIncome = 0;
  double _totalLoan = 0;
  late Future<List<DataItem>> _transactionsFuture;
  Future<List<Category>> _categoryFuture = Future.value([]);


  @override
  void initState() {
    super.initState();
    // Initialize category future safely
    _categoryFuture = _transactionService.fetchCategories(
      _getCategoryTypeFromString(_selectedButton),
    );
    _transactionsFuture =  _initScreen();
  }
  /// 🔹 Initial load
  Future<List<DataItem>> _initScreen() async {
    await _loadSelectedMonth();

    if (_selectedMonth.isEmpty) {
      _selectedMonth = DateFormat('MMM yyyy').format(DateTime.now());
    }
    final type = _getCategoryTypeFromString(_selectedButton);
    final categories = await _transactionService.fetchCategories(type);

    setState(() {
      _categoryFuture = Future.value(categories);
    });

    final items =
    await _transactionService.fetchAllTransactions(categories);

    _calculateTotals(items);
    return items;
  }

  /// 🔹 Reload when button/month changes
  Future<void> _reload() async {
    setState(() {
      _transactionsFuture = _initScreen();
    });
  }

  Future<void> _loadTransactions() async {
    final type = _getCategoryTypeFromString(_selectedButton);

    _categoryFuture = _transactionService.fetchCategories(type);

    _transactionsFuture = _categoryFuture.then(
          (categories) =>
          _transactionService.fetchAllTransactions(categories),
    );

    final items = await _transactionsFuture;
      _calculateTotals(items);
  }

  CategoryType _getCategoryTypeFromString(String value) {
    switch (value.toLowerCase()) {
      case 'income':
        return CategoryType.income;
      case 'loan':
        return CategoryType.loan;
      default:
        return CategoryType.expense;
    }
  }
  void _calculateTotals(List<DataItem> items) {
    double expense = 0, income = 0, loan = 0;

    for (final item in items) {
      if (_isSameMonth(item.dateTime, _selectedMonth)) {
        if (item.dataType == 'expense') expense += item.amount;
        if (item.dataType == 'income') income += item.amount;
        if (item.dataType == 'loan') loan += item.amount;
      }
    }

    _totalExpense = expense;
    _totalIncome = income;
    _totalLoan = loan;
  }

  bool _isSameMonth(DateTime date, String selectedMonth) {
    if (selectedMonth.isEmpty) return true; // safety fallback
    return DateFormat('MMM yyyy').format(date) == selectedMonth;
  }



  Future<void> _loadSelectedMonth() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedMonth =
        prefs.getString('selectedMonth') ??
            DateFormat('MMM yyyy').format(DateTime.now());
  }

  Future<void> _saveSelectedMonth(String month) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedMonth', month);

  }

  void _showMonthPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext builder) {
        return MonthPicker(
          initialMonth: _selectedMonth,
          onMonthSelected: (month) {
            setState(() {
              _selectedMonth = month;
              _saveSelectedMonth(month);
              // Save the selected month
            });
          },
        );
      },
    );
  }
  void _navigateToTransactionDetail(DataItem transaction) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionDetail(
          title: transaction.category.name,
          amount: transaction.amount,
          date: transaction.dateTime,
          categoryIcon: transaction.category.icon,
          categoryColor: transaction.category.color,
          note: '${transaction.note}',
          categoryId: transaction.category.id,
          dataType: transaction.dataType,
          itemId: transaction.id!,
        ),
      ),
    );

    // If EditExpenseScreen was popped with a true result, reload transactions
    if (result != null && result == true) {
      _loadTransactions();
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white12,

      body: Stack( // Use Stack to overlay widgets
        children: <Widget>[
          // Top Purple Section (Constant)
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Coloors.blueLight, Coloors.blueDark,Coloors.blueLight2],
                begin: FractionalOffset(0.5, 0.6),
                end: FractionalOffset(0.0, 0.5),
                stops: [0.0,0.5, 1.0],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10,),
                const Text(
                  'Statistics',
                  style: TextStyle(
                    fontSize: 29,
                    fontWeight: FontWeight.bold,
                    color: Coloors.backgroundLight,
                  ),
                ),

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Container(
                              width: 1,
                              height: 60,
                              color: Colors.blueAccent,
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              const Text(
                                'Available Balance',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white60,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                NumberFormat.currency(locale: 'en_IN', symbol: '₹',decimalDigits: 0).format(_totalIncome - _totalExpense),
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  color: Coloors.backgroundLight,
                                ),
                              ),

                            ],
                          ),
                        ],
                      ),


                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: TextButton(
                            onPressed:()=> Navigator.push(context, MaterialPageRoute(builder: (context)=> const StatisticDetail())),
                            child: const Icon(Icons.keyboard_arrow_right,color: Coloors.backgroundLight,size: 40,)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

              ],
            ),
          ),

          // Scrollable Content (Overlapping)
          Positioned(
            top: MediaQuery
                .of(context)
                .size
                .height * 0.23,
            left: 0,
            right: 0,
            bottom: 0,
            child: SingleChildScrollView(

              child: Container(
                decoration: const BoxDecoration(
                  color: Coloors.backgroundLight,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(22.0),
                          child: Column(
                              children: <Widget>[
                                ButtonRow(selectedButton: _selectedButton,
                                    onButtonChanged: (value) {
                                      setState(() {
                                        _selectedButton = value;
                                        _reload();
                                      });
                                    }),

                                const SizedBox(height: 16),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          Text(
                                            _selectedMonth.trim(),
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          TextButton(onPressed: ()=> _showMonthPicker(context),
                                              child: const Icon(Icons.keyboard_arrow_down,size: 30,)),
                                        ],
                                      ),

                                      ChartButtonRow(
                                        selectedChart: _selectedChart,
                                        onChartSelected: (type) => setState(() => _selectedChart = type),
                                      ),
                                   ]),),
                                Column(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Coloors.blueLight2.withOpacity(0.1), // Move color into BoxDecoration
                                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(10),topRight:Radius.circular(10) ),
                                      ),
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(maxHeight: 350), // Adjust the height as needed
                                        child: _buildChart(), //Removed expanded
                                      ),
                                    ),

                                    Container(
                                      width: MediaQuery.of(context).size.width,
                                      decoration: BoxDecoration(
                                        color: Coloors.blueLight2.withOpacity(0.1),
                                        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(10),bottomRight:Radius.circular(10) ),
                                      ),
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(maxHeight: 320),
                                        child: Padding( // Add Padding
                                          padding: const EdgeInsets.all(8.0), // Optional: Add padding around chart
                                          child:  _buildCategoryGridLegend(),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8,),
                                    _buildDataItemGrid(),
                                  const SizedBox(height: 50,)],
            ),
                                ]),),





                  ),

    ),),

    ]),
    );
  }
  Widget _buildChart() {
    DateTime selectedMonth;
    try {
      selectedMonth = DateFormat("MMM yyyy").parse(_selectedMonth);
    } catch (_) {
      selectedMonth = DateTime.now();
    }


    switch (_selectedChart) {
      case 'bar':
        return BarChartWidget(
          transactionsFuture: _transactionsFuture,
          selectedMonth: selectedMonth,
          type: _selectedButton.toLowerCase(),
        );
      case 'line':
        return LineGraphWidget(
          transactionsFuture: _transactionsFuture,
          selectedMonth: selectedMonth,
          type: _selectedButton.toLowerCase(),
        );
      default:
        return PieChartWidget(
          transactionsFuture: _transactionsFuture,
          selectedMonth: selectedMonth,
          type: _selectedButton.toLowerCase(),
        );
    }
  }


  Widget _buildCategoryGridLegend() {
    if (_categoryFuture == null) {
      return const SizedBox.shrink();
    }
    return FutureBuilder<List<Category>>(
      future: _categoryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('No categories');
        }
          final categories = snapshot.data!;

          return Wrap(
            spacing: 25,
            runSpacing: 5,
            alignment: WrapAlignment.center,
            children: categories.map((category) {
              return SizedBox(
                width: MediaQuery.of(context).size.width / 4-16, // 4 per row
                child: Row(
                  children: [
                    Container(
                      height: 10,
                      width: 10,
                      decoration: BoxDecoration(
                        color: category.color.withOpacity(0.8),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 2,),
                    Text(
                      category.name,
                      style: const TextStyle(fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.start,
                    ),
                  ],
                ),
              );
            }).toList(),
          );

      },
    );
  }



  String formatDate(DateTime date) {
    return DateFormat('EEE, dd MMM yyyy HH:mm').format(date);
  }





  Widget _buildDataItemGrid() {
    return FutureBuilder<List<DataItem>>(
      future: _transactionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No transactions found.'));
        }

        // Filter items based on selected button and month
        final filteredItems = snapshot.data!
            .where((item) =>
        item.dataType == _selectedButton.toLowerCase() &&
            _isSameMonth(item.dateTime, _selectedMonth))
            .toList();



        if (filteredItems.isEmpty) {
          return Center(
            child: SingleChildScrollView(
              child: Text(
                'Add your first $_selectedButton to get started!',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          );
        }

        final Map<int, double> totals = {};
        final Map<int, Category> categoryMap = {};

        for (var item in filteredItems) {
          final id = item.category.id;
          totals[id] = (totals[id] ?? 0) + item.amount;
          categoryMap[id] = item.category;
        }

        final totalAmount =
        totals.values.fold(0.0, (a, b) => a + b);


        return Column(
          children: totals.entries.map((item) {
            final cat = categoryMap[item.key]!;
            return StatisticListTile(
              icon: cat.icon, // Access icon from the aggregated category
              title: cat.name, // Access name from the aggregated category
              percentage: item.value / (totalAmount == 0 ? 1 : totalAmount), // Use totalAmount
              amount: item.value, // Use totalAmount
              color: cat.color, // Access color from the aggregated category
               // Removed, as this now represents aggregated data
            );
          }).toList(),
        );
      },
    );
  }

}



