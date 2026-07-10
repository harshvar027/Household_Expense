import 'package:flutter/material.dart';


class MonthlyBarChart extends StatelessWidget {
  final Map<String, double> monthlyExpenseTotals;

  const MonthlyBarChart({super.key, required this.monthlyExpenseTotals});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: SizedBox(
        height: 300,
        child: Center(
          child: Text(
            "Monthly Bar Chart",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
