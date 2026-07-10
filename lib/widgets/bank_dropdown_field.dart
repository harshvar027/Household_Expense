import 'package:flutter/material.dart';

import '../config/region_config.dart';
import '../models/bank_profile.dart';
import '../services/app_locale_service.dart';
import '../theme/app_theme.dart';
class BankDropdownField extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  final bool allowAutoDetect;
  final String? labelText;
  final String? helperText;
  final bool enabled;

  const BankDropdownField({
    super.key,
    required this.value,
    required this.onChanged,
    this.allowAutoDetect = true,
    this.labelText,
    this.helperText,
    this.enabled = true,
  });

  List<RegionalBankOption> get _options {
    final config = AppLocaleService.instance.config;
    if (allowAutoDetect) return config.banks;
    return config.registrationBanks;
  }

  String? _resolveInitialValue(List<RegionalBankOption> options) {
    if (value != null && options.any((bank) => bank.id == value)) {
      return value;
    }
    if (allowAutoDetect) return 'generic';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final options = _options;
    final initialValue = _resolveInitialValue(options);

    return DropdownButtonFormField<String>(
      initialValue: initialValue,
      hint: initialValue == null ? const Text('Select bank') : null,
      decoration: InputDecoration(
        labelText: labelText ?? 'Bank',
        helperText: helperText,
        prefixIcon: const Icon(Icons.account_balance_outlined),
      ),
      items: options
          .map(
            (bank) => DropdownMenuItem(
              value: bank.id,
              child: Text(bank.displayName),
            ),
          )
          .toList(),
      onChanged: enabled
          ? (selected) {
              if (selected == null || selected == 'generic') {
                onChanged(null);
              } else {
                onChanged(selected);
              }
            }
          : null,
    );
  }
}
/// Compact bank label chip for lists and summaries.
class BankLabelChip extends StatelessWidget {
  final String? bankId;
  final bool indicative;

  const BankLabelChip({
    super.key,
    required this.bankId,
    this.indicative = false,
  });

  @override
  Widget build(BuildContext context) {
    final label = BankProfile.labelForId(bankId);
    if (label.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Text(
        indicative ? '$label (bank)' : label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
