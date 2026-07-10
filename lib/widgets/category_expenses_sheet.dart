import 'package:flutter/material.dart';

import '../models/expense.dart';

import 'money_amount.dart';



void showCategoryExpensesSheet(

  BuildContext context, {

  required String category,

  required List<Expense> expenses,

  required String monthLabel,

  required String Function(String) formatDate,

}) {

  final total = expenses.fold<double>(0, (sum, e) => sum + e.amount);



  showModalBottomSheet(

    context: context,

    isScrollControlled: true,

    shape: const RoundedRectangleBorder(

      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),

    ),

    builder: (context) {

      return DraggableScrollableSheet(

        expand: false,

        initialChildSize: 0.55,

        minChildSize: 0.35,

        maxChildSize: 0.9,

        builder: (context, scrollController) {

          return Padding(

            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                Center(

                  child: Container(

                    width: 40,

                    height: 4,

                    decoration: BoxDecoration(

                      color: Colors.grey.shade300,

                      borderRadius: BorderRadius.circular(4),

                    ),

                  ),

                ),

                const SizedBox(height: 16),

                Row(

                  children: [

                    CircleAvatar(

                      backgroundColor: Colors.deepPurple.shade100,

                      child: const Icon(Icons.category, color: Colors.deepPurple),

                    ),

                    const SizedBox(width: 12),

                    Expanded(

                      child: Column(

                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [

                          Text(

                            category,

                            style: const TextStyle(

                              fontSize: 20,

                              fontWeight: FontWeight.bold,

                            ),

                          ),

                          Row(

                            children: [

                              Text(

                                '$monthLabel • ${expenses.length} items • ',

                                style: TextStyle(color: Colors.grey.shade600),

                              ),

                              MoneyAmount(

                                amount: total,

                                flow: MoneyFlow.debit,

                                fontSize: 13,

                                fontWeight: FontWeight.w600,

                              ),

                            ],

                          ),

                        ],

                      ),

                    ),

                  ],

                ),

                const SizedBox(height: 16),

                Expanded(

                  child: expenses.isEmpty

                      ? Center(

                          child: Text(

                            'No expenses in this category',

                            style: TextStyle(color: Colors.grey.shade600),

                          ),

                        )

                      : ListView.builder(

                          controller: scrollController,

                          itemCount: expenses.length,

                          itemBuilder: (context, index) {

                            final expense = expenses[index];

                            return Card(

                              margin: const EdgeInsets.only(bottom: 8),

                              child: ListTile(

                                leading: CircleAvatar(

                                  backgroundColor: Colors.orange.shade50,

                                  child: const Icon(

                                    Icons.receipt,

                                    color: Colors.orange,

                                    size: 20,

                                  ),

                                ),

                                title: Text(

                                  expense.item,

                                  style: const TextStyle(fontWeight: FontWeight.w600),

                                ),

                                subtitle: Text(

                                  '${formatDate(expense.expenseDate)} • ${expense.paymentMethod}',

                                ),

                                trailing: MoneyAmount(

                                  amount: expense.amount,

                                  flow: MoneyFlow.debit,

                                ),

                              ),

                            );

                          },

                        ),

                ),

              ],

            ),

          );

        },

      );

    },

  );

}


