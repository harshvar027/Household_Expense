import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../theme/neo_palette.dart';
import '../../utils/money_format.dart';
import 'ui/animated_counter.dart';
import 'ui/app_logo.dart';
import 'ui/neo_glass.dart';

class DashboardHeader extends StatelessWidget {
  final String selectedMonth;
  final List<Map<String, String>> months;
  final ValueChanged<String> onMonthChanged;
  final double balance;
  final String? userName;
  final String? householdName;
  final VoidCallback? onAccountSettings;
  final VoidCallback? onManageSettings;
  final VoidCallback? onLogout;

  const DashboardHeader({
    super.key,
    required this.selectedMonth,
    required this.months,
    required this.onMonthChanged,
    required this.balance,
    this.userName,
    this.householdName,
    this.onAccountSettings,
    this.onManageSettings,
    this.onLogout,
  });

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final isPositive = balance >= 0;
    final safeSelected = months.any((m) => m['value'] == selectedMonth)
        ? selectedMonth
        : (months.isNotEmpty ? months.last['value']! : selectedMonth);

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1A1035),
            Color(0xFF121A2E),
            Color(0xFF0A121F),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: NeoPalette.cyberMint.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: NeoPalette.electricAmethyst.withValues(alpha: 0.25),
            blurRadius: 36,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: NeoPalette.cyberMint.withValues(alpha: 0.08),
            blurRadius: 48,
            spreadRadius: -8,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    NeoPalette.electricAmethyst.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -40,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    NeoPalette.cyberMint.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppLogo(size: 48, showShadow: false),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: NeoPalette.neonGradient,
                            ).createShader(bounds),
                            child: Text(
                              getGreeting(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ).animate().fadeIn(duration: 400.ms),
                          const SizedBox(height: 6),
                          Text(
                            userName != null && userName!.trim().isNotEmpty
                                ? userName!.trim()
                                : 'Your Finances',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: NeoPalette.textPrimary,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.8,
                              height: 1.1,
                            ),
                          ).animate(delay: 60.ms).fadeIn().slideX(begin: -0.05, end: 0),
                          if (householdName != null &&
                              householdName!.trim().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              householdName!.trim(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: NeoPalette.textSecondary.withValues(alpha: 0.9),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (onAccountSettings != null ||
                        onManageSettings != null ||
                        onLogout != null)
                      PopupMenuButton<String>(
                        tooltip: 'Account & settings',
                        onSelected: (value) {
                          switch (value) {
                            case 'account':
                              onAccountSettings?.call();
                            case 'manage':
                              onManageSettings?.call();
                            case 'logout':
                              onLogout?.call();
                          }
                        },
                        icon: Icon(
                          Icons.tune_rounded,
                          color: NeoPalette.cyberMint.withValues(alpha: 0.9),
                        ),
                        color: NeoPalette.slateCard,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: NeoPalette.cyberMint.withValues(alpha: 0.2),
                          ),
                        ),
                        offset: const Offset(0, 44),
                        itemBuilder: (context) => [
                          if (onAccountSettings != null)
                            const PopupMenuItem(
                              value: 'account',
                              child: ListTile(
                                leading: Icon(Icons.person_outline),
                                title: Text('Account & security'),
                                contentPadding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          if (onManageSettings != null)
                            const PopupMenuItem(
                              value: 'manage',
                              child: ListTile(
                                leading: Icon(Icons.tune_rounded),
                                title: Text('Manage household'),
                                contentPadding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          if (onLogout != null) ...[
                            const PopupMenuDivider(),
                            PopupMenuItem(
                              value: 'logout',
                              child: ListTile(
                                leading: Icon(
                                  Icons.logout,
                                  color: AppColors.expense,
                                ),
                                title: Text(
                                  'Sign out',
                                  style: TextStyle(color: AppColors.expense),
                                ),
                                contentPadding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ],
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                NeoGlass.onGradient(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  borderRadius: 18,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: safeSelected,
                      isExpanded: true,
                      dropdownColor: NeoPalette.slateCard,
                      borderRadius: BorderRadius.circular(16),
                      icon: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: NeoPalette.cyberMint.withValues(alpha: 0.95),
                      ),
                      selectedItemBuilder: (context) {
                        return months.map((month) {
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_month_rounded,
                                  color: NeoPalette.cyberMint.withValues(alpha: 0.95),
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    month['label']!,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: NeoPalette.textPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList();
                      },
                      items: months.map((month) {
                        return DropdownMenuItem<String>(
                          value: month['value'],
                          child: Text(
                            month['label']!,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: NeoPalette.textPrimary,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) onMonthChanged(value);
                      },
                    ),
                  ),
                ).animate(delay: 120.ms).fadeIn().scale(
                      begin: const Offset(0.95, 0.95),
                    ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text(
                      'Available balance',
                      style: TextStyle(
                        color: NeoPalette.textSecondary.withValues(alpha: 0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      isPositive
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      color: isPositive
                          ? NeoPalette.incomeNeon
                          : NeoPalette.expenseNeon,
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                NeoGlass.card(
                  glowColor: isPositive
                      ? NeoPalette.cyberMint
                      : NeoPalette.expenseNeon,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  borderRadius: 20,
                  child: Row(
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: isPositive
                              ? NeoPalette.neonGradient
                              : [
                                  NeoPalette.expenseNeon,
                                  NeoPalette.electricAmethyst,
                                ],
                        ).createShader(bounds),
                        child: Text(
                          balance < 0 ? '-${currencySymbol()}' : currencySymbol(),
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Expanded(
                        child: AnimatedCounter(
                          value: balance.abs(),
                          fractionDigits: kMoneyDecimals,
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: NeoPalette.textPrimary,
                            letterSpacing: -0.5,
                            shadows: [
                              Shadow(
                                color: NeoPalette.cyberMint.withValues(alpha: 0.3),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate(delay: 180.ms).fadeIn().slideY(begin: 0.1, end: 0),
                if (!isPositive)
                  Padding(
                    padding: const EdgeInsets.only(top: 10, left: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 14,
                          color: NeoPalette.expenseNeon.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Over budget this month',
                          style: TextStyle(
                            color: NeoPalette.expenseNeon.withValues(alpha: 0.85),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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
