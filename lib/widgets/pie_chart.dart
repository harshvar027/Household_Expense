import 'package:flutter/material.dart';

import 'expense_pie_chart.dart';

/// Legacy helper — prefer [ExpensePieChart] directly.
Widget buildPieChart(Map<String, double> categoryTotals) {
  return ExpensePieChart(
    categoryTotals: categoryTotals,
    onCategoryTap: (_) {},
  );
}
