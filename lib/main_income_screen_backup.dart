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
      title: 'Household Expense Tracker',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const IncomeScreen(),
    );
  }
}

class IncomeScreen extends StatefulWidget {
  const IncomeScreen({super.key});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  final TextEditingController incomeController = TextEditingController();

  String savedIncome = "";

  void saveIncome() {
    setState(() {
      savedIncome = incomeController.text;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Income Saved Successfully...")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Household Expense Tracker")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 30),

            const Text(
              "Enter Monthly Income",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: incomeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Monthly Income",
                prefixText: "₹ ",
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: saveIncome,
              child: const Text("Save Income"),
            ),

            const SizedBox(height: 30),

            Text(
              "Saved Income: ₹ $savedIncome",
              style: const TextStyle(fontSize: 20, color: Colors.green),
            ),
          ],
        ),
      ),
    );
  }
}
