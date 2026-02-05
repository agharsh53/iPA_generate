import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../models/aggregated_category_data.dart';
import '../../models/category_model.dart';
import '../../models/data_item.dart';


class PieChartWidget extends StatelessWidget {
  final List<DataItem> transactions;

  /// Percentage denominator for this chart's type/month, sourced from
  /// TransactionProvider.totalExpenseForMonth() / totalIncomeForMonth() /
  /// totalLoanForMonth() — kept as a single source of truth rather than
  /// recomputed here.
  final double totalAmount;

  const PieChartWidget({
    super.key,
    required this.transactions,
    required this.totalAmount,
  });

  List<AggregatedCategoryData> _aggregateData(List<DataItem> dataItems) {
    final Map<int, double> aggregatedAmounts = {};
    final Map<int, Category> categories = {}; // To store the Category object

    for (var item in dataItems) {
      final categoryId = item.category.id;
      final amount = item.amount;

      aggregatedAmounts.update(categoryId, (value) => value + amount, ifAbsent: () => amount);
      categories.putIfAbsent(categoryId, () => item.category);
    }

    return aggregatedAmounts.entries.map((entry) {
      final categoryId = entry.key;
      final total = entry.value;
      final category = categories[categoryId]!; // Get the stored Category object
      return AggregatedCategoryData(category: category, totalAmount: total);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final aggregatedData = _aggregateData(transactions);

    if (aggregatedData.isEmpty) {
      return PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(
              value: 1,
              title: 'No Data',
              color: Colors.grey[300]!,
              radius: 70,
              titleStyle: const TextStyle(
                fontSize: 16,
                overflow: TextOverflow.ellipsis,
                fontWeight: FontWeight.bold,
                color: Colors.black45,
              ),
            ),
          ],
          centerSpaceRadius: 75,
          sectionsSpace: 0,
        ),
      );
    }

    final List<PieChartSectionData> sections = aggregatedData.map((entry) {
      final percentValue =
      totalAmount == 0 ? 0.0 : (entry.totalAmount / totalAmount) * 100;
      return PieChartSectionData(
        value: entry.totalAmount, // Use totalAmount from aggregated data
        title: '${percentValue.toStringAsFixed(1)}%',
        radius: 70,
        color: entry.category.color.withOpacity(0.8),
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xffffffff),
        ),
      );
    }).toList();

    return PieChart(PieChartData(
      sectionsSpace: 0,
      centerSpaceRadius: 75,
      sections: sections,
    ));
  }
}