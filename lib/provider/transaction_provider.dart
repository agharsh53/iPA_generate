import 'package:flutter/foundation.dart' hide Category;

import '../models/category_model.dart';
import '../models/data_item.dart';
import '../services/transaction_service.dart';

/// Single source of truth for all transaction / category state.
///
/// No screen should talk to TransactionService directly anymore.
/// Screens should only read from this provider and call its methods.
class TransactionProvider extends ChangeNotifier {
  final TransactionService _transactionService = TransactionService();

  List<DataItem> _transactions = [];
  List<Category> _expenseCategories = [];
  List<Category> _incomeCategories = [];
  List<Category> _loanCategories = [];

  bool _isLoading = false;
  String? _error;
  bool _initialized = false;

  // ---------------- GETTERS ----------------

  List<DataItem> get transactions => _transactions;

  List<Category> get expenseCategories => _expenseCategories;
  List<Category> get incomeCategories => _incomeCategories;
  List<Category> get loanCategories => _loanCategories;

  List<Category> get allCategories => [
    ..._expenseCategories,
    ..._incomeCategories,
    ..._loanCategories,
  ];

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get initialized => _initialized;

  /// Returns the correct category list for a given type string
  /// ('expense' / 'income' / 'loan' — case-insensitive).
  List<Category> categoriesForType(String type) {
    switch (type.toLowerCase()) {
      case 'income':
        return _incomeCategories;
      case 'loan':
        return _loanCategories;
      case 'expense':
      default:
        return _expenseCategories;
    }
  }

  /// Maps 'Expense' / 'Income' / 'Loan' button labels to CategoryType.
  CategoryType categoryTypeFromString(String value) {
    switch (value.toLowerCase()) {
      case 'income':
        return CategoryType.income;
      case 'loan':
        return CategoryType.loan;
      case 'expense':
      default:
        return CategoryType.expense;
    }
  }

  // ---------------- INIT / REFRESH ----------------

  /// Call once (e.g. in main.dart's ChangeNotifierProvider, or on app start /
  /// after login) to load categories + transactions.
  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _expenseCategories =
      await _transactionService.fetchCategories(CategoryType.expense);
      _incomeCategories =
      await _transactionService.fetchCategories(CategoryType.income);
      _loanCategories =
      await _transactionService.fetchCategories(CategoryType.loan);

      _transactions =
      await _transactionService.fetchAllTransactions(allCategories);

      _initialized = true;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Re-fetch transactions only (categories rarely change).
  /// Call after add/update/delete, or when user pulls to refresh.
  Future<void> refreshTransactions() async {
    _isLoading = true;
    notifyListeners();

    try {
      _transactions =
      await _transactionService.fetchAllTransactions(allCategories);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---------------- CRUD ----------------

  Future<bool> addTransaction(DataItem item) async {
    final success = await _transactionService.insertTransaction(item);
    if (success) {
      await refreshTransactions();
    }
    return success;
  }

  Future<bool> updateTransaction(DataItem item) async {
    final success = await _transactionService.updateTransaction(item);
    if (success) {
      await refreshTransactions();
    }
    return success;
  }

  Future<void> deleteTransaction(String id) async {
    await _transactionService.deleteTransaction(id);
    await refreshTransactions();
  }

  // ---------------- FILTERING / TOTALS ----------------

  bool _isSameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  /// Replaces every screen-local `_isSameMonth` + `.where(...)` combo.
  List<DataItem> filterTransactions({
    required String type,
    required DateTime month,
    String searchText = '',
  }) {
    final query = searchText.toLowerCase();
    return _transactions.where((item) {
      final matchesType = item.dataType == type.toLowerCase();
      final matchesMonth = _isSameMonth(item.dateTime, month);
      final matchesSearch = query.isEmpty ||
          item.category.name.toLowerCase().contains(query) ||
          item.note.toLowerCase().contains(query) ||
          item.amount.toString().contains(query);
      return matchesType && matchesMonth && matchesSearch;
    }).toList();
  }

  double totalExpenseForMonth(DateTime month) {
    return _transactions
        .where((i) =>
    (i.dataType == 'expense' || i.category.id == 20) &&
        _isSameMonth(i.dateTime, month))
        .fold(0.0, (sum, i) => sum + i.amount);
  }

  double totalIncomeForMonth(DateTime month) {
    return _transactions
        .where((i) =>
    (i.dataType == 'income' || i.category.id == 19) &&
        _isSameMonth(i.dateTime, month))
        .fold(0.0, (sum, i) => sum + i.amount);
  }

  double totalLoanForMonth(DateTime month) {
    return _transactions
        .where((i) => i.dataType == 'loan' && _isSameMonth(i.dateTime, month))
        .fold(0.0, (sum, i) => sum + i.amount);
  }

  double totalBalanceForMonth(DateTime month) {
    return totalIncomeForMonth(month) - totalExpenseForMonth(month);
  }

  /// Overall (all-time) balance — used by HomeScreen's "Available Balance"
  /// when no month filter is desired. Screens that filter by month should
  /// prefer totalBalanceForMonth().
  double get totalBalanceAllTime {
    final expense = _transactions
        .where((i) => i.dataType == 'expense' || i.category.id == 20)
        .fold(0.0, (sum, i) => sum + i.amount);
    final income = _transactions
        .where((i) => i.dataType == 'income' || i.category.id == 19)
        .fold(0.0, (sum, i) => sum + i.amount);
    return income - expense;
  }

  /// Aggregates a filtered list by category id -> total amount.
  /// Used by PieChartWidget / BarChartWidget / StatisticScreen legend list.
  Map<int, double> aggregateByCategory(List<DataItem> items) {
    final totals = <int, double>{};
    for (final item in items) {
      totals[item.category.id] = (totals[item.category.id] ?? 0) + item.amount;
    }
    return totals;
  }

  /// Year-level totals, used by StatisticDetail's yearly table.
  Map<int, Map<String, double>> monthlyTotalsForYear(int year) {
    final Map<int, Map<String, double>> monthly = {};
    for (final item in _transactions) {
      if (item.dateTime.year != year) continue;
      final m = item.dateTime.month;
      monthly.putIfAbsent(m, () => {'expense': 0, 'income': 0});
      if (item.dataType == 'expense') {
        monthly[m]!['expense'] = monthly[m]!['expense']! + item.amount;
      } else if (item.dataType == 'income') {
        monthly[m]!['income'] = monthly[m]!['income']! + item.amount;
      }
    }
    return monthly;
  }

  double totalExpenseForYear(int year) {
    return _transactions
        .where((i) => i.dataType == 'expense' && i.dateTime.year == year)
        .fold(0.0, (sum, i) => sum + i.amount);
  }

  double totalIncomeForYear(int year) {
    return _transactions
        .where((i) => i.dataType == 'income' && i.dateTime.year == year)
        .fold(0.0, (sum, i) => sum + i.amount);
  }
}