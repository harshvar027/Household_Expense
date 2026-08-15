import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/sms_transaction_parser.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/neo_palette.dart';

class SmsPasteMethod extends StatefulWidget {
  final List<String> categories;
  final List<String> paymentMethods;
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
  }) onSave;

  const SmsPasteMethod({
    super.key,
    required this.categories,
    required this.paymentMethods,
    required this.onCancel,
    required this.onSave,
  });

  @override
  State<SmsPasteMethod> createState() => _SmsPasteMethodState();
}

class _SmsPasteMethodState extends State<SmsPasteMethod> {
  final _text = TextEditingController();
  bool _busy = false;
  String? _error;

  late String _category =
      widget.categories.isNotEmpty ? widget.categories.first : 'Other';
  late String _payment =
      widget.paymentMethods.isNotEmpty ? widget.paymentMethods.first : 'UPI';

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) return;
    setState(() => _text.text = text);
  }

  Future<void> _parseAndSave() async {
    final sms = _text.text.trim();
    if (sms.isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final parsed = SmsTransactionParser.parse(sms);
      if (parsed == null) {
        setState(() => _error = 'Could not detect a transaction in that SMS.');
        return;
      }
      final desc = parsed.description.trim().isEmpty
          ? 'SMS transaction'
          : parsed.description.trim();
      final payment = parsed.paymentMethod.isNotEmpty
          ? parsed.paymentMethod
          : _payment;
      final category = widget.categories.contains(parsed.suggestedCategory)
          ? parsed.suggestedCategory
          : _category;
      await widget.onSave(
        item: parsed.isDebit ? desc : 'Credit: $desc',
        amount: parsed.amount,
        category: category,
        paymentMethod: payment,
        date: parsed.date,
        notes: 'Imported from pasted SMS',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        Text(
          'Paste a UPI or bank debit/credit SMS. Parsing runs fully on-device — nothing is uploaded.',
          style: GoogleFonts.spaceGrotesk(
            color: AppTheme.mutedOf(context),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _text,
          minLines: 5,
          maxLines: 10,
          decoration: const InputDecoration(
            labelText: 'Payment SMS',
            alignLabelWithHint: true,
            hintText: 'e.g. Rs.450.00 debited from A/c XX1234 at SWIGGY via UPI…',
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _busy ? null : _paste,
            icon: const Icon(Icons.content_paste_rounded, size: 18),
            label: const Text('Paste from clipboard'),
          ),
        ),
        DropdownButtonFormField<String>(
          initialValue: widget.categories.contains(_category)
              ? _category
              : (widget.categories.isNotEmpty ? widget.categories.first : null),
          decoration: const InputDecoration(labelText: 'Fallback category'),
          items: widget.categories
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _category = v);
          },
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!, style: const TextStyle(color: NeoPalette.expenseNeon)),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _busy ? null : _parseAndSave,
          child: Text(_busy ? 'Parsing…' : 'Parse & save'),
        ),
        TextButton(onPressed: widget.onCancel, child: const Text('Back')),
      ],
    );
  }
}
