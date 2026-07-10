import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'ui/glass_surface.dart';

enum ExpenseSort { dateDesc, dateAsc, amountDesc, amountAsc }

enum TransactionHistoryType { expenses, income, savingsInvestments }

const _unset = Object();

class ExpenseFilterState {
  String searchQuery;
  String? categoryFilter;
  String? paymentFilter;
  double? minAmount;
  double? maxAmount;
  ExpenseSort sort;
  bool showTransfers;

  ExpenseFilterState({
    this.searchQuery = '',
    this.categoryFilter,
    this.paymentFilter,
    this.minAmount,
    this.maxAmount,
    this.sort = ExpenseSort.dateDesc,
    this.showTransfers = false,
  });

  ExpenseFilterState copyWith({
    String? searchQuery,
    Object? categoryFilter = _unset,
    Object? paymentFilter = _unset,
    Object? minAmount = _unset,
    Object? maxAmount = _unset,
    ExpenseSort? sort,
    bool? showTransfers,
  }) {
    return ExpenseFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      categoryFilter: identical(categoryFilter, _unset)
          ? this.categoryFilter
          : categoryFilter as String?,
      paymentFilter: identical(paymentFilter, _unset)
          ? this.paymentFilter
          : paymentFilter as String?,
      minAmount: identical(minAmount, _unset)
          ? this.minAmount
          : minAmount as double?,
      maxAmount: identical(maxAmount, _unset)
          ? this.maxAmount
          : maxAmount as double?,
      sort: sort ?? this.sort,
      showTransfers: showTransfers ?? this.showTransfers,
    );
  }
}

class ExpenseFilterBar extends StatefulWidget {
  final ExpenseFilterState filter;
  final TransactionHistoryType historyType;
  final List<String> categories;
  final List<String> paymentMethods;
  final ValueChanged<ExpenseFilterState> onChanged;

  const ExpenseFilterBar({
    super.key,
    required this.filter,
    required this.historyType,
    required this.categories,
    required this.paymentMethods,
    required this.onChanged,
  });

  @override
  State<ExpenseFilterBar> createState() => _ExpenseFilterBarState();
}

class _ExpenseFilterBarState extends State<ExpenseFilterBar> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.filter.searchQuery);
  }

  @override
  void didUpdateWidget(ExpenseFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filter.searchQuery != _searchController.text) {
      _searchController.text = widget.filter.searchQuery;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _searchHint {
    switch (widget.historyType) {
      case TransactionHistoryType.expenses:
        return 'Search item or merchant…';
      case TransactionHistoryType.income:
        return 'Search source or category…';
      case TransactionHistoryType.savingsInvestments:
        return 'Search investment or category…';
    }
  }

  @override
  Widget build(BuildContext context) {
    final showPayment = widget.historyType != TransactionHistoryType.savingsInvestments;
    final showTransfers = widget.historyType == TransactionHistoryType.expenses;

    return Theme(
      data: Theme.of(context).copyWith(
        dropdownMenuTheme: DropdownMenuThemeData(
          menuStyle: MenuStyle(
            backgroundColor: WidgetStateProperty.all(AppColors.surfaceElevated),
            surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
            elevation: WidgetStateProperty.all(4),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ),
      child: GlassSurface.card(
        padding: const EdgeInsets.all(16),
        borderRadius: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.tune_rounded, color: AppColors.primary, size: 20),
                SizedBox(width: 8),
                Text(
                  'Search & Filter',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: _searchHint,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: widget.filter.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          widget.onChanged(widget.filter.copyWith(searchQuery: ''));
                        },
                      )
                    : null,
              ),
              onChanged: (v) =>
                  widget.onChanged(widget.filter.copyWith(searchQuery: v)),
            ),
            const SizedBox(height: 12),
            _FilterDropdown<String?>(
              label: 'Category',
              value: widget.filter.categoryFilter,
              items: [
                const DropdownMenuItem(value: null, child: Text('All categories')),
                ...widget.categories.map(
                  (c) => DropdownMenuItem(
                    value: c,
                    child: Text(c, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
              onChanged: (v) =>
                  widget.onChanged(widget.filter.copyWith(categoryFilter: v)),
            ),
            if (showPayment) ...[
              const SizedBox(height: 10),
              _FilterDropdown<String?>(
                label: 'Payment method',
                value: widget.filter.paymentFilter,
                items: [
                  const DropdownMenuItem(value: null, child: Text('All methods')),
                  ...widget.paymentMethods.map(
                    (p) => DropdownMenuItem(
                      value: p,
                      child: Text(p, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: (v) =>
                    widget.onChanged(widget.filter.copyWith(paymentFilter: v)),
              ),
            ],
            const SizedBox(height: 10),
            _FilterDropdown<ExpenseSort>(
              label: 'Sort by',
              value: widget.filter.sort,
              items: const [
                DropdownMenuItem(
                  value: ExpenseSort.dateDesc,
                  child: Text('Date (newest first)'),
                ),
                DropdownMenuItem(
                  value: ExpenseSort.dateAsc,
                  child: Text('Date (oldest first)'),
                ),
                DropdownMenuItem(
                  value: ExpenseSort.amountDesc,
                  child: Text('Amount (high to low)'),
                ),
                DropdownMenuItem(
                  value: ExpenseSort.amountAsc,
                  child: Text('Amount (low to high)'),
                ),
              ],
              onChanged: (v) {
                if (v != null) widget.onChanged(widget.filter.copyWith(sort: v));
              },
            ),
            if (showTransfers) ...[
              const SizedBox(height: 10),
              FilterChip(
                label: const Text('Show transfers'),
                selected: widget.filter.showTransfers,
                selectedColor: AppColors.primary.withValues(alpha: 0.15),
                checkmarkColor: AppColors.primary,
                onSelected: (v) =>
                    widget.onChanged(widget.filter.copyWith(showTransfers: v)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      key: ValueKey('$label-$value'),
      initialValue: value,
      isExpanded: true,
      isDense: false,
      menuMaxHeight: 320,
      decoration: InputDecoration(
        labelText: label,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: items,
      selectedItemBuilder: (context) => items.map((item) {
        final child = item.child;
        return Align(
          alignment: Alignment.centerLeft,
          child: DefaultTextStyle(
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textPrimary,
              overflow: TextOverflow.ellipsis,
            ),
            child: child is Text
                ? Text(
                    child.data ?? '',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  )
                : child,
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
