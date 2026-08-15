import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/household_member.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/money_format.dart';

class SplitPaymentMethod extends StatefulWidget {
  final List<String> categories;
  final List<String> paymentMethods;
  final List<HouseholdMember> members;
  final VoidCallback onCancel;
  final Future<void> Function({
    required String item,
    required double amount,
    required String category,
    required String paymentMethod,
    required DateTime date,
    required String notes,
  }) onSave;

  const SplitPaymentMethod({
    super.key,
    required this.categories,
    required this.paymentMethods,
    required this.members,
    required this.onCancel,
    required this.onSave,
  });

  @override
  State<SplitPaymentMethod> createState() => _SplitPaymentMethodState();
}

class _SplitPaymentMethodState extends State<SplitPaymentMethod> {
  static const _friendsKey = 'he_split_friends';

  final _title = TextEditingController();
  final _total = TextEditingController();
  final _newFriend = TextEditingController();

  List<String> _friends = [];
  final _selected = <String>{};
  bool _includeMe = true;
  late String _category =
      widget.categories.isNotEmpty ? widget.categories.first : 'Food';
  late String _payment =
      widget.paymentMethods.isNotEmpty ? widget.paymentMethods.first : 'UPI';
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadFriends();
    for (final m in widget.members) {
      if (m.name.trim().isNotEmpty) _selected.add(m.name.trim());
    }
  }

  Future<void> _loadFriends() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_friendsKey) ?? [];
    if (!mounted) return;
    setState(() => _friends = raw);
  }

  Future<void> _persistFriends() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_friendsKey, _friends);
  }

  @override
  void dispose() {
    _title.dispose();
    _total.dispose();
    _newFriend.dispose();
    super.dispose();
  }

  int get _peopleCount => _selected.length + (_includeMe ? 1 : 0);

  Future<void> _save() async {
    final title = _title.text.trim();
    final total = parseMoney(_total.text) ?? 0;
    if (title.isEmpty || total <= 0 || _peopleCount <= 0 || _saving) return;
    setState(() => _saving = true);
    try {
      final share = total / _peopleCount;
      final names = [
        if (_includeMe) 'You',
        ..._selected,
      ].join(', ');
      await widget.onSave(
        item: title,
        amount: share,
        category: _category,
        paymentMethod: _payment,
        date: _date,
        notes: 'Split $peopleCount ways with $names · total ${formatMoney(total)}',
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  int get peopleCount => _peopleCount;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        TextField(
          controller: _title,
          decoration: const InputDecoration(labelText: 'What was split?'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _total,
          keyboardType: kMoneyKeyboard,
          inputFormatters: kMoneyInputFormatters,
          decoration: const InputDecoration(labelText: 'Total amount', prefixText: '₹ '),
        ),
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
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Include me'),
          value: _includeMe,
          onChanged: (v) => setState(() => _includeMe = v),
        ),
        Text(
          'Friends',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final name in {...widget.members.map((m) => m.name), ..._friends})
              FilterChip(
                label: Text(name),
                selected: _selected.contains(name),
                onSelected: (sel) {
                  setState(() {
                    if (sel) {
                      _selected.add(name);
                    } else {
                      _selected.remove(name);
                    }
                  });
                },
              ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _newFriend,
                decoration: const InputDecoration(labelText: 'Add friend name'),
              ),
            ),
            IconButton(
              onPressed: () async {
                final name = _newFriend.text.trim();
                if (name.isEmpty) return;
                setState(() {
                  if (!_friends.contains(name)) _friends = [..._friends, name];
                  _selected.add(name);
                  _newFriend.clear();
                });
                await _persistFriends();
              },
              icon: const Icon(Icons.add_circle_rounded),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          _peopleCount > 0
              ? 'Your share: ₹${formatMoney((parseMoney(_total.text) ?? 0) / _peopleCount)} · $_peopleCount people'
              : 'Select at least one person',
          style: GoogleFonts.spaceGrotesk(color: AppTheme.mutedOf(context)),
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving…' : 'Save my share'),
        ),
        TextButton(onPressed: widget.onCancel, child: const Text('Back')),
      ],
    );
  }
}
