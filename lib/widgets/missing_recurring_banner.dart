import 'package:flutter/material.dart';
import '../models/recurring_transaction.dart';

class MissingRecurringBanner extends StatelessWidget {
  final List<RecurringTransaction> missing;
  final VoidCallback? onDismiss;

  const MissingRecurringBanner({
    super.key,
    required this.missing,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (missing.isEmpty) return const SizedBox.shrink();

    final names = missing.map((m) => m.item).join(', ');
    return Card(
      color: Colors.amber.shade50,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.warning_amber, color: Colors.orange),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Missing recurring expenses',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Not seen this month: $names. Check imports or add manually.',
                    style: TextStyle(color: Colors.grey.shade800, fontSize: 13),
                  ),
                ],
              ),
            ),
            if (onDismiss != null)
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: onDismiss,
              ),
          ],
        ),
      ),
    );
  }
}
