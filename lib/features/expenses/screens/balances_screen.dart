import 'package:flutter/material.dart';
import 'package:vayu_flutter_app/core/themes/app_theme.dart';
import 'package:vayu_flutter_app/data/models/expense_model.dart';
import 'package:vayu_flutter_app/data/models/trip_model.dart';

class BalancesScreen extends StatelessWidget {
  final TripModel trip;
  final TripExpenseSummary summary;

  const BalancesScreen({
    super.key,
    required this.trip,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Balances'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Text(
              'Trip: ${trip.tripName}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          if (summary.currencySummaries.isNotEmpty)
            ...summary.currencySummaries.entries.map((entry) {
              final currency = entry.key;
              final currencySummary = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currency,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      _buildSummaryRow(
                        context,
                        'Your Balance',
                        currencySummary.userBalance,
                        currency,
                        isBalance: true,
                      ),
                      _buildSummaryRow(context, 'Total Trip Spend',
                          currencySummary.totalTripSpend, currency),
                      _buildSummaryRow(context, 'Your Total Spend',
                          currencySummary.userTotalSpend, currency),
                      _buildSummaryRow(context, 'Your Share',
                          currencySummary.userShare, currency),
                    ],
                  ),
                ),
              );
            })
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No expenses recorded yet.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
      BuildContext context, String label, double amount, String currency,
      {bool isBalance = false}) {
    final Color? textColor =
        isBalance ? (amount >= 0 ? Colors.green : Colors.red) : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            '$currency ${amount.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
          ),
        ],
      ),
    );
  }
}
