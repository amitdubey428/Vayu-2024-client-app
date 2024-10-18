import 'package:flutter/material.dart';
import 'package:vayu_flutter_app/data/models/expense_model.dart';

class ExpenseSummaryCard extends StatelessWidget {
  final TripExpenseSummary summary;

  const ExpenseSummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {}, // Add functionality if needed
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.summarize, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Expense Summary',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              const Divider(height: 24),
              ..._buildCurrencySummaries(context),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Expenses:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '${summary.expenses.length}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCurrencySummaries(BuildContext context) {
    if (summary.currencySummaries.isEmpty) {
      return [
        Text(
          'No expenses yet',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ];
    }

    return summary.currencySummaries.entries.map((entry) {
      final currency = entry.key;
      final totalSpend = entry.value.totalTripSpend;
      final isPositive = totalSpend >= 0;

      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              currency,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              '${isPositive ? '+' : ''}${totalSpend.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isPositive ? Colors.green : Colors.red,
                  ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
