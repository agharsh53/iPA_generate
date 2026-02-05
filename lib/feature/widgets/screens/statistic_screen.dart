import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:money_tracker/common/color/colors.dart';

import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../common/widgets/bar_chart_widget.dart';
import '../../../common/widgets/button_row.dart';

import '../../../common/widgets/chart_button_row.dart';
import '../../../common/widgets/month_picker.dart';
import '../../../common/widgets/pie_chart_widget.dart';
import '../../../common/widgets/statistic_list_tile.dart';
import '../../../common/widgets/line_graph_widget.dart';
import '../../../feature/widgets/pages/statistic_detail.dart';

import '../../../models/category_model.dart';
import '../../../models/data_item.dart';
import '../../../provider/transaction_provider.dart';

class StatisticScreen extends StatefulWidget {

  const StatisticScreen({super.key,  });

  @override
  State<StatisticScreen> createState() => _StatisticScreenState();
}

class _StatisticScreenState extends State<StatisticScreen> {
  String _selectedMonth = DateFormat('MMM yyyy').format(DateTime.now());
  String _selectedButton = 'Expense';
  String _selectedChart = 'pie';

  @override
  void initState() {
    super.initState();
    _loadSelectedMonth();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<TransactionProvider>();
      if (!provider.initialized) {
        provider.initialize();
      }
    });
  }

  DateTime _parseSelectedMonth() {
    try {
      return DateFormat('MMM yyyy').parse(_selectedMonth);
    } catch (_) {
      return DateTime.now();
    }
  }

  Future<void> _loadSelectedMonth() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedMonth = prefs.getString('selectedMonth') ??
          DateFormat('MMM yyyy').format(DateTime.now());
    });
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
            });
            _saveSelectedMonth(month);
          },
        );
      },
    );
  }

  double _totalForSelectedType(TransactionProvider provider, DateTime month) {
    switch (_selectedButton) {
      case 'Income':
        return provider.totalIncomeForMonth(month);
      case 'Loan':
        return provider.totalLoanForMonth(month);
      case 'Expense':
      default:
        return provider.totalExpenseForMonth(month);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final selectedMonthDate = _parseSelectedMonth();

    final filteredItems = provider.filterTransactions(
      type: _selectedButton.toLowerCase(),
      month: selectedMonthDate,
    );
    final totalForType = _totalForSelectedType(provider, selectedMonthDate);
    final totalBalance = provider.totalBalanceForMonth(selectedMonthDate);

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
                                  NumberFormat.currency(locale: 'en_IN', symbol: '₹',decimalDigits: 0).format(totalBalance),
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
                                  child: _buildChart(filteredItems, totalForType), //Removed expanded
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
                                    child:  _buildCategoryGridLegend(provider),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8,),
                              _buildDataItemGrid(provider, filteredItems),
                              const SizedBox(height: 50,)],
                          ),
                        ]),),





                ),

              ),),

          ]),
    );
  }

  Widget _buildChart(List<DataItem> filteredItems, double totalForType) {
    switch (_selectedChart) {
      case 'bar':
        return BarChartWidget(transactions: filteredItems);
      case 'line':
        return LineGraphWidget(transactions: filteredItems);
      default:
        return PieChartWidget(transactions: filteredItems, totalAmount: totalForType);
    }
  }


  Widget _buildCategoryGridLegend(TransactionProvider provider) {
    final categories = provider.categoriesForType(_selectedButton);

    if (categories.isEmpty) {
      return const Text('No categories');
    }

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
  }

  Widget _buildDataItemGrid(TransactionProvider provider, List<DataItem> filteredItems) {
    if (provider.isLoading && !provider.initialized) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null) {
      return Center(child: Text('Error: ${provider.error}'));
    }

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

    final totals = provider.aggregateByCategory(filteredItems);
    final Map<int, Category> categoryMap = {};
    for (var item in filteredItems) {
      categoryMap[item.category.id] = item.category;
    }

    final totalAmount = totals.values.fold(0.0, (a, b) => a + b);

    return Column(
      children: totals.entries.map((entry) {
        final cat = categoryMap[entry.key]!;
        return StatisticListTile(
          icon: cat.icon,
          title: cat.name,
          percentage: entry.value / (totalAmount == 0 ? 1 : totalAmount),
          amount: entry.value,
          color: cat.color,
        );
      }).toList(),
    );
  }

}