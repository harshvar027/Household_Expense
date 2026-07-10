import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'ui/glass_surface.dart';

class MonthSelector extends StatelessWidget {
  final String selectedMonth;
  final List<Map<String, String>> months;
  final ValueChanged<String> onChanged;

  const MonthSelector({
    super.key,
    required this.selectedMonth,
    required this.months,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GlassSurface.card(
      padding: EdgeInsets.zero,
      borderRadius: 18,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedMonth,
          isExpanded: true,
          borderRadius: BorderRadius.circular(18),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.primary,
          ),
          items: months.map((month) {
            return DropdownMenuItem<String>(
              value: month['value'],
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.calendar_month_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    month['label']!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ),
    );
  }
}
