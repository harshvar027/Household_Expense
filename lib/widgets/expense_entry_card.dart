import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/money_format.dart';

class ExpenseEntryCard extends StatelessWidget {
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

  const ExpenseEntryCard({
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

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    String? prefixText,
  }) {
    return InputDecoration(
      labelText: label,
      prefixText: prefixText,
      prefixIcon: Icon(icon, color: AppColors.primary),
      filled: true,
      fillColor: AppColors.surfaceElevated,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      hintStyle: const TextStyle(color: AppColors.textMuted),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: AppColors.heroGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.add_shopping_cart, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Expense',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Record a new household expense',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: OutlinedButton.icon(
              onPressed: onImport,
              icon: const Icon(Icons.upload_file, color: Colors.white),
              label: const Text(
                'Import Bank Statement',
                style: TextStyle(color: Colors.white),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.card.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.18),
              ),
            ),
            child: Column(
              children: [
                InkWell(
                  onTap: onPickDate,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Text(
                          'Date: ${selectedDate.day.toString().padLeft(2, '0')}-'
                          '${selectedDate.month.toString().padLeft(2, '0')}-'
                          '${selectedDate.year}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.edit,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory.isEmpty ? null : selectedCategory,
                  decoration: _fieldDecoration(
                    label: 'Category',
                    icon: Icons.category_outlined,
                  ),
                  items: categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) onCategoryChanged(value);
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: itemController,
                  decoration: _fieldDecoration(
                    label: 'Item / Description',
                    icon: Icons.receipt_long,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: amountController,
                  keyboardType: kMoneyKeyboard,
                  inputFormatters: kMoneyInputFormatters,
                  decoration: _fieldDecoration(
                    label: 'Amount',
                    icon: Icons.payments_outlined,
                    prefixText: moneyInputPrefix(),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: selectedPaymentMethod,
                  decoration: _fieldDecoration(
                    label: 'Payment Method',
                    icon: Icons.payment,
                  ),
                  items: paymentMethods.map((method) {
                    return DropdownMenuItem(
                      value: method,
                      child: Text(method),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) onPaymentMethodChanged(value);
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: onSave,
                    icon: const Icon(Icons.save_alt),
                    label: const Text(
                      'Save Expense',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
