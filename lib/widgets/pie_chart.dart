import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

Widget buildPieChart(Map<String, double> categoryTotals) {
  if (categoryTotals.isEmpty) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Text(
            "No expense data available",
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }

  final colors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.amber,
    Colors.pink,
  ];

  int colorIndex = 0;

  return SizedBox(
    height: 300,
    child: PieChart(
      PieChartData(
        sections: categoryTotals.entries.map((entry) {
          final color = colors[colorIndex % colors.length];
          colorIndex++;

          return PieChartSectionData(
            color: color,
            value: entry.value,
            title: entry.key,
            radius: 90,
            titleStyle: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          );
        }).toList(),
      ),
    ),
  );
}
