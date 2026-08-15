import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/account.dart';
import '../../../models/household_member.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/money_format.dart';

class ManualEntryMethod extends StatefulWidget {
  final List<String> categories;
  final List<String> paymentMethods;
  final List<HouseholdMember> members;
  final List<Account> accounts;
  final int? defaultMemberId;
  final int? defaultAccountId;
  final VoidCallback onCancel;
  final Future<void> Function({
    required String item,
    required double amount,
    required String category,
    required String paymentMethod,
    required DateTime date,
    String notes,
    bool isTransfer,
    int? memberId,
    int? accountId,
  }) onSaveExpense;
  final Future<void> Function({
    required String description,
    required double amount,
    required DateTime date,
  }) onSaveIncome;
  final String? initialItem;
  final double? initialAmount;
  final String? initialNotes;
  final String? photoNote;

  const ManualEntryMethod({
    super.key,
    required this.categories,
    required this.paymentMethods,
    required this.members,
    required this.accounts,
    required this.onCancel,
    required this.onSaveExpense,
    required this.onSaveIncome,
    this.defaultMemberId,
    this.defaultAccountId,
    this.initialItem,
    this.initialAmount,
    this.initialNotes,
    this.photoNote,
  });

  @override
  State<ManualEntryMethod> createState() => _ManualEntryMethodState();
}

class _ManualEntryMethodState extends State<ManualEntryMethod> {
  late final _item = TextEditingController(text: widget.initialItem ?? '');
  late final _amount = TextEditingController(
    text: widget.initialAmount != null ? formatMoney(widget.initialAmount!) : '',
  );
  late final _notes = TextEditingController(
    text: [
      if (widget.photoNote != null && widget.photoNote!.isNotEmpty) widget.photoNote,
      if (widget.initialNotes != null && widget.initialNotes!.isNotEmpty)
        widget.initialNotes,
    ].whereType<String>().join('\n'),
  );

  late String _type = 'expense';
  late String _category = widget.categories.isNotEmpty ? widget.categories.first : 'Other';
  late String _payment =
      widget.paymentMethods.isNotEmpty ? widget.paymentMethods.first : 'UPI';
  late DateTime _date = DateTime.now();
  late int? _memberId = widget.defaultMemberId;
  late int? _accountId = widget.defaultAccountId;
  bool _isTransfer = false;
  bool _saving = false;

  @override
  void dispose() {
    _item.dispose();
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _item.text.trim();
    final amt = parseMoney(_amount.text) ?? 0;
    if (title.isEmpty || amt <= 0 || _saving) return;
    setState(() => _saving = true);
    try {
      if (_type == 'income') {
        await widget.onSaveIncome(
          description: title,
          amount: amt,
          date: _date,
        );
      } else {
        await widget.onSaveExpense(
          item: title,
          amount: amt,
          category: _category,
          paymentMethod: _payment,
          date: _date,
          notes: _notes.text.trim(),
          isTransfer: _isTransfer,
          memberId: _memberId,
          accountId: _accountId,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'expense', label: Text('Expense'), icon: Icon(Icons.south_west_rounded, size: 16)),
            ButtonSegment(value: 'income', label: Text('Income'), icon: Icon(Icons.north_east_rounded, size: 16)),
          ],
          selected: {_type},
          onSelectionChanged: (s) => setState(() => _type = s.first),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _item,
          decoration: InputDecoration(
            labelText: _type == 'income' ? 'Description' : 'Item / merchant',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _amount,
          keyboardType: kMoneyKeyboard,
          inputFormatters: kMoneyInputFormatters,
          decoration: const InputDecoration(labelText: 'Amount', prefixText: '₹ '),
        ),
        if (_type == 'expense') ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: widget.categories.contains(_category)
                ? _category
                : (widget.categories.isNotEmpty ? widget.categories.first : null),
            decoration: const InputDecoration(labelText: 'Category'),
            items: widget.categories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _category = v);
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: widget.paymentMethods.contains(_payment)
                ? _payment
                : (widget.paymentMethods.isNotEmpty ? widget.paymentMethods.first : null),
            decoration: const InputDecoration(labelText: 'Payment'),
            items: widget.paymentMethods
                .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _payment = v);
            },
          ),
          if (widget.members.isNotEmpty) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              initialValue: _memberId,
              decoration: const InputDecoration(labelText: 'Member'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Unassigned')),
                ...widget.members.map(
                  (m) => DropdownMenuItem(value: m.id, child: Text(m.name)),
                ),
              ],
              onChanged: (v) => setState(() => _memberId = v),
            ),
          ],
          if (widget.accounts.isNotEmpty) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              initialValue: _accountId,
              decoration: const InputDecoration(labelText: 'Account'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Default')),
                ...widget.accounts.map(
                  (a) => DropdownMenuItem(value: a.id, child: Text(a.name)),
                ),
              ],
              onChanged: (v) => setState(() => _accountId = v),
            ),
          ],
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Mark as transfer'),
            value: _isTransfer,
            onChanged: (v) => setState(() => _isTransfer = v),
          ),
        ],
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Date'),
          subtitle: Text(
            '${_date.day}/${_date.month}/${_date.year}',
            style: GoogleFonts.spaceGrotesk(color: AppTheme.mutedOf(context)),
          ),
          trailing: const Icon(Icons.calendar_month_rounded),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _date,
              firstDate: DateTime(2018),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) setState(() => _date = picked);
          },
        ),
        TextField(
          controller: _notes,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Notes',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving…' : 'Save'),
        ),
        TextButton(onPressed: widget.onCancel, child: const Text('Back')),
      ],
    );
  }
}
