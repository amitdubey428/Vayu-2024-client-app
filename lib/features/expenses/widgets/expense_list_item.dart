import 'package:flutter/material.dart';
import 'package:vayu_flutter_app/core/themes/app_theme.dart';
import 'package:vayu_flutter_app/data/models/expense_model.dart';
import 'package:intl/intl.dart';

class ExpenseListItem extends StatelessWidget {
  final ExpenseModel expense;
  final int currentUserId;
  final VoidCallback onTap;

  const ExpenseListItem({
    super.key,
    required this.expense,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final userSplit = expense.splits.firstWhere(
      (split) => split.userId == currentUserId,
      orElse: () => ExpenseSplit(userId: currentUserId, amount: 0),
    );
    final userPayment = expense.payments.firstWhere(
      (payment) => payment.userId == currentUserId,
      orElse: () => ExpensePayment(userId: currentUserId, amountPaid: 0),
    );
    final amountOwed = userSplit.amount! - userPayment.amountPaid;
    final isInvolved = userSplit.amount! > 0 || userPayment.amountPaid > 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor,
          child: Text(
            expense.currency,
            style: const TextStyle(color: AppTheme.textLight),
          ),
        ),
        title: Text(
          expense.description,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Total: ${expense.amount.toStringAsFixed(2)} ${expense.currency}',
              style: const TextStyle(
                color: AppTheme.accentColor1,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            if (isInvolved)
              Text(
                amountOwed > 0
                    ? 'You owe: ${amountOwed.abs().toStringAsFixed(2)} ${expense.currency}'
                    : 'You are owed: ${amountOwed.abs().toStringAsFixed(2)} ${expense.currency}',
                style: TextStyle(
                  color: amountOwed > 0
                      ? AppTheme.accentColor2
                      : AppTheme.accentColor1,
                  fontWeight: FontWeight.bold,
                ),
              )
            else
              Text(
                'Not Involved',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM dd, yyyy').format(expense.createdAt),
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        trailing:
            const Icon(Icons.arrow_forward_ios, color: AppTheme.primaryColor),
        onTap: onTap,
      ),
    );
  }
}
