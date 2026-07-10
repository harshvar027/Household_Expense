import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/household_member.dart';
import '../models/account.dart';
import '../models/recurring_transaction.dart';
import '../models/goal.dart';
import '../models/merchant_rule.dart';
import '../models/user_profile.dart';
import '../services/entitlement_service.dart';
import '../models/subscription_tier.dart';
import '../widgets/upgrade_prompt.dart';
import '../services/sms_listener_service.dart';
import '../config/region_config.dart';
import '../models/app_region.dart';
import '../models/bank_profile.dart';
import '../services/app_locale_service.dart';
import '../widgets/bank_dropdown_field.dart';
import '../theme/app_theme.dart';
import '../utils/auth_dialogs.dart';
import '../utils/backup_ui.dart';
import '../utils/money_format.dart';
import '../widgets/ui/app_scaffold.dart';
import '../widgets/money_amount.dart';
import 'auth/account_security_screen.dart';

class SettingsScreen extends StatefulWidget {
  final List<String> categories;
  final List<String> paymentMethods;
  final UserProfile? userProfile;
  final Future<void> Function()? onLogout;

  const SettingsScreen({
    super.key,
    required this.categories,
    required this.paymentMethods,
    this.userProfile,
    this.onLogout,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _db = DatabaseHelper.instance;

  List<HouseholdMember> members = [];
  List<Account> accounts = [];
  List<RecurringTransaction> recurring = [];
  List<Goal> goals = [];
  List<MerchantRule> merchantRules = [];
  bool smsQuickEntryEnabled = true;
  bool smsQuickEntrySupported = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadAll();
    _loadSmsSettings();
  }

  Future<void> _loadSmsSettings() async {
    smsQuickEntrySupported = SmsListenerService.instance.isSupported;
    smsQuickEntryEnabled = await SmsListenerService.instance.isEnabled();
    if (mounted) setState(() {});
  }

  Future<void> _loadAll() async {
    members = await _db.getMembers();
    accounts = await _db.getAccounts();
    recurring = await _db.getAllRecurring();
    goals = await _db.getActiveGoals();
    merchantRules = await _db.getMerchantRules();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScreenScaffold(
      title: 'Manage',
      actions: [
        if (widget.onLogout != null)
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              if (!await confirmLogout(context)) return;
              await widget.onLogout!();
            },
          ),
      ],
      bottom: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textMuted,
        indicatorColor: AppColors.primary,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Household'),
          Tab(text: 'Accounts'),
          Tab(text: 'Recurring'),
          Tab(text: 'Goals'),
          Tab(text: 'Data'),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _membersTab(),
          _accountsTab(),
          _recurringTab(),
          _goalsTab(),
          _dataTab(),
        ],
      ),
    );
  }

  Widget _membersTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Tag expenses with who paid. Useful for household tracking.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 12),
        ...members.map(
          (m) => Card(
            child: ListTile(
              leading: CircleAvatar(child: Text(m.name[0])),
              title: Text(m.name),
              subtitle: Text(m.role),
              trailing: m.name == 'Self'
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await _db.deleteMember(m.id!);
                        await _loadAll();
                      },
                    ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _addMember,
          icon: const Icon(Icons.person_add),
          label: const Text('Add member'),
        ),
        if (merchantRules.isNotEmpty) ...[
          const Divider(height: 32),
          const Text(
            'Learned merchant rules',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          ...merchantRules.map(
            (r) => ListTile(
              dense: true,
              title: Text('"${r.pattern}" → ${r.category}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: () async {
                  await _db.deleteMerchantRule(r.id!);
                  await _loadAll();
                },
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _addMember() async {
    final nameCtrl = TextEditingController();
    final roleCtrl = TextEditingController(text: 'Member');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add household member'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: roleCtrl,
              decoration: const InputDecoration(labelText: 'Role'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Add')),
        ],
      ),
    );
    if (ok == true && nameCtrl.text.trim().isNotEmpty) {
      await _db.insertMember(HouseholdMember(
        name: nameCtrl.text.trim(),
        role: roleCtrl.text.trim(),
      ));
      await _loadAll();
    }
  }

  Widget _accountsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Import statements per account. Mark transfers to avoid double-counting.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 12),
        ...accounts.map(
          (a) => Card(
            child: ListTile(
              leading: Icon(
                a.type == 'Credit Card' ? Icons.credit_card : Icons.account_balance,
              ),
              title: Text(a.name),
              subtitle: Text(
                [
                  a.type,
                  if (BankProfile.labelForId(a.bankId).isNotEmpty)
                    BankProfile.labelForId(a.bankId),
                ].join(' · '),
              ),
              trailing: a.isDefault
                  ? const Chip(label: Text('Default'))
                  : IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await _db.deleteAccount(a.id!);
                        await _loadAll();
                      },
                    ),
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _addAccount,
          icon: const Icon(Icons.add),
          label: const Text('Add account'),
        ),
      ],
    );
  }

  Future<void> _addAccount() async {
    final nameCtrl = TextEditingController();
    String type = 'Savings';
    String? bankSlug;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add account'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Account name',
                    hintText: 'e.g. Sangeeta, Joint Savings',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Account type'),
                  items: const [
                    DropdownMenuItem(value: 'Savings', child: Text('Savings')),
                    DropdownMenuItem(value: 'Salary', child: Text('Salary')),
                    DropdownMenuItem(
                      value: 'Credit Card',
                      child: Text('Credit Card'),
                    ),
                    DropdownMenuItem(value: 'Cash', child: Text('Cash Wallet')),
                  ],
                  onChanged: (v) => setDialogState(() => type = v ?? 'Savings'),
                ),
                const SizedBox(height: 12),
                BankDropdownField(
                  value: bankSlug,
                  allowAutoDetect: false,
                  labelText: 'Bank',
                  helperText: 'Statement imports will use this bank\'s format.',
                  onChanged: (v) => setDialogState(() => bankSlug = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
    if (ok == true && nameCtrl.text.trim().isNotEmpty) {
      await _db.insertAccount(
        Account(
          name: nameCtrl.text.trim(),
          type: type,
          bankId: bankSlug,
        ),
      );
      await _loadAll();
    }
  }

  Widget _recurringTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Rent, EMI, salary — auto-created each month. Missing items are flagged on dashboard.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 12),
        ...recurring.map(
          (r) => Card(
            child: ListTile(
              title: Text(r.item),
              subtitle: Text(
                '${r.isIncome ? "Income" : r.category} · day ${r.dayOfMonth}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MoneyAmount(
                    amount: r.amount,
                    flow: r.isIncome ? MoneyFlow.credit : MoneyFlow.debit,
                    fontSize: 14,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await _db.deleteRecurring(r.id!);
                      await _loadAll();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _addRecurring,
          icon: const Icon(Icons.repeat),
          label: const Text('Add recurring'),
        ),
      ],
    );
  }

  Future<void> _addRecurring() async {
    final itemCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String category = widget.categories.first;
    bool isIncome = false;
    int day = 1;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add recurring transaction'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: itemCtrl,
                decoration: const InputDecoration(labelText: 'Name (Rent, Netflix...)'),
              ),
              TextField(
                controller: amountCtrl,
                keyboardType: kMoneyKeyboard,
                inputFormatters: kMoneyInputFormatters,
                decoration: InputDecoration(labelText: 'Amount', prefixText: moneyInputPrefix()),
              ),
              DropdownButtonFormField<String>(
                initialValue: category,
                items: widget.categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => category = v ?? category,
              ),
              SwitchListTile(
                title: const Text('Is income?'),
                value: isIncome,
                onChanged: (v) => isIncome = v,
              ),
              TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Day of month (1-28)'),
                onChanged: (v) => day = int.tryParse(v) ?? 1,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Add')),
        ],
      ),
    );

    if (ok == true && itemCtrl.text.isNotEmpty && amountCtrl.text.isNotEmpty) {
      await _db.insertRecurring(RecurringTransaction(
        item: itemCtrl.text.trim(),
        amount: parseMoney(amountCtrl.text) ?? 0,
        category: category,
        isIncome: isIncome,
        dayOfMonth: day.clamp(1, 28),
      ));
      await _loadAll();
    }
  }

  Widget _goalsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...goals.map(
          (g) => Card(
            child: ListTile(
              title: Text(g.name),
              subtitle: Row(
                children: [
                  MoneyAmount(
                    amount: g.currentAmount,
                    flow: MoneyFlow.credit,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  Text(
                    ' / ${formatMoneyWithCurrency(g.targetAmount)}',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  await _db.deleteGoal(g.id!);
                  await _loadAll();
                },
              ),
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _addGoal,
          icon: const Icon(Icons.flag),
          label: const Text('Add goal'),
        ),
      ],
    );
  }

  Future<void> _addGoal() async {
    final nameCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    final currentCtrl = TextEditingController(text: '0');
    String? linked = widget.categories.contains('Investment')
        ? 'Investment'
        : widget.categories.first;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add savings goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Goal name')),
            TextField(
              controller: targetCtrl,
              keyboardType: kMoneyKeyboard,
              inputFormatters: kMoneyInputFormatters,
              decoration: InputDecoration(labelText: 'Target', prefixText: moneyInputPrefix()),
            ),
            TextField(
              controller: currentCtrl,
              keyboardType: kMoneyKeyboard,
              inputFormatters: kMoneyInputFormatters,
              decoration: InputDecoration(labelText: 'Current saved', prefixText: moneyInputPrefix()),
            ),
            DropdownButtonFormField<String?>(
              initialValue: linked,
              decoration: const InputDecoration(labelText: 'Linked category'),
              items: widget.categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => linked = v,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Add')),
        ],
      ),
    );

    if (ok == true && nameCtrl.text.isNotEmpty && targetCtrl.text.isNotEmpty) {
      await _db.insertGoal(Goal(
        name: nameCtrl.text.trim(),
        targetAmount: parseMoney(targetCtrl.text) ?? 0,
        currentAmount: parseMoney(currentCtrl.text) ?? 0,
        linkedCategory: linked,
      ));
      await _loadAll();
    }
  }

  Widget _dataTab() {
    final profile = widget.userProfile;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (profile != null) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                        child: Text(
                          profile.firstName.isNotEmpty
                              ? profile.firstName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            if (profile.householdName.trim().isNotEmpty)
                              Text(
                                profile.householdName,
                                style: const TextStyle(color: AppColors.textSecondary),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.email_outlined),
                    title: const Text('Email'),
                    subtitle: Text(profile.email),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.phone_android_outlined),
                    title: const Text('Phone'),
                    subtitle: Text(
                      '${RegionConfig.forRegion(AppRegion.fromStorage(profile.region)).phoneDialCode} ${profile.phone}',
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.payments_outlined),
                    title: const Text('Currency'),
                    subtitle: Text(
                      '${profile.currency} (${AppLocaleService.instance.currencySymbol})',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () async {
              final updated = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => AccountSecurityScreen(
                    profile: profile,
                    onLogout: widget.onLogout,
                  ),
                ),
              );
              if (updated == true && context.mounted) {
                Navigator.pop(context, true);
              }
            },
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit account & security'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: widget.onLogout == null
                ? null
                : () async {
                    if (!await confirmLogout(context)) return;
                    await widget.onLogout!();
                  },
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
          ),
          const Divider(height: 24),
        ],
        if (smsQuickEntrySupported) ...[
          SwitchListTile(
            secondary: const Icon(Icons.sms_outlined),
            title: const Text('SMS quick entry'),
            subtitle: const Text(
              'Uses Google SMS User Consent (Play-safe). When a bank SMS arrives, '
              'Android asks you to allow reading that one message, then shows the quick-entry popup.',
            ),
            value: smsQuickEntryEnabled,
            onChanged: (value) async {
              await SmsListenerService.instance.setEnabled(value);
              await _loadSmsSettings();
            },
          ),
          const Divider(),
        ],
        ListTile(
          leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
          title: const Text('Export / Backup / Restore'),
          subtitle: const Text('Use the menu on the home screen for PDF and CSV export'),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.backup),
          title: const Text('Backup all data (JSON)'),
          subtitle: const Text('Save encrypted backup locally or to cloud'),
          onTap: () async {
            if (!await EntitlementService.instance.canAccess(AppFeature.backup)) {
              if (!context.mounted) return;
              await showUpgradePrompt(context, feature: AppFeature.backup);
              return;
            }
            if (!context.mounted) return;
            await runBackupFlow(context);
          },
        ),
        ListTile(
          leading: const Icon(Icons.cloud_upload_outlined),
          title: const Text('Backup to cloud (Drive/Dropbox/Email)'),
          subtitle: const Text('Creates encrypted file and opens share sheet'),
          onTap: () async {
            if (!await EntitlementService.instance.canAccess(AppFeature.backup)) {
              if (!context.mounted) return;
              await showUpgradePrompt(context, feature: AppFeature.backup);
              return;
            }
            if (!context.mounted) return;
            await runCloudBackupFlow(context);
          },
        ),
        ListTile(
          leading: const Icon(Icons.restore, color: Colors.orange),
          title: const Text('Restore from backup'),
          subtitle: const Text('Load encrypted/local backup and replace data'),
          onTap: () async {
            if (!await EntitlementService.instance.canAccess(AppFeature.restore)) {
              if (!context.mounted) return;
              await showUpgradePrompt(context, feature: AppFeature.restore);
              return;
            }
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Restore backup?'),
                content: const Text(
                  'This will replace all expenses, income, budgets, and settings '
                  'from the JSON file. Your PIN is not changed.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    child: const Text('Restore'),
                  ),
                ],
              ),
            );
            if (confirmed != true || !context.mounted) return;
            final ok = await runRestoreFlow(context);
            if (ok && context.mounted) {
              Navigator.pop(context, true);
            }
          },
        ),
      ],
    );
  }
}
