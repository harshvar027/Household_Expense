import 'package:flutter/material.dart';
import '../models/household_member.dart';
import '../theme/app_theme.dart';
import 'money_amount.dart';
import 'ui/neo_glass.dart';

class MemberSpendingCard extends StatelessWidget {
  final Map<String, double> memberTotals;

  const MemberSpendingCard({super.key, required this.memberTotals});

  @override
  Widget build(BuildContext context) {
    if (memberTotals.isEmpty) return const SizedBox.shrink();

    return NeoGlass.card(
      glowColor: AppColors.electricAmethyst,
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.people_rounded, color: AppColors.electricAmethyst, size: 22),
              SizedBox(width: 10),
              Text(
                'Household Spending',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...memberTotals.entries.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      e.key,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    MoneyAmount(amount: e.value, flow: MoneyFlow.debit, fontSize: 14),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

Color memberColor(HouseholdMember m) {
  try {
    final hex = m.color.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  } catch (_) {
    return AppColors.savings;
  }
}
