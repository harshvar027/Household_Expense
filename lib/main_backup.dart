import 'models/expense.dart';
import 'database/database_helper.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const ExpenseTrackerApp());
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Household Expense Tracker !!',

      theme: ThemeData(primarySwatch: Colors.green),
      home: const ExpenseScreen(),
    );
  }
}

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final TextEditingController itemController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController incomeController = TextEditingController();
  Map<String, double> categoryTotals = {};
  double monthlyIncome = 0;
  double totalExpenses = 0;
  double savings = 0;
  String selectedCategory = '';
  String selectedPaymentMethod = 'UPI';
  DateTime selectedDate = DateTime.now();
  String savedItem = '';
  String savedAmount = '';
  String savedCategory = '';
  List<Expense> expenses = [];
  List<String> categories = [];
  final List<String> paymentMethods = [
    'Cash',
    'UPI',
    'Credit Card',
    'Debit Card',
    'Net Banking',
  ];
  Future<void> loadExpenses() async {
    final data = await DatabaseHelper.instance.getAllExpenses();

    print("Total expenses in DB = ${data.length}");

    for (final e in data.take(5)) {
      print("${e.id} ${e.item} ${e.amount}");
    }

    expenses = data;

    await calculateSummary();

    if (!mounted) return;

    setState(() {});
  }

  Future<void> loadCategories() async {
    categories = await DatabaseHelper.instance.getCategories();

    if (categories.isEmpty) {
      await DatabaseHelper.instance.insertCategory('Vegetables');
      await DatabaseHelper.instance.insertCategory('Fruits');
      await DatabaseHelper.instance.insertCategory('Milk');
      await DatabaseHelper.instance.insertCategory('Groceries');
      await DatabaseHelper.instance.insertCategory('Petrol');
      await DatabaseHelper.instance.insertCategory('Medical');
      await DatabaseHelper.instance.insertCategory('Shopping');
      await DatabaseHelper.instance.insertCategory('Electricity');
      await DatabaseHelper.instance.insertCategory('Internet');
      await DatabaseHelper.instance.insertCategory('Other');

      categories = await DatabaseHelper.instance.getCategories();
    }
    categories.sort();
    debugPrint('Loaded Categories: $categories');
    if (categories.isNotEmpty && selectedCategory.isEmpty) {
      selectedCategory = categories.first;
    }

    setState(() {});
  }

  Future<void> calculateSummary() async {
    double total = 0;

    Map<String, double> totals = {};

    for (var expense in expenses) {
      total += expense.amount;

      totals[expense.category] =
          (totals[expense.category] ?? 0) + expense.amount;
    }

    final currentMonth = "${DateTime.now().year}-${DateTime.now().month}";

    monthlyIncome = await DatabaseHelper.instance.getCurrentMonthIncome(
      currentMonth,
    );

    setState(() {
      totalExpenses = total;
      savings = monthlyIncome - totalExpenses;
      categoryTotals = totals;
    });
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

    loadCategories();

    loadExpenses().then((_) {
      calculateSummary();
    });
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

    Expense expense = Expense(
      expenseDate:
          "${selectedDate.year}-${selectedDate.month}-${selectedDate.day}",
      category: selectedCategory,
      item: itemController.text,
      amount: double.parse(amountController.text),
      paymentMethod: selectedPaymentMethod,
    );

    await DatabaseHelper.instance.insertExpense(expense);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Expense Saved Successfully'),
        duration: Duration(seconds: 2),
      ),
    );

    await loadExpenses();
    await calculateSummary();
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
      text: expense.amount.toString(),
    );

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Expense'),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: itemController,
                decoration: const InputDecoration(labelText: 'Item'),
              ),

              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount'),
              ),
            ],
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
                Navigator.pop(context);

                await updateExpense(
                  expense.id!,
                  itemController.text,
                  double.parse(amountController.text),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> updateExpense(int id, String item, double amount) async {
    await DatabaseHelper.instance.updateExpense(id, item, amount);

    await loadExpenses();

    await calculateSummary();
  }

  Future<void> deleteExpense(int id) async {
    await DatabaseHelper.instance.deleteExpense(id);

    await loadExpenses();

    await calculateSummary();
  }

  Future<void> saveIncome() async {
    if (incomeController.text.isEmpty) return;

    final currentMonth = "${DateTime.now().year}-${DateTime.now().month}";

    await DatabaseHelper.instance.saveIncome(
      currentMonth,
      double.parse(incomeController.text),
    );

    await calculateSummary();

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Income Saved')));

    incomeController.clear();
  }

  Widget summaryCard(String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: color.withValues(alpha: 0.1),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 35),
              const SizedBox(height: 10),

              Text(
                title,
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        title: const Text(
          'Household Expense Tracker',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text(
                'Monthly Dashboard',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),

              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: incomeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Monthly Income',
                          border: OutlineInputBorder(),
                          prefixText: '₹ ',
                        ),
                      ),

                      const SizedBox(height: 15),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: saveIncome,
                          icon: const Icon(Icons.account_balance_wallet),
                          label: const Text('Save Income'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  summaryCard(
                    'Income',
                    '₹ ${monthlyIncome.toStringAsFixed(0)}',
                    Colors.green,
                    Icons.account_balance_wallet,
                  ),

                  const SizedBox(width: 10),

                  summaryCard(
                    'Expenses',
                    '₹ ${totalExpenses.toStringAsFixed(0)}',
                    Colors.red,
                    Icons.shopping_cart,
                  ),

                  const SizedBox(width: 10),

                  summaryCard(
                    'Savings',
                    '₹ ${savings.toStringAsFixed(0)}',
                    Colors.blue,
                    Icons.savings,
                  ),
                ],
              ),

              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Date: ${selectedDate.day}-${selectedDate.month}-${selectedDate.year}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  ElevatedButton(
                    onPressed: pickDate,
                    child: const Text('Change Date'),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: addCategoryDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add Category'),
              ),

              const SizedBox(height: 20),

              const Text(
                'Add Expense',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                        items: categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedCategory = value!;
                          });
                        },
                      ),

                      const SizedBox(height: 20),

                      TextField(
                        controller: itemController,
                        decoration: const InputDecoration(
                          labelText: 'Item Name',
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 20),

                      TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Amount',
                          border: OutlineInputBorder(),
                          prefixText: '₹ ',
                        ),
                      ),

                      const SizedBox(height: 20),

                      DropdownButtonFormField<String>(
                        initialValue: selectedPaymentMethod,
                        decoration: const InputDecoration(
                          labelText: 'Payment Method',
                          border: OutlineInputBorder(),
                        ),
                        items: paymentMethods.map((method) {
                          return DropdownMenuItem(
                            value: method,
                            child: Text(method),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedPaymentMethod = value!;
                          });
                        },
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.save),
                          label: const Text(
                            'Save Expense',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: saveExpense,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const SizedBox(height: 20),

              const Text(
                'Category Summary',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: categoryTotals.length,
                itemBuilder: (context, index) {
                  final category = categoryTotals.keys.elementAt(index);

                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.deepPurple.shade100,
                        child: const Icon(
                          Icons.category,
                          color: Colors.deepPurple,
                        ),
                      ),
                      title: Text(
                        category,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '₹ ${categoryTotals[category]!.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const Text(
                'Expense History',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: expenses.length,
                itemBuilder: (context, index) {
                  final expense = expenses[index];

                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.orange.shade100,
                        child: const Icon(
                          Icons.shopping_bag,
                          color: Colors.orange,
                        ),
                      ),

                      title: Text(
                        expense.item,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),

                      subtitle: Text(
                        '${expense.category} • ${expense.expenseDate}',
                      ),

                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '₹ ${expense.amount.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),

                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              editExpenseDialog(expense);
                            },
                          ),

                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () async {
                              await deleteExpense(expense.id!);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
