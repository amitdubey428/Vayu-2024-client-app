import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:vayu_flutter_app/blocs/expense/expense_bloc.dart';
import 'package:vayu_flutter_app/data/models/expense_model.dart';
import 'package:vayu_flutter_app/core/routes/route_names.dart';
import 'package:vayu_flutter_app/data/models/user_public_info.dart';
import 'package:vayu_flutter_app/core/themes/app_theme.dart';
import 'dart:developer' as developer;
import 'dart:async';

import 'package:vayu_flutter_app/shared/widgets/snackbar_util.dart';
import 'package:vayu_flutter_app/shared/widgets/custom_loading_indicator.dart';

class ExpenseDetailsScreen extends StatefulWidget {
  final ExpenseModel expense;
  final List<UserPublicInfo> tripParticipants;
  final Function(ExpenseModel) onExpenseUpdated;
  final ExpenseBloc expenseBloc;

  const ExpenseDetailsScreen({
    super.key,
    required this.expense,
    required this.tripParticipants,
    required this.onExpenseUpdated,
    required this.expenseBloc,
  });

  @override
  State<ExpenseDetailsScreen> createState() => _ExpenseDetailsScreenState();
}

class _ExpenseDetailsScreenState extends State<ExpenseDetailsScreen> {
  late ExpenseModel _expense;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _expense = widget.expense;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.expenseBloc,
      child: Stack(
        children: [
          Scaffold(
            body: RefreshIndicator(
              onRefresh: _refreshExpense,
              child: CustomScrollView(
                slivers: [
                  _buildAppBar(context),
                  SliverToBoxAdapter(
                    child: _buildExpenseDetails(context),
                  ),
                ],
              ),
            ),
          ),
          if (_isDeleting)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CustomLoadingIndicator(message: 'Deleting expense...'),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _refreshExpense() async {
    final updatedExpense = await _fetchUpdatedExpense();
    if (updatedExpense != null) {
      setState(() {
        _expense = updatedExpense;
      });
      widget.onExpenseUpdated(updatedExpense);
    }
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        titlePadding: EdgeInsets.zero,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          color: AppTheme.primaryColor.withOpacity(0.7),
          child: Text(
            _expense.description,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryColor.withOpacity(0.8)
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${_expense.currency} ${_expense.amount.toStringAsFixed(2)}',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('MMMM d, yyyy').format(_expense.createdAt),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                  Text(
                    DateFormat('MMMM d, yyyy').format(_expense.updatedAt),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                  const SizedBox(height: 24), // Added extra space here
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => _editExpense(context),
        ),
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () => _deleteExpense(context),
        ),
      ],
    );
  }

  Widget _buildExpenseDetails(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(context, 'Expense Details', [
            _buildInfoRow('Created by', _getUserName(_expense.createdBy)),
            _buildInfoRow('Category', 'Not specified'),
            if (_expense.notes != null && _expense.notes!.isNotEmpty)
              _buildNotesSection(context),
          ]),
          const SizedBox(height: 16),
          _buildPaymentsCard(context),
          const SizedBox(height: 16),
          _buildSplitsCard(context),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildNotesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Notes',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          _expense.notes!,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildPaymentsCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Who Paid',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
            ),
            const SizedBox(height: 12),
            ..._expense.payments.map((payment) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppTheme.secondaryColor,
                        child: Text(
                          _getUserName(payment.userId)[0].toUpperCase(),
                          style: const TextStyle(color: AppTheme.textDark),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${_getUserName(payment.userId)} paid',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      Text(
                        '${_expense.currency} ${payment.amountPaid.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildSplitsCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How It\'s Split',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
            ),
            const SizedBox(height: 12),
            ..._expense.splits.map((split) {
              final amount = split.amount ?? 0;
              final isOwed = amount > 0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: isOwed
                          ? AppTheme.accentColor1
                          : AppTheme.accentColor2,
                      child: Text(
                        _getUserName(split.userId)[0].toUpperCase(),
                        style: const TextStyle(color: AppTheme.textLight),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${_getUserName(split.userId)} ${isOwed ? 'owes' : 'gets back'}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    Text(
                      '${_expense.currency} ${amount.abs().toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isOwed
                            ? AppTheme.accentColor2
                            : AppTheme.accentColor1,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
      BuildContext context, String title, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value ?? 'N/A',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _getUserName(int userId) {
    final user = widget.tripParticipants.firstWhere(
      (u) => u.userId == userId,
      orElse: () => UserPublicInfo(
        userId: userId,
        firebaseUid: '', // Provide a default empty string
        phoneNumber: '', // Provide a default empty string
        fullName: 'Unknown User',
      ),
    );
    return user.fullName ?? 'Unknown User';
  }

  Future<void> _editExpense(BuildContext context) async {
    final result = await Navigator.pushNamed(
      context,
      Routes.addEditExpense,
      arguments: {
        'tripId': _expense.tripId,
        'expense': _expense,
        'tripParticipants': widget.tripParticipants,
      },
    );

    if (result == true) {
      await _refreshExpense();
    }
  }

  Future<ExpenseModel?> _fetchUpdatedExpense() async {
    try {
      widget.expenseBloc.add(LoadExpenses(_expense.tripId));

      final state = await widget.expenseBloc.stream.firstWhere(
          (state) => state is ExpensesLoaded || state is ExpenseError);

      if (state is ExpensesLoaded) {
        final updatedExpense = state.summary.expenses.firstWhere(
          (e) => e.expenseId == _expense.expenseId,
          orElse: () => _expense,
        );
        return updatedExpense;
      } else if (state is ExpenseError) {
        throw Exception(state.message);
      }
    } catch (e) {
      developer.log('Error fetching updated expense: $e');
    }
    return null;
  }

  void _deleteExpense(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Expense'),
          content: const Text('Are you sure you want to delete this expense?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
                _performDelete(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _performDelete(BuildContext context) {
    setState(() {
      _isDeleting = true;
    });

    widget.expenseBloc.add(DeleteExpense(_expense.expenseId!, _expense.tripId));

    // Listen for the state change
    late final StreamSubscription<ExpenseState> subscription;
    subscription = widget.expenseBloc.stream.listen((state) {
      if (state is ExpensesLoaded || state is ExpenseError) {
        setState(() {
          _isDeleting = false;
        });

        if (state is ExpensesLoaded) {
          // Deletion successful
          SnackbarUtil.showSnackbar(
            'Expense deleted successfully',
            type: SnackbarType.success,
          );
          Navigator.of(context).pop(); // Return to the expense list
        } else if (state is ExpenseError) {
          // Deletion failed
          SnackbarUtil.showSnackbar(
            'Failed to delete expense: ${state.message}',
            type: SnackbarType.error,
          );
        }

        subscription
            .cancel(); // Cancel the subscription after handling the state
      }
    });
  }
}
