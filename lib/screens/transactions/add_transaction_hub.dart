import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../database/database_helper.dart';
import '../../models/account.dart';
import '../../models/expense.dart';
import '../../models/household_member.dart';
import '../../screens/import_statement_screen.dart';
import '../../theme/app_theme.dart';
import 'hub/manual_entry_method.dart';
import 'hub/receipt_attach_method.dart';
import 'hub/sms_paste_method.dart';
import 'hub/split_payment_method.dart';

enum _HubStage { select, manual, split, receipt, sms }

/// Multi-path add transaction hub — all data stays on-device.
class AddTransactionHub extends StatefulWidget {
  final List<String> categories;
  final List<String> paymentMethods;
  final List<HouseholdMember> members;
  final List<Account> accounts;
  final int? defaultMemberId;
  final int? defaultAccountId;
  final VoidCallback? onSaved;

  const AddTransactionHub({
    super.key,
    required this.categories,
    required this.paymentMethods,
    required this.members,
    required this.accounts,
    this.defaultMemberId,
    this.defaultAccountId,
    this.onSaved,
  });

  static Future<bool?> open(
    BuildContext context, {
    required List<String> categories,
    required List<String> paymentMethods,
    required List<HouseholdMember> members,
    required List<Account> accounts,
    int? defaultMemberId,
    int? defaultAccountId,
    VoidCallback? onSaved,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AddTransactionHub(
        categories: categories,
        paymentMethods: paymentMethods,
        members: members,
        accounts: accounts,
        defaultMemberId: defaultMemberId,
        defaultAccountId: defaultAccountId,
        onSaved: onSaved,
      ),
    );
  }

  @override
  State<AddTransactionHub> createState() => _AddTransactionHubState();
}

class _AddTransactionHubState extends State<AddTransactionHub> {
  _HubStage _stage = _HubStage.select;

  String get _title => switch (_stage) {
        _HubStage.select => 'Add Transaction',
        _HubStage.manual => 'Manual Entry',
        _HubStage.split => 'Split Payment',
        _HubStage.receipt => 'Attach Receipt',
        _HubStage.sms => 'Paste Payment SMS',
      };

  String get _subtitle => switch (_stage) {
        _HubStage.select => 'Choose how you want to capture spending',
        _HubStage.receipt => 'Photo stays on device — fill details manually',
        _HubStage.sms => 'Parsed locally with our SMS engine',
        _ => 'Saved privately in your encrypted database',
      };

  Future<void> _saveExpense({
    required String item,
    required double amount,
    required String category,
    required String paymentMethod,
    required DateTime date,
    String notes = '',
    bool isTransfer = false,
    int? memberId,
    int? accountId,
  }) async {
    final expense = Expense(
      expenseDate:
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      category: category,
      item: item,
      amount: amount,
      paymentMethod: paymentMethod,
      notes: notes,
      isTransfer: isTransfer,
      memberId: memberId ?? widget.defaultMemberId,
      accountId: accountId ?? widget.defaultAccountId,
    );
    await DatabaseHelper.instance.insertExpense(expense);
    widget.onSaved?.call();
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _saveIncome({
    required String description,
    required double amount,
    required DateTime date,
  }) async {
    final month =
        '${date.year}-${date.month.toString().padLeft(2, '0')}';
    await DatabaseHelper.instance.insertManualIncome(
      month: month,
      amount: amount,
      description: description,
    );
    widget.onSaved?.call();
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _openStatement() async {
    final imported = await Navigator.of(context).push<bool>(
      appPageRoute(const ImportStatementScreen()),
    );
    if (!mounted) return;
    if (imported == true) {
      widget.onSaved?.call();
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.92;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final accent = AppTheme.accentOf(context);

    return SizedBox(
      height: height,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 8, 8),
              child: Row(
                children: [
                  if (_stage != _HubStage.select)
                    IconButton(
                      onPressed: () => setState(() => _stage = _HubStage.select),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_title, style: AppTheme.displayOf(context, fontSize: 20)),
                        const SizedBox(height: 2),
                        Text(
                          _subtitle,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12.5,
                            color: AppTheme.mutedOf(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context, false),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: switch (_stage) {
                  _HubStage.select => _MethodGrid(
                      key: const ValueKey('select'),
                      accent: accent,
                      onManual: () => setState(() => _stage = _HubStage.manual),
                      onSplit: () => setState(() => _stage = _HubStage.split),
                      onSms: () => setState(() => _stage = _HubStage.sms),
                      onReceipt: () => setState(() => _stage = _HubStage.receipt),
                      onStatement: _openStatement,
                    ),
                  _HubStage.manual => ManualEntryMethod(
                      key: const ValueKey('manual'),
                      categories: widget.categories,
                      paymentMethods: widget.paymentMethods,
                      members: widget.members,
                      accounts: widget.accounts,
                      defaultMemberId: widget.defaultMemberId,
                      defaultAccountId: widget.defaultAccountId,
                      onCancel: () => setState(() => _stage = _HubStage.select),
                      onSaveExpense: _saveExpense,
                      onSaveIncome: _saveIncome,
                    ),
                  _HubStage.split => SplitPaymentMethod(
                      key: const ValueKey('split'),
                      categories: widget.categories,
                      paymentMethods: widget.paymentMethods,
                      members: widget.members,
                      onCancel: () => setState(() => _stage = _HubStage.select),
                      onSave: ({
                        required String item,
                        required double amount,
                        required String category,
                        required String paymentMethod,
                        required DateTime date,
                        required String notes,
                      }) =>
                          _saveExpense(
                            item: item,
                            amount: amount,
                            category: category,
                            paymentMethod: paymentMethod,
                            date: date,
                            notes: notes,
                          ),
                    ),
                  _HubStage.sms => SmsPasteMethod(
                      key: const ValueKey('sms'),
                      categories: widget.categories,
                      paymentMethods: widget.paymentMethods,
                      onCancel: () => setState(() => _stage = _HubStage.select),
                      onSave: _saveExpense,
                    ),
                  _HubStage.receipt => ReceiptAttachMethod(
                      key: const ValueKey('receipt'),
                      categories: widget.categories,
                      paymentMethods: widget.paymentMethods,
                      members: widget.members,
                      accounts: widget.accounts,
                      defaultMemberId: widget.defaultMemberId,
                      defaultAccountId: widget.defaultAccountId,
                      onCancel: () => setState(() => _stage = _HubStage.select),
                      onSaveExpense: _saveExpense,
                    ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodGrid extends StatelessWidget {
  final Color accent;
  final VoidCallback onManual;
  final VoidCallback onSplit;
  final VoidCallback onSms;
  final VoidCallback onReceipt;
  final VoidCallback onStatement;

  const _MethodGrid({
    super.key,
    required this.accent,
    required this.onManual,
    required this.onSplit,
    required this.onSms,
    required this.onReceipt,
    required this.onStatement,
  });

  @override
  Widget build(BuildContext context) {
    final methods = [
      _Method(
        Icons.edit_note_rounded,
        'Manual',
        'Full details, notes & accounts',
        onManual,
      ),
      _Method(
        Icons.group_add_rounded,
        'Split',
        'Share a bill with friends',
        onSplit,
      ),
      _Method(
        Icons.sms_rounded,
        'Paste SMS',
        'Local UPI / bank SMS parse',
        onSms,
      ),
      _Method(
        Icons.receipt_long_rounded,
        'Receipt',
        'Attach photo, enter amounts',
        onReceipt,
      ),
      _Method(
        Icons.account_balance_rounded,
        'Bank statement',
        'CSV · Excel · PDF import',
        onStatement,
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        for (final m in methods) ...[
          Material(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: m.onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: accent.withValues(alpha: 0.14),
                      ),
                      child: Icon(m.icon, color: accent),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.title,
                            style: GoogleFonts.spaceGrotesk(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            m.subtitle,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 12,
                              color: AppTheme.mutedOf(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: AppTheme.mutedOf(context)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _Method {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _Method(this.icon, this.title, this.subtitle, this.onTap);
}
