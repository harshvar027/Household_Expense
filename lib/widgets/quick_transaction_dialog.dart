import 'package:flutter/material.dart';

import '../models/parsed_sms_transaction.dart';
import '../utils/category_utils.dart';
import '../utils/money_format.dart';

class QuickTransactionResult {
  final QuickTransactionType type;
  final double amount;
  final String category;
  final String description;
  final String paymentMethod;
  final DateTime date;

  const QuickTransactionResult({
    required this.type,
    required this.amount,
    required this.category,
    required this.description,
    required this.paymentMethod,
    required this.date,
  });
}

const incomeCategories = [
  'Salary',
  'Interest',
  'Refund',
  'Dividend',
  'Investment Return',
  'Income',
];

Future<QuickTransactionResult?> showQuickTransactionDialog({
  required BuildContext context,
  required ParsedSmsTransaction parsed,
  required List<String> expenseCategories,
  required List<String> paymentMethods,
}) {
  return showDialog<QuickTransactionResult>(
    context: context,
    barrierDismissible: false,
    builder: (context) => QuickTransactionDialog(
      parsed: parsed,
      expenseCategories: expenseCategories,
      paymentMethods: paymentMethods,
    ),
  );
}

class QuickTransactionDialog extends StatefulWidget {
  final ParsedSmsTransaction parsed;
  final List<String> expenseCategories;
  final List<String> paymentMethods;

  const QuickTransactionDialog({
    super.key,
    required this.parsed,
    required this.expenseCategories,
    required this.paymentMethods,
  });

  @override
  State<QuickTransactionDialog> createState() => _QuickTransactionDialogState();
}

class _QuickTransactionDialogState extends State<QuickTransactionDialog> {
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  late QuickTransactionType _type;
  late String _category;
  late String _paymentMethod;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: formatMoney(widget.parsed.amount),
    );
    _descriptionController = TextEditingController(text: widget.parsed.description);
    _paymentMethod = widget.paymentMethods.contains(widget.parsed.paymentMethod)
        ? widget.parsed.paymentMethod
        : widget.paymentMethods.first;

    if (widget.parsed.isInvestmentHint) {
      _type = QuickTransactionType.investment;
    } else if (widget.parsed.isDebit) {
      _type = QuickTransactionType.expense;
    } else {
      _type = QuickTransactionType.income;
    }

    _category = _defaultCategoryForType(_type);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  List<String> get _currentCategories {
    switch (_type) {
      case QuickTransactionType.income:
        return incomeCategories;
      case QuickTransactionType.investment:
        return CategoryUtils.savingsCategories
            .where(widget.expenseCategories.contains)
            .toList();
      case QuickTransactionType.expense:
        return widget.expenseCategories
            .where((c) => !CategoryUtils.isSavingsCategory(c))
            .toList();
    }
  }

  String _defaultCategoryForType(QuickTransactionType type) {
    switch (type) {
      case QuickTransactionType.income:
        return incomeCategories.contains(widget.parsed.suggestedCategory)
            ? widget.parsed.suggestedCategory
            : 'Income';
      case QuickTransactionType.investment:
        final options = CategoryUtils.savingsCategories
            .where(widget.expenseCategories.contains)
            .toList();
        if (options.contains(widget.parsed.suggestedCategory)) {
          return widget.parsed.suggestedCategory;
        }
        return options.isNotEmpty ? options.first : 'Investment';
      case QuickTransactionType.expense:
        if (widget.expenseCategories.contains(widget.parsed.suggestedCategory) &&
            !CategoryUtils.isSavingsCategory(widget.parsed.suggestedCategory)) {
          return widget.parsed.suggestedCategory;
        }
        return widget.expenseCategories
                .where((c) => !CategoryUtils.isSavingsCategory(c))
                .firstOrNull ??
            'Other';
    }
  }

  void _onTypeChanged(QuickTransactionType type) {
    setState(() {
      _type = type;
      _category = _defaultCategoryForType(type);
    });
  }

  void _save() {
    final amount = parseMoney(_amountController.text.trim());
    final description = _descriptionController.text.trim();
    if (amount == null || amount <= 0 || description.isEmpty) return;

    Navigator.pop(
      context,
      QuickTransactionResult(
        type: _type,
        amount: amount,
        category: _category,
        description: description,
        paymentMethod: _paymentMethod,
        date: widget.parsed.date,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = _currentCategories;

    return AlertDialog(
      title: const Text('Transaction received'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Add this to your tracker now to skip manual entry later.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            SegmentedButton<QuickTransactionType>(
              segments: const [
                ButtonSegment(
                  value: QuickTransactionType.expense,
                  label: Text('Expense'),
                  icon: Icon(Icons.shopping_bag_outlined, size: 18),
                ),
                ButtonSegment(
                  value: QuickTransactionType.income,
                  label: Text('Income'),
                  icon: Icon(Icons.south_west, size: 18),
                ),
                ButtonSegment(
                  value: QuickTransactionType.investment,
                  label: Text('Invest'),
                  icon: Icon(Icons.savings_outlined, size: 18),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (selection) {
                if (selection.isEmpty) return;
                _onTypeChanged(selection.first);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: kMoneyKeyboard,
              inputFormatters: kMoneyInputFormatters,
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: moneyInputPrefix(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: categories.contains(_category)
                  ? _category
                  : categories.firstOrNull,
              decoration: const InputDecoration(labelText: 'Category'),
              items: categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: categories.isEmpty
                  ? null
                  : (value) {
                      if (value != null) setState(() => _category = value);
                    },
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: widget.paymentMethods.contains(_paymentMethod)
                  ? _paymentMethod
                  : widget.paymentMethods.first,
              decoration: const InputDecoration(labelText: 'Payment method'),
              items: widget.paymentMethods
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _paymentMethod = value);
              },
            ),
            const SizedBox(height: 8),
            Text(
              widget.parsed.rawMessage,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Dismiss'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
