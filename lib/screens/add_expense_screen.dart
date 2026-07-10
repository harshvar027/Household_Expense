import 'package:flutter/material.dart';
import '../widgets/ui/app_scaffold.dart';
import '../widgets/expense_entry_card.dart';

class AddExpenseScreen extends StatelessWidget {
  final List<String> categories;
  final List<String> paymentMethods;
  final String selectedCategory;
  final String selectedPaymentMethod;
  final DateTime selectedDate;
  final TextEditingController itemController;
  final TextEditingController amountController;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onPaymentMethodChanged;
  final VoidCallback onPickDate;
  final VoidCallback onSave;
  final VoidCallback onImport;

  const AddExpenseScreen({
    super.key,
    required this.categories,
    required this.paymentMethods,
    required this.selectedCategory,
    required this.selectedPaymentMethod,
    required this.selectedDate,
    required this.itemController,
    required this.amountController,
    required this.onCategoryChanged,
    required this.onPaymentMethodChanged,
    required this.onPickDate,
    required this.onSave,
    required this.onImport,
  });

  @override
  Widget build(BuildContext context) {
    return AppScreenScaffold(
      title: 'Add Expense',
      scrollBody: true,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          32 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ExpenseEntryCard(
          categories: categories,
          paymentMethods: paymentMethods,
          selectedCategory: selectedCategory,
          selectedPaymentMethod: selectedPaymentMethod,
          selectedDate: selectedDate,
          itemController: itemController,
          amountController: amountController,
          onCategoryChanged: onCategoryChanged,
          onPaymentMethodChanged: onPaymentMethodChanged,
          onPickDate: onPickDate,
          onSave: () async {
            onSave();
            if (context.mounted) Navigator.pop(context);
          },
          onImport: onImport,
        ),
      ),
    );
  }
}
