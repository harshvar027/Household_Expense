import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/account.dart';
import '../../../models/household_member.dart';
import '../../../theme/app_theme.dart';
import 'manual_entry_method.dart';

/// Receipt path without cloud OCR — attach a photo note, then manual entry.
class ReceiptAttachMethod extends StatefulWidget {
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

  const ReceiptAttachMethod({
    super.key,
    required this.categories,
    required this.paymentMethods,
    required this.members,
    required this.accounts,
    required this.onCancel,
    required this.onSaveExpense,
    this.defaultMemberId,
    this.defaultAccountId,
  });

  @override
  State<ReceiptAttachMethod> createState() => _ReceiptAttachMethodState();
}

class _ReceiptAttachMethodState extends State<ReceiptAttachMethod> {
  String? _fileName;
  bool _readyForForm = false;

  Future<void> _pick() async {
    final file = await openFile(
      acceptedTypeGroups: [
        const XTypeGroup(
          label: 'images',
          extensions: ['jpg', 'jpeg', 'png', 'webp', 'heic'],
        ),
      ],
    );
    if (file == null) return;
    setState(() {
      _fileName = file.name;
      _readyForForm = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_readyForForm) {
      return ManualEntryMethod(
        categories: widget.categories,
        paymentMethods: widget.paymentMethods,
        members: widget.members,
        accounts: widget.accounts,
        defaultMemberId: widget.defaultMemberId,
        defaultAccountId: widget.defaultAccountId,
        photoNote: _fileName == null ? null : 'Receipt attached: $_fileName',
        onCancel: widget.onCancel,
        onSaveExpense: widget.onSaveExpense,
        onSaveIncome: ({
          required String description,
          required double amount,
          required DateTime date,
        }) async {},
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Cloud receipt OCR is skipped to keep Household Expense fully on-device. Attach a photo for your records, then enter the amount yourself.',
            style: GoogleFonts.spaceGrotesk(
              height: 1.45,
              color: AppTheme.mutedOf(context),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _pick,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Choose receipt photo'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => setState(() => _readyForForm = true),
            icon: const Icon(Icons.edit_rounded),
            label: const Text('Skip photo — enter manually'),
          ),
          const Spacer(),
          TextButton(onPressed: widget.onCancel, child: const Text('Back')),
        ],
      ),
    );
  }
}
