import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/neo_palette.dart';
import 'money_amount.dart';
import 'ui/glass_surface.dart';

import '../utils/category_utils.dart';
import '../utils/money_format.dart';

class CategoryBudgetCard extends StatelessWidget {
  final String monthLabel;
  final Map<String, double> categoryTotals;
  final Map<String, double> categoryBudgets;
  final List<String> categories;
  final Future<void> Function(String category, double amount) onSaveBudget;

  const CategoryBudgetCard({
    super.key,
    required this.monthLabel,
    required this.categoryTotals,
    required this.categoryBudgets,
    required this.categories,
    required this.onSaveBudget,
  });

  @override
  Widget build(BuildContext context) {
    final budgetedCategories = categoryBudgets.keys
        .where(
          (c) =>
              categoryBudgets[c]! > 0 &&
              !CategoryUtils.isSavingsCategory(c),
        )
        .toList();

    if (budgetedCategories.isEmpty) {
      return GlassSurface.card(
        padding: const EdgeInsets.all(20),
        borderRadius: 24,
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.category, color: Colors.teal),
                  SizedBox(width: 10),
                  Text(
                    'Category Budgets',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'No per-category budgets set for $monthLabel.',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _showBudgetDialog(context, categories.first),
                icon: const Icon(Icons.add),
                label: const Text('Set category budget'),
              ),
            ],
          ),
      );
    }

    return GlassSurface.card(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.category, color: Colors.teal),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Category Budgets — $monthLabel',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => _pickCategoryAndBudget(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...budgetedCategories.map((cat) {
              final budget = categoryBudgets[cat]!;
              final spent = categoryTotals[cat] ?? 0;
              final ratio = budget > 0 ? (spent / budget).clamp(0.0, 1.5) : 0.0;
              final color = spent > budget
                  ? Colors.red
                  : ratio >= 0.8
                      ? Colors.orange
                      : Colors.green;

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            cat,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: MoneyAmount(
                                  amount: spent,
                                  flow: MoneyFlow.debit,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                ' / ${formatMoneyWithCurrency(budget)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: ratio > 1 ? 1 : ratio,
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(8),
                      backgroundColor: NeoPalette.slateElevated,
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                    if (spent > budget)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            const Text('Over by ', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            MoneyAmount(
                              amount: spent - budget,
                              flow: MoneyFlow.debit,
                              fontSize: 12,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
      ),
    );
  }

  Future<void> _pickCategoryAndBudget(BuildContext context) async {
    String? picked = categories.first;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Choose category'),
        content: DropdownButtonFormField<String>(
          initialValue: picked,
          items: categories
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (v) => picked = v,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (picked != null) _showBudgetDialog(context, picked!);
            },
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  Future<void> _showBudgetDialog(BuildContext context, String category) async {
    final controller = TextEditingController(
      text: categoryBudgets[category] != null
          ? formatMoney(categoryBudgets[category]!)
          : '',
    );
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Budget for $category'),
        content: TextField(
          controller: controller,
          keyboardType: kMoneyKeyboard,
          inputFormatters: kMoneyInputFormatters,
          decoration: InputDecoration(
            prefixText: moneyInputPrefix(),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final amount = parseMoney(controller.text) ?? 0;
              await onSaveBudget(category, amount);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
