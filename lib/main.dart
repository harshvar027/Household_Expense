import 'dart:async';

import 'dart:io';

import 'models/expense.dart';
import 'database/database_helper.dart';
import 'package:flutter/material.dart';
import 'widgets/category_expenses_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'utils/auth_dialogs.dart';
import 'utils/backup_ui.dart';
import 'utils/category_utils.dart';
import 'utils/money_format.dart';
import 'utils/expense_filter_utils.dart';
import 'widgets/expense_filter_bar.dart';
import 'models/income.dart';
import 'models/household_member.dart';
import 'models/account.dart';
import 'models/bank_profile.dart';
import 'models/goal.dart';
import 'models/recurring_transaction.dart';
import 'screens/import_statement_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/add_expense_screen.dart';
import 'screens/budget_screen.dart';
import 'screens/tabs/home_tab.dart';
import 'screens/tabs/expenses_tab.dart';
import 'screens/tabs/analytics_tab.dart';
import 'screens/tabs/menu_tab.dart';
import 'theme/app_theme.dart';
import 'theme/neo_palette.dart';
import 'widgets/ui/mesh_background.dart';
import 'widgets/ui/premium_bottom_nav.dart';
import 'widgets/ui/glass_fab.dart';
import 'services/insights_service.dart';
import 'services/export_service.dart';
import 'services/recurring_service.dart';
import 'services/merchant_rule_service.dart';
import 'services/balance_service.dart';
import 'services/sms_listener_service.dart';
import 'services/sms_transaction_parser.dart';
import 'models/parsed_sms_transaction.dart';
import 'widgets/quick_transaction_dialog.dart';
import 'screens/auth/auth_gate.dart';
import 'screens/auth/account_security_screen.dart';
import 'services/auth_service.dart';
import 'services/app_locale_service.dart';
import 'models/user_profile.dart';
import 'services/ad_service.dart';
import 'widgets/ads/bottom_ad_ribbon.dart';
import 'screens/help_about_screen.dart';
import 'screens/feedback_screen.dart';
import 'screens/subscription_screen.dart';
import 'services/entitlement_service.dart';
import 'models/subscription_tier.dart';
import 'widgets/upgrade_prompt.dart';
import 'utils/responsive_layout.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && Platform.isAndroid) {
    await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }
  runApp(const ExpenseTrackerApp());
  // Initialize ads after first frame — never block app launch.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(AdService.initialize());
  });
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: rootNavigatorKey,
      title: 'Household Expense Tracker !!',

      theme: AppTheme.light,
      darkTheme: AppTheme.light,
      themeMode: ThemeMode.dark,
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: mq.textScaler.clamp(
              minScaleFactor: 0.9,
              maxScaleFactor: 1.35,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: AuthGate(
        authenticatedBuilder: (_) => const ExpenseScreen(),
      ),
    );
  }
}

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> with WidgetsBindingObserver {
  final TextEditingController itemController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  Map<String, double> categoryTotals = {};
  double monthlyIncome = 0;
  double manualIncome = 0;
  double importedIncome = 0;
  double broughtForwardIncome = 0;
  double totalExpenses = 0;
  double investmentTotal = 0;
  Map<String, double> investmentTotals = {};
  double monthlyBudget = 0;
  double savings = 0;
  double balance = 0;
  String selectedMonth =
      "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}";

  String selectedCategory = '';
  String selectedPaymentMethod = 'UPI';
  DateTime selectedDate = DateTime.now();
  String savedItem = '';
  String savedAmount = '';
  String savedCategory = '';
  List<Expense> expenses = [];
  List<Income> incomes = [];
  List<String> categories = [];
  List<Map<String, String>> months = [];
  Map<String, double> monthlyExpenseTotals = {};
  Map<String, double> categoryBudgets = {};
  Map<String, double> memberSpending = {};
  List<HouseholdMember> members = [];
  List<Account> accounts = [];
  List<Goal> goals = [];
  List<RecurringTransaction> missingRecurring = [];
  List<Insight> insights = [];
  UserProfile? userProfile;
  EntitlementStatus? entitlement;
  ExpenseFilterState expenseFilter = ExpenseFilterState();
  int? selectedMemberId;
  int? selectedAccountId;
  bool dismissMissingBanner = false;
  int _currentTab = 0;
  late final PageController _pageController = PageController();
  final Set<String> shownBudgetAlerts = {};
  StreamSubscription<ParsedSmsTransaction>? _smsSubscription;
  final List<ParsedSmsTransaction> _pendingSmsDialogs = [];
  bool _smsDialogOpen = false;
  bool _appReady = false;
  List<String> get paymentMethods =>
      AppLocaleService.instance.config.paymentMethods;
  final List<Color> barColors = NeoPalette.categoryNeons(12);
  Future<void> loadExpenses() async {
    final data = await DatabaseHelper.instance.getAllExpenses();

    expenses = data;

    await calculateSummary();

    if (!mounted) return;

    setState(() {});
  }

  Future<void> loadCategories() async {
    await DatabaseHelper.instance.ensureDefaultCategories();
    categories = await DatabaseHelper.instance.getCategories();
    categories.sort();

    if (categories.isNotEmpty && selectedCategory.isEmpty) {
      selectedCategory = categories.first;
    }

    setState(() {});
  }

  Future<void> loadIncomes() async {
    incomes = await DatabaseHelper.instance.getAllIncome();

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> loadIncome() async {
    manualIncome = await DatabaseHelper.instance.getCurrentMonthIncome(
      selectedMonth,
    );
    importedIncome = await DatabaseHelper.instance.getImportedIncome(
      selectedMonth,
    );
    broughtForwardIncome =
        await DatabaseHelper.instance.getBalanceBroughtForwardAmount(
      selectedMonth,
    );
    monthlyIncome = manualIncome + importedIncome + broughtForwardIncome;

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> refreshDashboard({bool syncBalance = true}) async {
    if (syncBalance) {
      await BalanceService.syncAdjacentMonths(selectedMonth);
    }

    await Future.wait([
      loadExpenses(),
      loadIncomes(),
      loadMonthlyExpenseTotals(),
    ]);

    await Future.wait([
      loadIncome(),
      loadBudget(),
      loadCategoryBudgets(),
      loadGoals(),
    ]);

    await processRecurringForMonth();
    await calculateSummary();
    _generateInsights();
    _checkBudgetAlerts();
    userProfile = await AuthService.instance.getProfile();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _refreshAfterBudgetOrIncome() async {
    await Future.wait([
      loadIncome(),
      loadIncomes(),
    ]);
    await calculateSummary();
    _generateInsights();
    if (mounted) setState(() {});
  }

  Future<void> loadMembersAndAccounts() async {
    members = await DatabaseHelper.instance.getMembers();
    accounts = await DatabaseHelper.instance.getAccounts();
    selectedMemberId ??= members.isNotEmpty ? members.first.id : null;
    final defaultAccount = await DatabaseHelper.instance.getDefaultAccount();
    selectedAccountId ??= defaultAccount?.id;
  }

  int? _resolveMemberId(int? id) {
    if (members.isEmpty) return null;
    if (id != null && members.any((m) => m.id == id)) return id;
    return members.first.id;
  }

  int? _resolveAccountId(int? id) {
    if (accounts.isEmpty) return null;
    if (id != null && accounts.any((a) => a.id == id)) return id;
    return accounts.first.id;
  }

  Map<int, String> get accountNamesById {
    return {
      for (final account in accounts)
        if (account.id != null) account.id!: account.name,
    };
  }

  Map<int, String> get accountBankLabelsById {
    return {
      for (final account in accounts)
        if (account.id != null)
          account.id!: BankProfile.labelForId(account.bankId),
    };
  }

  Future<void> loadCategoryBudgets() async {
    categoryBudgets =
        await DatabaseHelper.instance.getCategoryBudgets(selectedMonth);
  }

  Future<void> loadGoals() async {
    goals = await DatabaseHelper.instance.getActiveGoals();
  }

  Future<void> saveCategoryBudget(String category, double amount) async {
    await DatabaseHelper.instance.setCategoryBudget(
      selectedMonth,
      category,
      amount,
    );
    await loadCategoryBudgets();
    if (mounted) setState(() {});
  }

  Future<void> processRecurringForMonth() async {
    missingRecurring =
        await RecurringService.instance.processMonth(selectedMonth);
    dismissMissingBanner = false;
  }

  void _generateInsights() {
    insights = InsightsService().generate(
      selectedMonth: selectedMonth,
      allExpenses: expenses,
      categoryTotals: categoryTotals,
      totalExpenses: totalExpenses,
      monthlyBudget: monthlyBudget,
      categoryBudgets: categoryBudgets,
    );
  }

  void _checkBudgetAlerts() {
    if (!mounted) return;

    if (monthlyBudget > 0) {
      final ratio = totalExpenses / monthlyBudget;
      final key = 'total_$selectedMonth';
      if (ratio >= 1 && !shownBudgetAlerts.contains('${key}_100')) {
        shownBudgetAlerts.add('${key}_100');
        _showBudgetSnack('Monthly budget exceeded!');
      } else if (ratio >= 0.8 && !shownBudgetAlerts.contains('${key}_80')) {
        shownBudgetAlerts.add('${key}_80');
        _showBudgetSnack(
          'You have used ${(ratio * 100).toStringAsFixed(0)}% of monthly budget.',
        );
      }
    }

    for (final entry in categoryBudgets.entries) {
      if (CategoryUtils.isSavingsCategory(entry.key)) continue;
      final spent = categoryTotals[entry.key] ?? 0;
      if (entry.value <= 0) continue;
      final ratio = spent / entry.value;
      final key = 'cat_${entry.key}_$selectedMonth';
      if (ratio >= 1 && !shownBudgetAlerts.contains('${key}_100')) {
        shownBudgetAlerts.add('${key}_100');
        _showBudgetSnack('${entry.key} budget exceeded!');
      }
    }
  }

  void _showBudgetSnack(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.orange.shade800),
      );
    });
  }

  Future<void> deleteSelectedMonthData() async {
    final monthLabel = getSelectedMonthLabel();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this month’s data?'),
        content: Text(
          'This will delete expenses, income, category budgets, and bank imports '
          'for $monthLabel only.\n\n'
          'Other months stay unchanged. Balance brought forward for later months '
          'will be recalculated automatically.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete month'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final month = selectedMonth;
    final counts = await DatabaseHelper.instance.deleteMonthData(month);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('budget_$month');
    final alertKeys = prefs
        .getKeys()
        .where((k) => k.contains(month))
        .where((k) => k.startsWith('total_') || k.startsWith('cat_'))
        .toList();
    for (final key in alertKeys) {
      await prefs.remove(key);
    }
    shownBudgetAlerts.removeWhere((k) => k.contains(month));

    await BalanceService.resyncAfterMonthDelete(month);
    await refreshDashboard();

    if (!mounted) return;

    final deleted =
        (counts['expenses'] ?? 0) +
        (counts['income'] ?? 0) +
        (counts['categoryBudgets'] ?? 0) +
        (counts['bankTransactions'] ?? 0);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          deleted == 0
              ? 'No $monthLabel records to delete. Carry forward updated.'
              : 'Deleted $monthLabel data '
                  '(${counts['expenses']} expenses, '
                  '${counts['income']} income). Carry forward updated.',
        ),
      ),
    );
  }

  Future<void> resetAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all data?'),
        content: const Text(
          'This will delete all expenses, income, and bank imports. '
          'Categories will be reset to defaults.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await DatabaseHelper.instance.resetDatabase();
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('budget_'));
    for (final key in keys) {
      await prefs.remove(key);
    }
    manualIncome = 0;
    importedIncome = 0;
    broughtForwardIncome = 0;
    monthlyIncome = 0;

    await refreshDashboard();
    await loadCategories();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Database cleared. Ready for CSV import.')),
    );
  }

  Future<void> calculateSummary() async {
    double spendingTotal = 0;
    double investments = 0;
    Map<String, double> totals = {};
    Map<String, double> savingsBreakdown = {};

    for (var expense in expenses) {
      final expenseMonth = expense.expenseDate.substring(0, 7);

      if (expenseMonth != selectedMonth) continue;
      if (expense.isTransfer) continue;

      if (CategoryUtils.isSavingsCategory(expense.category)) {
        investments += expense.amount;
        savingsBreakdown[expense.category] =
            (savingsBreakdown[expense.category] ?? 0) + expense.amount;
        continue;
      }

      spendingTotal += expense.amount;
      totals[expense.category] =
          (totals[expense.category] ?? 0) + expense.amount;
    }

    manualIncome = await DatabaseHelper.instance.getCurrentMonthIncome(
      selectedMonth,
    );
    importedIncome = await DatabaseHelper.instance.getImportedIncome(
      selectedMonth,
    );
    broughtForwardIncome =
        await DatabaseHelper.instance.getBalanceBroughtForwardAmount(
      selectedMonth,
    );
    monthlyIncome = manualIncome + importedIncome + broughtForwardIncome;

    totalExpenses = spendingTotal;
    investmentTotal = investments;
    investmentTotals = savingsBreakdown;
    savings = investmentTotal;
    balance = monthlyIncome - totalExpenses - investmentTotal;
    categoryTotals = totals;
    memberSpending =
        await DatabaseHelper.instance.getMemberSpending(selectedMonth);

    for (final goal in goals) {
      if (goal.linkedCategory != null) {
        final linked = investmentTotals[goal.linkedCategory!] ?? 0;
        if (linked > goal.currentAmount && goal.id != null) {
          await DatabaseHelper.instance.updateGoal(
            Goal(
              id: goal.id,
              name: goal.name,
              targetAmount: goal.targetAmount,
              currentAmount: linked,
              deadline: goal.deadline,
              linkedCategory: goal.linkedCategory,
            ),
          );
        }
      }
    }
    goals = await DatabaseHelper.instance.getActiveGoals();
  }

  String getHighestCategory() {
    if (categoryTotals.isEmpty) return "-";

    return categoryTotals.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  double getLargestExpense() {
    final monthlyExpenses = expenses.where(
      (e) =>
          e.expenseDate.substring(0, 7) == selectedMonth &&
          !CategoryUtils.isSavingsCategory(e.category),
    );

    if (monthlyExpenses.isEmpty) return 0;

    return monthlyExpenses.map((e) => e.amount).reduce((a, b) => a > b ? a : b);
  }

  int getTransactionCount() {
    return expenses
        .where(
          (e) =>
              e.expenseDate.substring(0, 7) == selectedMonth &&
              !CategoryUtils.isSavingsCategory(e.category),
        )
        .length;
  }

  double getBudgetUsed() {
    if (monthlyBudget == 0) return 0;

    return (totalExpenses / monthlyBudget) * 100;
  }

  Future<void> loadMonthlyExpenseTotals() async {
    monthlyExpenseTotals = await DatabaseHelper.instance
        .getMonthlyExpenseTotals();

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        AppLocaleService.instance.config.supportsSmsQuickEntry) {
      unawaited(SmsListenerService.instance.resumeIfEnabled());
    }
  }

  Future<void> _startSmsQuickEntry() async {
    if (!AppLocaleService.instance.config.supportsSmsQuickEntry) return;
    await SmsListenerService.instance.start();
    await _smsSubscription?.cancel();
    _smsSubscription = SmsListenerService.instance.transactions.listen(
      _queueSmsTransaction,
    );
  }

  void _queueSmsTransaction(ParsedSmsTransaction parsed) {
    _pendingSmsDialogs.add(parsed);
    unawaited(_showNextSmsDialog());
  }

  Future<void> _showNextSmsDialog() async {
    if (_smsDialogOpen || _pendingSmsDialogs.isEmpty || !mounted) return;

    final parsed = _pendingSmsDialogs.removeAt(0);
    final enriched = await SmsTransactionParser.withCategory(parsed, categories);

    final dialogContext = rootNavigatorKey.currentContext ?? context;
    if (!dialogContext.mounted) return;

    _smsDialogOpen = true;
    final result = await showQuickTransactionDialog(
      context: dialogContext,
      parsed: enriched,
      expenseCategories: categories,
      paymentMethods: paymentMethods,
    );
    _smsDialogOpen = false;

    if (result != null) {
      await _saveQuickTransaction(result);
    }

    if (_pendingSmsDialogs.isNotEmpty) {
      await _showNextSmsDialog();
    }
  }

  Future<void> _saveQuickTransaction(QuickTransactionResult result) async {
    final date =
        '${result.date.year}-${result.date.month.toString().padLeft(2, '0')}-${result.date.day.toString().padLeft(2, '0')}';

    if (result.type == QuickTransactionType.income) {
      await DatabaseHelper.instance.insertIncome(
        Income(
          incomeDate: date,
          month: date.substring(0, 7),
          category: result.category,
          source: result.description,
          amount: result.amount,
          paymentMethod: result.paymentMethod,
        ),
      );
    } else {
      await DatabaseHelper.instance.insertExpense(
        Expense(
          expenseDate: date,
          category: result.category,
          item: result.description,
          amount: result.amount,
          paymentMethod: result.paymentMethod,
          memberId: selectedMemberId,
          accountId: selectedAccountId,
        ),
      );
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.type == QuickTransactionType.income
              ? 'Income saved from SMS'
              : result.type == QuickTransactionType.investment
                  ? 'Investment saved from SMS'
                  : 'Expense saved from SMS',
        ),
      ),
    );

    await refreshDashboard();
  }

  Future<void> _initializeApp() async {
    entitlement = await EntitlementService.instance.getStatus();
    await generateMonths();

    final prefs = await SharedPreferences.getInstance();
    const resetKey = 'csv_fresh_start_v1';
    if (!(prefs.getBool(resetKey) ?? false)) {
      await DatabaseHelper.instance.resetDatabase();
      await prefs.setBool(resetKey, true);
    }

    await loadCategories();
    await loadMembersAndAccounts();

    await Future.wait([
      loadExpenses(),
      loadIncomes(),
      loadGoals(),
      loadMonthlyExpenseTotals(),
    ]);

    await Future.wait([
      loadBudget(),
      loadCategoryBudgets(),
    ]);

    await processRecurringForMonth();
    await calculateSummary();
    _generateInsights();
    await loadIncome();
    userProfile = await AuthService.instance.getProfile();
    if (!paymentMethods.contains(selectedPaymentMethod)) {
      selectedPaymentMethod = paymentMethods.first;
    }
    await _startSmsQuickEntry();

    if (!entitlement!.canUseApp && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openSubscription(blocking: true);
      });
    }
    if (mounted) setState(() => _appReady = true);
  }

  Future<void> _reloadEntitlement() async {
    entitlement = await EntitlementService.instance.getStatus();
    await generateMonths();
    if (mounted) setState(() {});
  }

  Future<void> _openSubscription({bool blocking = false}) async {
    final status = entitlement ?? await EntitlementService.instance.getStatus();
    await Navigator.push<bool>(
      context,
      appPageRoute(
        SubscriptionScreen(status: status, blocking: blocking),
      ),
    );
    await _reloadEntitlement();
  }

  Future<bool> _ensureFeature(AppFeature feature) async {
    final status = entitlement ?? await EntitlementService.instance.getStatus();
    if (status.canAccess(feature)) return true;
    return showUpgradePrompt(context, feature: feature, status: status);
  }

  Future<void> addCategoryDialog() async {
    TextEditingController categoryController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Category'),
          content: TextField(
            controller: categoryController,
            decoration: const InputDecoration(labelText: 'Category Name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (categoryController.text.isNotEmpty) {
                  await DatabaseHelper.instance.insertCategory(
                    categoryController.text.trim(),
                  );

                  await loadCategories();

                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> saveExpense() async {
    if (itemController.text.isEmpty || amountController.text.isEmpty) {
      return;
    }

    final amount = parseMoney(amountController.text);
    if (amount == null || amount <= 0) return;

    Expense expense = Expense(
      expenseDate:
          "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}",
      category: selectedCategory,
      item: itemController.text,
      amount: amount,
      paymentMethod: selectedPaymentMethod,
      memberId: selectedMemberId,
      accountId: selectedAccountId,
    );

    await DatabaseHelper.instance.insertExpense(expense);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Expense Saved Successfully'),
        duration: Duration(seconds: 2),
      ),
    );

    await refreshDashboard();
    setState(() {
      savedCategory = selectedCategory;
      savedItem = itemController.text;
      savedAmount = amountController.text;
    });

    if (!mounted) return;

    itemController.clear();
    amountController.clear();
  }

  Future<void> editExpenseDialog(Expense expense) async {
    final itemController = TextEditingController(text: expense.item);
    final amountController = TextEditingController(
      text: formatMoney(expense.amount),
    );
    final notesController = TextEditingController(text: expense.notes);
    String category = expense.category;
    String payment = expense.paymentMethod;
    bool isTransfer = expense.isTransfer;
    int? memberId = _resolveMemberId(expense.memberId ?? selectedMemberId);
    int? accountId = _resolveAccountId(expense.accountId ?? selectedAccountId);

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Expense'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: itemController,
                      decoration: const InputDecoration(labelText: 'Item'),
                    ),
                    TextField(
                      controller: amountController,
                      keyboardType: kMoneyKeyboard,
                      inputFormatters: kMoneyInputFormatters,
                      decoration: const InputDecoration(labelText: 'Amount'),
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: categories.contains(category)
                          ? category
                          : categories.first,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: categories
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setDialogState(() => category = v);
                      },
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: paymentMethods.contains(payment)
                          ? payment
                          : paymentMethods.first,
                      decoration: const InputDecoration(labelText: 'Payment'),
                      items: paymentMethods
                          .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setDialogState(() => payment = v);
                      },
                    ),
                    if (members.isNotEmpty)
                      DropdownButtonFormField<int?>(
                        initialValue: memberId,
                        decoration: const InputDecoration(labelText: 'Paid by'),
                        items: members
                            .map(
                              (m) => DropdownMenuItem(
                                value: m.id,
                                child: Text(m.name),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setDialogState(() => memberId = v),
                      ),
                    if (accounts.isNotEmpty)
                      DropdownButtonFormField<int?>(
                        initialValue: accountId,
                        decoration: const InputDecoration(labelText: 'Account'),
                        items: accounts
                            .map(
                              (a) => DropdownMenuItem(
                                value: a.id,
                                child: Text(a.name),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setDialogState(() => accountId = v),
                      ),
                    SwitchListTile(
                      title: const Text('Transfer between own accounts'),
                      subtitle: const Text('Excluded from spending totals'),
                      value: isTransfer,
                      onChanged: (v) => setDialogState(() => isTransfer = v),
                    ),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(labelText: 'Notes'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final amount = parseMoney(amountController.text);
                    if (amount == null || amount <= 0) return;
                    Navigator.pop(context);
                    final oldCategory = expense.category;
                    final updated = expense.copyWith(
                      item: itemController.text,
                      amount: amount,
                      category: category,
                      paymentMethod: payment,
                      memberId: memberId,
                      accountId: accountId,
                      isTransfer: isTransfer,
                      notes: notesController.text,
                    );
                    await DatabaseHelper.instance.updateExpenseFull(updated);
                    if (oldCategory != category) {
                      await MerchantRuleService.instance.learnFromCategoryChange(
                        expense.item,
                        category,
                      );
                      if (expenseFilter.categoryFilter == oldCategory) {
                        expenseFilter =
                            expenseFilter.copyWith(categoryFilter: null);
                      }
                    }
                    await refreshDashboard();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void showExpensesForCategory(String category) {
    final categoryExpenses = filteredExpenses
        .where((e) => e.category == category)
        .toList();

    showCategoryExpensesSheet(
      context,
      category: category,
      expenses: categoryExpenses,
      monthLabel: getSelectedMonthLabel(),
      formatDate: formatDate,
    );
  }

  Future<void> editIncomeDialog(Income income) async {
    if (isSystemIncome(income)) return;

    final sourceController = TextEditingController(text: income.source);
    final amountController = TextEditingController(
      text: formatMoney(income.amount),
    );
    final categoryController = TextEditingController(text: income.category);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Income'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: sourceController,
                decoration: const InputDecoration(labelText: 'Source'),
              ),
              TextField(
                controller: amountController,
                keyboardType: kMoneyKeyboard,
                inputFormatters: kMoneyInputFormatters,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: moneyInputPrefix(),
                ),
              ),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = parseMoney(amountController.text.trim());
                if (amount == null || amount <= 0) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Amount must be greater than zero.'),
                    ),
                  );
                  return;
                }
                Navigator.pop(context);
                await updateIncome(
                  income.id!,
                  sourceController.text.trim(),
                  amount,
                  categoryController.text.trim(),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> updateIncome(
    int id,
    String source,
    double amount,
    String category,
  ) async {
    await DatabaseHelper.instance.updateIncome(id, source, amount, category);
    await refreshDashboard();
  }

  Future<void> deleteIncome(int id) async {
    final income = incomes.where((i) => i.id == id).firstOrNull;
    if (income != null && isSystemIncome(income)) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete income?'),
        content: const Text('This will update your monthly income total.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await DatabaseHelper.instance.deleteIncome(id);
    await refreshDashboard();
  }

  Future<void> updateExpense(int id, String item, double amount) async {
    await DatabaseHelper.instance.updateExpense(id, item, amount);
    await refreshDashboard();
  }

  Future<void> deleteExpense(int id) async {
    await DatabaseHelper.instance.deleteExpense(id);
    await refreshDashboard();
  }

  Future<String?> _saveBudgetFormIncome(
    double amount,
    String description,
  ) async {
    if (description.trim().isEmpty) {
      return 'Description is required (e.g. Salary, Business, Bonus).';
    }
    if (amount <= 0) {
      return 'Enter an income amount greater than zero.';
    }

    await DatabaseHelper.instance.insertManualIncome(
      month: selectedMonth,
      amount: amount,
      description: description.trim(),
    );
    await BalanceService.syncAdjacentMonths(selectedMonth);
    await _refreshAfterBudgetOrIncome();
    return null;
  }

  Future<String?> _saveBudgetFormLimit(double amount) async {
    if (amount < 0) return 'Enter a valid budget amount.';

    final prefs = await SharedPreferences.getInstance();
    monthlyBudget = roundMoney(amount);
    await prefs.setDouble('budget_$selectedMonth', monthlyBudget);

    _generateInsights();
    _checkBudgetAlerts();
    if (mounted) setState(() {});
    return null;
  }

  Future<BudgetFormSnapshot> _loadBudgetFormSnapshot() async {
    await loadIncome();
    await loadBudget();
    final manualEntries =
        await DatabaseHelper.instance.getManualIncomeForMonth(selectedMonth);
    final prevKey = BalanceService.previousMonthKey(selectedMonth);

    return BudgetFormSnapshot(
      manualIncome: manualIncome,
      monthlyBudget: monthlyBudget,
      broughtForwardIncome: broughtForwardIncome,
      importedIncome: importedIncome,
      monthlyIncome: monthlyIncome,
      manualEntries: manualEntries,
      previousMonthLabel: prevKey != null ? getMonthLabel(prevKey) : null,
    );
  }

  String formatDate(String dbDate) {
    if (dbDate.isEmpty) return 'Monthly entry';
    final parts = dbDate.split('-');
    if (parts.length < 3) return dbDate;

    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return dbDate;
    return formatDisplayDate(DateTime(year, month, day));
  }

  List<Expense> get filteredExpenses {
    return applyExpenseFilters(expenses, selectedMonth, expenseFilter);
  }

  List<Expense> get filteredInvestments {
    return applyExpenseFilters(
      expenses,
      selectedMonth,
      expenseFilter,
      investmentsOnly: true,
    );
  }

  List<Income> get filteredIncomes {
    return applyIncomeFilters(incomes, selectedMonth, expenseFilter);
  }

  bool isSystemIncome(Income income) =>
      income.source == BalanceService.broughtForwardSource;

  void updateDefaultDate() {
    final parts = selectedMonth.split('-');

    final selectedYear = int.parse(parts[0]);
    final selectedMonthNumber = int.parse(parts[1]);

    final today = DateTime.now();

    // Current month → today's date
    if (selectedYear == today.year && selectedMonthNumber == today.month) {
      selectedDate = today;
      return;
    }

    // Previous month → last day of selected month
    if (selectedYear < today.year ||
        (selectedYear == today.year && selectedMonthNumber < today.month)) {
      selectedDate = DateTime(selectedYear, selectedMonthNumber + 1, 0);
      return;
    }

    // Future month → first day of month
    selectedDate = DateTime(selectedYear, selectedMonthNumber, 1);
  }

  Future<void> generateMonths() async {
    months.clear();

    final status = entitlement ?? await EntitlementService.instance.getStatus();
    final earliest = status.earliestAllowedMonthKey(DateTime.now());

    final currentYear = DateTime.now().year;

    for (int year = currentYear - 2; year <= currentYear + 2; year++) {
      for (int month = 1; month <= 12; month++) {
        final value = '$year-${month.toString().padLeft(2, '0')}';
        if (earliest != null && value.compareTo(earliest) < 0) continue;

        const monthNames = [
          'January',
          'February',
          'March',
          'April',
          'May',
          'June',
          'July',
          'August',
          'September',
          'October',
          'November',
          'December',
        ];

        final label = '${monthNames[month - 1]} $year';

        months.add({'value': value, 'label': label});
      }
    }

    if (months.isNotEmpty &&
        !months.any((m) => m['value'] == selectedMonth)) {
      selectedMonth = months.last['value']!;
    }
  }

  Future<void> loadBudget() async {
    final prefs = await SharedPreferences.getInstance();
    monthlyBudget = prefs.getDouble('budget_$selectedMonth') ?? 0;
    if (mounted) setState(() {});
  }

  Future<void> _openSettings() async {
    final refreshed = await Navigator.push<bool>(
      context,
      appPageRoute<bool>(
        SettingsScreen(
          categories: categories,
          paymentMethods: paymentMethods,
          userProfile: userProfile,
          onLogout: _logout,
        ),
      ),
    );
    if (refreshed == true) await refreshDashboard();
  }

  Future<void> _openAccountSecurity() async {
    final profile = userProfile ?? await AuthService.instance.getProfile();
    if (profile == null || !mounted) return;

    final updated = await Navigator.push<bool>(
      context,
      appPageRoute<bool>(AccountSecurityScreen(
        profile: profile,
        onLogout: _confirmLogout,
      )),
    );
    if (updated == true) await refreshDashboard();
  }

  Future<void> _confirmLogout() async {
    if (!mounted) return;
    if (!await confirmLogout(context)) return;
    await _logout();
  }

  Future<void> _logout() async {
    await AuthService.instance.logout();
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => AuthGate(
          authenticatedBuilder: (_) => const ExpenseScreen(),
        ),
      ),
      (_) => false,
    );
  }

  Future<void> _handleMenuAction(String action) async {
    if (action == 'subscription') {
      await _openSubscription();
      return;
    }
    if (action.startsWith('upgrade:')) {
      final name = action.split(':').last;
      final feature = AppFeature.values.firstWhere(
        (f) => f.name == name,
        orElse: () => AppFeature.basicUsage,
      );
      await showUpgradePrompt(
        context,
        feature: feature,
        status: entitlement,
      );
      return;
    }

    switch (action) {
      case 'add_expense':
        await _openAddExpense();
        return;
      case 'import':
        if (!await _ensureFeature(AppFeature.importStatement)) return;
        final imported = await Navigator.push<bool>(
          context,
          appPageRoute<bool>(const ImportStatementScreen()),
        );
        if (imported == true) {
          await generateMonths();
          await refreshDashboard();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bank statement imported successfully')),
          );
        }
        return;
      case 'transactions':
        setState(() => _currentTab = 1);
        _pageController.animateToPage(
          1,
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutCubic,
        );
        return;
      case 'budget':
        await _openBudget();
        return;
      case 'analytics':
        setState(() => _currentTab = 2);
        _pageController.animateToPage(
          2,
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutCubic,
        );
        return;
      case 'categories':
        await addCategoryDialog();
        return;
      case 'goals':
      case 'settings':
        await _openSettings();
        return;
      case 'pdf':
        if (!await _ensureFeature(AppFeature.exportPdf)) return;
        try {
          final reportFilter = ExpenseFilterState();
          await ExportService.instance.exportMonthlyPdf(
            monthLabel: getSelectedMonthLabel(),
            income: monthlyIncome,
            manualIncome: manualIncome,
            importedIncome: importedIncome,
            broughtForwardIncome: broughtForwardIncome,
            budget: monthlyBudget,
            expenses: totalExpenses,
            investmentTotal: investmentTotal,
            netBalance: balance,
            categoryTotals: categoryTotals,
            investmentTotals: investmentTotals,
            expenseList: applyExpenseFilters(
              expenses,
              selectedMonth,
              reportFilter,
            ),
            incomeList: applyIncomeFilters(
              incomes,
              selectedMonth,
              reportFilter,
            ),
            investmentList: applyExpenseFilters(
              expenses,
              selectedMonth,
              reportFilter,
              investmentsOnly: true,
            ),
          );
        } on EntitlementException {
          await showUpgradePrompt(context, feature: AppFeature.exportPdf);
        }
        return;
      case 'csv':
        if (!await _ensureFeature(AppFeature.exportCsv)) return;
        try {
          final path = await ExportService.instance.exportExpensesCsv(expenses);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                path != null ? 'CSV saved to $path' : 'Export cancelled',
              ),
            ),
          );
        } on EntitlementException {
          await showUpgradePrompt(context, feature: AppFeature.exportCsv);
        }
        return;
      case 'backup':
        if (!await _ensureFeature(AppFeature.backup)) return;
        await runBackupFlow(context);
        return;
      case 'restore':
        if (!await _ensureFeature(AppFeature.restore)) return;
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
        if (confirmed != true) return;
        final restored = await runRestoreFlow(context);
        if (restored) await refreshDashboard();
        return;
      case 'delete_month':
        await deleteSelectedMonthData();
        return;
      case 'clear':
        await resetAllData();
        return;
      case 'help':
        await Navigator.push(
          context,
          appPageRoute(
            HelpAboutScreen(userProfile: userProfile),
          ),
        );
        return;
      case 'feedback':
        await Navigator.push(
          context,
          appPageRoute(
            FeedbackScreen(userProfile: userProfile),
          ),
        );
        return;
    }
  }

  Future<void> _openAddExpense() async {
    await Navigator.push(
      context,
      appPageRoute(
        AddExpenseScreen(
          categories: categories,
          paymentMethods: paymentMethods,
          selectedCategory: selectedCategory,
          selectedPaymentMethod: selectedPaymentMethod,
          selectedDate: selectedDate,
          itemController: itemController,
          amountController: amountController,
          onCategoryChanged: (v) => setState(() => selectedCategory = v),
          onPaymentMethodChanged: (v) => setState(() => selectedPaymentMethod = v),
          onPickDate: pickDate,
          onSave: saveExpense,
          onImport: () async {
            if (!await _ensureFeature(AppFeature.importStatement)) return;
            final imported = await Navigator.push<bool>(
              context,
              appPageRoute<bool>(const ImportStatementScreen()),
            );
            if (imported == true) {
              await generateMonths();
              await refreshDashboard();
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bank statement imported successfully')),
              );
            }
          },
        ),
      ),
    );
  }

  Future<void> _openBudget() async {
    if (!mounted) return;
    await Navigator.push(
      context,
      appPageRoute(
        BudgetScreen(
          monthLabel: getSelectedMonthLabel(),
          categoryTotals: categoryTotals,
          categoryBudgets: categoryBudgets,
          categories: categories,
          loadSnapshot: _loadBudgetFormSnapshot,
          onSaveIncome: _saveBudgetFormIncome,
          onSaveBudget: _saveBudgetFormLimit,
          onSaveCategoryBudget: saveCategoryBudget,
        ),
      ),
    );
  }

  String getSelectedMonthLabel() {
    return getMonthLabel(selectedMonth);
  }

  String getMonthLabel(String monthKey) {
    final month = months.firstWhere(
      (m) => m['value'] == monthKey,
      orElse: () => {'label': monthKey},
    );

    return month['label']!;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _smsSubscription?.cancel();
    _pageController.dispose();
    itemController.dispose();
    amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_appReady) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        body: MeshBackground(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(strokeWidth: 2.5),
                const SizedBox(height: 16),
                Text(
                  'Loading your finances…',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final isPremium = entitlement?.hasActivePremium ?? false;
    final showBottomBanner = !keyboardOpen && _currentTab != 3 && !isPremium;
    final showMenuAds = !isPremium && _currentTab == 3;
    final fabBottom = ResponsiveLayout.fabBottomOffset(
      context,
      showBottomAd: showBottomBanner,
    );
    final homeScrollBottom = ResponsiveLayout.scrollBottomPadding(
      context,
      showBottomAd: showBottomBanner,
      includeFabClearance: true,
    );
    final expensesScrollBottom = ResponsiveLayout.scrollBottomPadding(
      context,
      showBottomAd: showBottomBanner,
      includeFabClearance: true,
    );
    final analyticsScrollBottom = ResponsiveLayout.scrollBottomPadding(
      context,
      showBottomAd: showBottomBanner,
    );
    final menuScrollBottom = ResponsiveLayout.scrollBottomPadding(
      context,
      showBottomAd: false,
    );
    final menuEntitlement = entitlement ??
        EntitlementStatus(
          tier: SubscriptionTier.free,
          registrationDate: DateTime.now(),
          subscriptionExpiresAt: null,
          evaluatedAt: DateTime.now(),
        );

    return Scaffold(
      backgroundColor: AppColors.surface,
      extendBody: true,
      body: MeshBackground(
        child: SafeArea(
          bottom: false,
          child: ResponsiveLayout.constrainContent(
            context,
            PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (index) => setState(() => _currentTab = index),
            children: [
            HomeTab(
              selectedMonth: selectedMonth,
              months: months,
              monthLabel: getSelectedMonthLabel(),
              monthlyIncome: monthlyIncome,
              manualIncome: manualIncome,
              importedIncome: importedIncome,
              broughtForwardIncome: broughtForwardIncome,
              totalExpenses: totalExpenses,
              investmentTotal: investmentTotal,
              balance: balance,
              monthlyBudget: monthlyBudget,
              categoryTotals: categoryTotals,
              monthlyExpenseTotals: monthlyExpenseTotals,
              insights: insights,
              missingRecurring: missingRecurring,
              dismissMissingBanner: dismissMissingBanner,
              highestCategory: getHighestCategory(),
              transactionCount: getTransactionCount(),
              userName: userProfile?.name,
              householdName: userProfile?.householdName,
              onMonthChanged: (value) async {
                selectedMonth = value;
                shownBudgetAlerts.clear();
                updateDefaultDate();
                await refreshDashboard();
              },
              onDismissBanner: () => setState(() => dismissMissingBanner = true),
              onAddExpense: _openAddExpense,
              onViewTransactions: () {
                setState(() => _currentTab = 1);
                _pageController.animateToPage(
                  1,
                  duration: const Duration(milliseconds: 380),
                  curve: Curves.easeOutCubic,
                );
              },
              onViewAnalytics: () {
                setState(() => _currentTab = 2);
                _pageController.animateToPage(
                  2,
                  duration: const Duration(milliseconds: 380),
                  curve: Curves.easeOutCubic,
                );
              },
              onAccountSettings: _openAccountSecurity,
              onManageSettings: _openSettings,
              onLogout: _confirmLogout,
              bottomScrollPadding: homeScrollBottom,
            ),
            ExpensesTab(
              monthLabel: getSelectedMonthLabel(),
              expenses: filteredExpenses,
              investments: filteredInvestments,
              incomes: filteredIncomes,
              investmentTotal: investmentTotal,
              categories: categories,
              paymentMethods: paymentMethods,
              filter: expenseFilter,
              onFilterChanged: (f) => setState(() => expenseFilter = f),
              formatDate: formatDate,
              onEditExpense: editExpenseDialog,
              onDeleteExpense: deleteExpense,
              onEditIncome: editIncomeDialog,
              onDeleteIncome: deleteIncome,
              isSystemIncome: isSystemIncome,
              accountNames: accountNamesById,
              accountBankLabels: accountBankLabelsById,
              bottomScrollPadding: expensesScrollBottom,
            ),
            AnalyticsTab(
              monthLabel: getSelectedMonthLabel(),
              categoryTotals: categoryTotals,
              monthlyExpenseTotals: monthlyExpenseTotals,
              categoryBudgets: categoryBudgets,
              memberSpending: memberSpending,
              categories: categories
                  .where((c) => !CategoryUtils.isSavingsCategory(c))
                  .toList(),
              barColors: barColors,
              insights: insights,
              goals: goals,
              highestCategory: getHighestCategory(),
              highestExpense: getLargestExpense(),
              transactionCount: getTransactionCount(),
              budgetUsed: getBudgetUsed(),
              onCategoryTap: showExpensesForCategory,
              onSaveBudget: saveCategoryBudget,
              onManageGoals: _openSettings,
              bottomScrollPadding: analyticsScrollBottom,
            ),
            MenuTab(
                onAction: _handleMenuAction,
                adsActive: showMenuAds,
                entitlement: menuEntitlement,
                bottomScrollPadding: menuScrollBottom,
              ),
            ],
          ),
        ),
        ),
      ),
      floatingActionButton: _currentTab == 1
          ? Padding(
              padding: EdgeInsets.only(bottom: fabBottom),
              child: GlassFab(
                onPressed: _openAddExpense,
                icon: Icons.add_rounded,
                label: 'Add Expense',
              ),
            )
          : null,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BottomAdRibbon(visible: showBottomBanner),
          PremiumBottomNav(
        selectedIndex: _currentTab,
        onSelected: (index) {
          setState(() => _currentTab = index);
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 380),
            curve: Curves.easeOutCubic,
          );
        },
      ),
        ],
      ),
    );
  }
}
