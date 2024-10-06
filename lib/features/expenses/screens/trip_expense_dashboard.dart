import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vayu_flutter_app/blocs/expense/expense_bloc.dart';
import 'package:vayu_flutter_app/core/di/service_locator.dart';
import 'package:vayu_flutter_app/core/routes/route_names.dart';
import 'package:vayu_flutter_app/data/models/expense_model.dart';
import 'package:vayu_flutter_app/data/models/trip_model.dart';
import 'package:vayu_flutter_app/features/expenses/screens/expense_details_screen.dart';
import 'package:vayu_flutter_app/features/expenses/widgets/expense_list_item.dart';
import 'package:vayu_flutter_app/features/expenses/widgets/expense_summary_card.dart';
import 'package:vayu_flutter_app/services/auth_notifier.dart';
import 'package:vayu_flutter_app/shared/widgets/custom_loading_indicator.dart';
import 'package:vayu_flutter_app/shared/widgets/snackbar_util.dart';
import 'package:vayu_flutter_app/features/expenses/screens/balances_screen.dart';
import 'package:intl/intl.dart';

class TripExpenseDashboard extends StatelessWidget {
  final TripModel trip;

  const TripExpenseDashboard({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          getIt<ExpenseBloc>()..add(LoadExpenses(trip.tripId!)),
      child: _TripExpenseDashboardContent(trip: trip),
    );
  }
}

class _TripExpenseDashboardContent extends StatefulWidget {
  final TripModel trip;

  const _TripExpenseDashboardContent({required this.trip});

  @override
  _TripExpenseDashboardContentState createState() =>
      _TripExpenseDashboardContentState();
}

class _TripExpenseDashboardContentState
    extends State<_TripExpenseDashboardContent> {
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isAscending = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: GestureDetector(
          onLongPress: () => _showFullTripName(context),
          child: Text(
            widget.trip.tripName,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            onPressed: () => _showBalances(context),
            tooltip: 'View Balances',
          ),
        ],
      ),
      body: BlocConsumer<ExpenseBloc, ExpenseState>(
        listener: (context, state) {
          if (state is ExpenseError) {
            SnackbarUtil.showSnackbar(state.message, type: SnackbarType.error);
          }
        },
        builder: (context, state) {
          if (state is ExpenseInitial || state is ExpenseLoading) {
            return const CustomLoadingIndicator(message: 'Loading expenses...');
          } else if (state is ExpensesLoaded) {
            return _buildContent(context, state);
          } else if (state is ExpenseError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addExpense(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showFullTripName(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Trip Name'),
          content: Text(widget.trip.tripName),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, ExpensesLoaded state) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<ExpenseBloc>().add(LoadExpenses(widget.trip.tripId!));
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: ExpenseSummaryCard(summary: state.summary),
          ),
          SliverToBoxAdapter(
            child: _buildFilterOptions(context),
          ),
          SliverPadding(
            padding: const EdgeInsets.only(top: 16),
            sliver: state.summary.expenses.isEmpty
                ? SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyExpenseList(context),
                  )
                : _buildExpenseList(context, state.summary.expenses),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOptions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton.icon(
            onPressed: () => _showDateFilterDialog(context),
            icon: const Icon(Icons.filter_list),
            label: const Text('Filter'),
          ),
          ElevatedButton.icon(
            onPressed: _toggleSortOrder,
            icon:
                Icon(_isAscending ? Icons.arrow_upward : Icons.arrow_downward),
            label: Text(_isAscending ? 'Oldest First' : 'Newest First'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyExpenseList(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.money_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No expenses found',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _addExpense(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Expense'),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseList(BuildContext context, List<ExpenseModel> expenses) {
    final currentUserId = context.read<AuthNotifier>().postgresUserId;

    // Apply date filters
    List<ExpenseModel> filteredExpenses = expenses;
    if (_startDate != null) {
      filteredExpenses = filteredExpenses
          .where((e) => e.createdAt.isAfter(_startDate!))
          .toList();
    }
    if (_endDate != null) {
      filteredExpenses = filteredExpenses
          .where((e) =>
              e.createdAt.isBefore(_endDate!.add(const Duration(days: 1))))
          .toList();
    }

    // Sort expenses
    filteredExpenses.sort((a, b) => _isAscending
        ? a.createdAt.compareTo(b.createdAt)
        : b.createdAt.compareTo(a.createdAt));

    // Group expenses by date
    final groupedExpenses = groupExpensesByDate(filteredExpenses);

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final date = groupedExpenses.keys.elementAt(index);
          final expensesForDate = groupedExpenses[date]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  DateFormat('MMMM d, yyyy').format(date),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              ...expensesForDate.map((expense) => ExpenseListItem(
                    expense: expense,
                    currentUserId: currentUserId!,
                    onTap: () => _viewExpenseDetails(context, expense),
                  )),
            ],
          );
        },
        childCount: groupedExpenses.length,
      ),
    );
  }

  Map<DateTime, List<ExpenseModel>> groupExpensesByDate(
      List<ExpenseModel> expenses) {
    final groupedExpenses = <DateTime, List<ExpenseModel>>{};
    for (final expense in expenses) {
      final date = DateTime(expense.createdAt.year, expense.createdAt.month,
          expense.createdAt.day);
      if (!groupedExpenses.containsKey(date)) {
        groupedExpenses[date] = [];
      }
      groupedExpenses[date]!.add(expense);
    }
    return groupedExpenses;
  }

  void _addExpense(BuildContext context) async {
    final result = await Navigator.pushNamed(
      context,
      Routes.addEditExpense,
      arguments: {
        'tripId': widget.trip.tripId,
        'tripParticipants': widget.trip.participants,
      },
    );

    if (result == true) {
      // Refresh expenses if the expense was added successfully
      if (context.mounted) {
        context.read<ExpenseBloc>().add(LoadExpenses(widget.trip.tripId!));
      }
    }
  }

  void _viewExpenseDetails(BuildContext context, ExpenseModel expense) async {
    final expenseBloc = context.read<ExpenseBloc>();
    final updatedExpense = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExpenseDetailsScreen(
          expense: expense,
          tripParticipants: widget.trip.participants,
          onExpenseUpdated: (updatedExpense) {
            expenseBloc.add(LoadExpenses(widget.trip.tripId!));
          },
          expenseBloc: expenseBloc,
        ),
      ),
    );

    if (updatedExpense != null) {
      expenseBloc.add(LoadExpenses(widget.trip.tripId!));
    }
  }

  void _showBalances(BuildContext context) {
    final state = context.read<ExpenseBloc>().state;
    if (state is ExpensesLoaded) {
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              BalancesScreen(
            trip: widget.trip,
            summary: state.summary,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;
            var tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);
            return SlideTransition(position: offsetAnimation, child: child);
          },
        ),
      );
    }
  }

  void _showDateFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Filter Expenses'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                    initialDateRange: DateTimeRange(
                      start: _startDate ??
                          DateTime.now().subtract(const Duration(days: 30)),
                      end: _endDate ?? DateTime.now(),
                    ),
                  );
                  if (picked != null) {
                    setState(() {
                      _startDate = picked.start;
                      _endDate = picked.end;
                    });
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  }
                },
                child: const Text('Select Date Range'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _startDate = null;
                    _endDate = null;
                  });
                  Navigator.of(context).pop();
                },
                child: const Text('Clear Filters'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _toggleSortOrder() {
    setState(() {
      _isAscending = !_isAscending;
    });
  }
}
