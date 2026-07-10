import 'package:flutter/material.dart';
import '../utils/money_format.dart';

Widget buildCategorySummary(Map<String, double> categoryTotals) {
  return Card(
    elevation: 5,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart, color: Colors.orange),

              SizedBox(width: 10),

              Text(
                'Category Summary',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),

          const SizedBox(height: 20),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categoryTotals.length,
            itemBuilder: (context, index) {
              final category = categoryTotals.keys.elementAt(index);

              return Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      radius: 12,
                      backgroundColor:
                          Colors.primaries[index % Colors.primaries.length],
                    ),

                    title: Text(
                      category,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),

                    trailing: Text(
                      formatMoneyWithCurrency(categoryTotals[category]!),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),

                  if (index != categoryTotals.length - 1)
                    const Divider(height: 1),
                ],
              );
            },
          ),
        ],
      ),
    ),
  );
}
