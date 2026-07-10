import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../exceptions/pdf_password_exception.dart';
import '../models/account.dart';
import '../models/bank_profile.dart';
import '../services/app_locale_service.dart';
import '../services/statement_import_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/bank_dropdown_field.dart';
import '../widgets/ui/app_scaffold.dart';
import '../widgets/ui/finance_illustration.dart';
import '../widgets/ui/glass_surface.dart';
import '../widgets/ui/stagger_animate.dart';
import 'import_preview_screen.dart';

class ImportStatementScreen extends StatefulWidget {
  const ImportStatementScreen({super.key});

  @override
  State<ImportStatementScreen> createState() => _ImportStatementScreenState();
}

class _ImportStatementScreenState extends State<ImportStatementScreen> {
  List<Account> accounts = [];
  int? selectedAccountId;
  String? selectedBankSlug;
  bool loadingAccounts = true;
  bool picking = false;
  String? loadError;

  BankId? get _importBankId =>
      BankProfile.importBankIdFromStorage(selectedBankSlug);

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    try {
      accounts = await DatabaseHelper.instance
          .getAccounts()
          .timeout(const Duration(seconds: 10));
      if (accounts.isNotEmpty) {
        selectedAccountId = accounts
                .where((a) => a.isDefault)
                .map((a) => a.id)
                .firstOrNull ??
            accounts.first.id;
        _syncBankFromAccount();
      } else {
        final profile = await AuthService.instance.getProfile();
        selectedBankSlug = profile?.primaryBankId;
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Failed to load accounts: $e');
        debugPrintStack(stackTrace: stackTrace);
      }
      loadError = 'Could not load accounts. You can still import a statement.';
    } finally {
      if (mounted) {
        setState(() => loadingAccounts = false);
      }
    }
  }

  String? get _selectedAccountName {
    if (selectedAccountId == null) return null;
    for (final account in accounts) {
      if (account.id == selectedAccountId) return account.name;
    }
    return null;
  }

  String get _selectedBankLabel {
    if (selectedBankSlug == null || selectedBankSlug!.isEmpty) {
      return 'Auto-detect from file';
    }
    return BankProfile.labelForId(selectedBankSlug);
  }

  void _syncBankFromAccount() {
    if (selectedAccountId == null) return;
    for (final account in accounts) {
      if (account.id == selectedAccountId) {
        selectedBankSlug = account.bankId;
        return;
      }
    }
  }

  Future<void> pickStatement() async {
    if (picking) return;

    setState(() => picking = true);
    try {
      final service = StatementImportService();
      final picked = await service.pickStatementFile();

      if (picked == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No file selected')),
        );
        return;
      }

      await _importPickedFile(service, picked);
    } catch (e, stackTrace) {
      _showImportError(e, stackTrace);
    } finally {
      if (mounted) setState(() => picking = false);
    }
  }

  Future<void> _importPickedFile(
    StatementImportService service,
    PickedStatementFile picked, {
    String? pdfPassword,
  }) async {
    try {
      final transactions = await service.importStatement(
        picked,
        pdfPassword: pdfPassword,
        bankId: _importBankId,
      );

      if (!mounted) return;

      final imported = await Navigator.push<bool>(
        context,
        appPageRoute(
          ImportPreviewScreen(
            transactions: transactions,
            accountId: selectedAccountId,
            accountName: _selectedAccountName,
            bankId: _importBankId,
            bankLabel: _selectedBankLabel,
          ),
        ),
      );

      if (imported == true) {
        if (!mounted) return;
        Navigator.pop(context, true);
      }
    } on PdfPasswordException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).clearSnackBars();

      final password = await _promptPdfPassword(
        incorrect: e.passwordProvided,
      );
      if (password == null || password.isEmpty) return;

      await _importPickedFile(service, picked, pdfPassword: password);
    }
  }

  Future<String?> _promptPdfPassword({required bool incorrect}) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: false,
      enableDrag: false,
      builder: (dialogContext) => _PdfPasswordDialog(incorrect: incorrect),
    );
  }

  void _showImportError(Object e, StackTrace stackTrace) {
    if (kDebugMode) {
      debugPrint('IMPORT ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);
    }

    if (!mounted) return;

    final message = switch (e) {
      PdfPasswordException(:final message) => message,
      Exception() => e.toString().replaceFirst('Exception: ', ''),
      _ => 'Import failed. Please try another file.',
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScreenScaffold(
      title: 'Import Statement',
      scrollBody: true,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeroBanner().staggerIn(index: 0),
            const SizedBox(height: 20),
            GlassSurface.card(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Link to account',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Choose which account this statement belongs to. '
                    'Transfers between your own accounts can be marked after import.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.45,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (loadingAccounts)
                    const LinearProgressIndicator(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    )
                  else if (loadError != null)
                    Text(
                      loadError!,
                      style: const TextStyle(color: AppColors.expense),
                    )
                  else if (accounts.isEmpty)
                    const Text(
                      'No accounts found. A default account will be used.',
                      style: TextStyle(color: AppColors.warning),
                    )
                  else
                    DropdownButtonFormField<int>(
                      initialValue: selectedAccountId,
                      decoration: const InputDecoration(
                        labelText: 'Account',
                        prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                      ),
                      items: accounts
                          .map(
                            (a) => DropdownMenuItem(
                              value: a.id,
                              child: Text('${a.name} (${a.type})'),
                            ),
                          )
                          .toList(),
                      onChanged: picking
                          ? null
                          : (v) => setState(() {
                                selectedAccountId = v;
                                _syncBankFromAccount();
                              }),
                    ),
                ],
              ),
            ).staggerIn(index: 1),
            const SizedBox(height: 14),
            GlassSurface.card(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Statement bank',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Pick your bank so the correct statement format is used. '
                    'This is saved on the account for next time.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.45,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  BankDropdownField(
                    value: selectedBankSlug,
                    enabled: !picking,
                    labelText: 'Bank format',
                    helperText: selectedBankSlug == null
                        ? 'Auto-detect works for many files; choose your bank if import looks wrong.'
                        : 'Using $_selectedBankLabel layout.',
                    onChanged: (bankSlug) =>
                        setState(() => selectedBankSlug = bankSlug),
                  ),
                ],
              ),
            ).staggerIn(index: 2),
            const SizedBox(height: 14),
            _SupportedFormatsCard().staggerIn(index: 3),
            const SizedBox(height: 24),
            PrimaryActionButton(
              onPressed: pickStatement,
              loading: picking,
              icon: Icons.upload_file_rounded,
              label: picking ? 'Waiting for file…' : 'Choose CSV, Excel or PDF',
            ).staggerIn(index: 4),
          ],
        ),
      ),
    );
  }
}

class _SupportedFormatsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlassSurface.card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.folder_open_rounded, color: AppColors.primary, size: 22),
              SizedBox(width: 10),
              Text(
                'Supported formats',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FormatChip(
                icon: Icons.table_chart_rounded,
                label: 'CSV',
                color: AppColors.income,
              ),
              _FormatChip(
                icon: Icons.grid_on_rounded,
                label: 'Excel (.xls/.xlsx)',
                color: AppColors.savings,
              ),
              _FormatChip(
                icon: Icons.picture_as_pdf_rounded,
                label: 'PDF',
                color: AppColors.expense,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Pick a bank statement from Downloads or Files. PDFs with a text layer '
            'are read automatically — password-protected PDFs will ask for the password. '
            'Expenses, income, and investments are detected from each transaction. '
            'Scanned/image-only PDFs are not supported.',
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocaleService.instance.config.importBankSummary,
            style: const TextStyle(
              fontSize: 12,
              height: 1.4,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FormatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _FormatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.heroGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bank import',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Import your\nbank statement',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    letterSpacing: -0.6,
                  ),
                ),
              ],
            ),
          ),
          const FinanceIllustration(
            type: FinanceIllustrationType.empty,
            size: 80,
          ),
        ],
      ),
    );
  }
}

class _PdfPasswordDialog extends StatefulWidget {
  const _PdfPasswordDialog({required this.incorrect});

  final bool incorrect;

  @override
  State<_PdfPasswordDialog> createState() => _PdfPasswordDialogState();
}

class _PdfPasswordDialogState extends State<_PdfPasswordDialog> {
  late final TextEditingController _controller;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.pop(context, _controller.text);

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: viewInsets.bottom + bottomPadding + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'PDF password',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.incorrect
                ? 'That password did not work. Try again.'
                : 'This statement PDF is password-protected.',
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'PDF password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _submit,
                  child: const Text('Unlock'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
