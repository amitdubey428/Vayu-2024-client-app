import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:vayu_flutter_app/blocs/expense/expense_bloc.dart';
import 'package:vayu_flutter_app/core/themes/app_theme.dart';
import 'package:vayu_flutter_app/data/models/expense_model.dart';
import 'package:vayu_flutter_app/data/models/user_public_info.dart';
import 'package:vayu_flutter_app/features/expenses/widgets/split_details_view.dart';
import 'package:vayu_flutter_app/services/auth_notifier.dart';
import 'package:vayu_flutter_app/shared/widgets/custom_loading_indicator.dart';
import 'package:vayu_flutter_app/shared/widgets/custom_text_form_field.dart';
import 'package:vayu_flutter_app/shared/widgets/snackbar_util.dart';

enum SplitMethod { equal, unequal, percentage, shares }

class AddEditExpenseScreen extends StatefulWidget {
  final int tripId;
  final ExpenseModel? expense;
  final List<UserPublicInfo> tripParticipants;
  final ExpenseBloc expenseBloc;

  const AddEditExpenseScreen({
    super.key,
    required this.tripId,
    this.expense,
    required this.tripParticipants,
    required this.expenseBloc,
  });

  @override
  State<AddEditExpenseScreen> createState() => _AddEditExpenseScreenState();
}

class _AddEditExpenseScreenState extends State<AddEditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _currencyController;
  late Map<int, double> _paidBy;
  late Map<int, double> _splits;
  late Set<int> _selectedParticipants;
  late SplitMethod _splitMethod;
  late TextEditingController _notesController;
  static const List<String> currencies = [
    'USD',
    'EUR',
    'GBP',
    'JPY',
    'AUD',
    'CAD',
    'CHF',
    'CNY',
    'INR'
  ];
  bool _isFormChanged = false;
  late TextEditingController _categoryController;
  IconData _categoryIcon = Icons.category;
  final List<String> allCategories = [
    'Food',
    'Transportation',
    'Accommodation',
    'Entertainment',
    'Shopping',
    'Health',
    'Education',
    'Utilities',
    'Personal',
    'Gifts',
    'Travel',
    'Business',
    'Investments',
    'Bills',
    'Subscriptions',
    'Other'
  ];
  Timer? _debounce;
  late DateTime _transactionDate;
  bool _formSubmitted = false;

  String getCurrencyCode(String currencyCode) {
    return currencyCode;
  }

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.expense?.description ?? '');
    _amountController =
        TextEditingController(text: widget.expense?.amount.toString() ?? '');
    _currencyController =
        TextEditingController(text: widget.expense?.currency ?? 'INR');
    _initializePaidBy();
    _initializeSplits();
    _selectedParticipants =
        widget.tripParticipants.map((p) => p.userId).toSet();
    _splitMethod = SplitMethod.equal;
    _notesController = TextEditingController(text: widget.expense?.notes ?? '');
    _categoryController =
        TextEditingController(text: widget.expense?.category ?? '');

    if (widget.expense != null) {
      _splitMethod = SplitMethod.unequal;
      _splits = Map.fromEntries(widget.expense!.splits
          .map((split) => MapEntry(split.userId, split.amount ?? 0.0)));
    }
    _transactionDate = widget.expense?.transactionDate ?? DateTime.now();

    // Add listeners to all controllers to detect changes
    _titleController.addListener(_onFormChanged);
    _amountController.addListener(_onFormChanged);
    _currencyController.addListener(_onFormChanged);
    _notesController.addListener(_onFormChanged);
    _categoryController.addListener(_onFormChanged);
  }

  void _onFormChanged() {
    setState(() {
      _isFormChanged = true;
    });
  }

  void _initializePaidBy() {
    if (widget.expense != null) {
      _paidBy = {
        for (var payment in widget.expense!.payments)
          payment.userId: payment.amountPaid
      };
    } else {
      _paidBy = {
        context.read<AuthNotifier>().postgresUserId!:
            double.tryParse(_amountController.text) ?? 0
      };
    }
  }

  String? _validateField(String? value, String fieldName) {
    if (!_formSubmitted) return null;

    if (value == null || value.isEmpty) {
      return 'Please enter $fieldName';
    }
    if (fieldName == 'Title' && value.length < 3) {
      return '$fieldName must be at least 3 characters long';
    }
    return null;
  }

  String? _validateAmount(String? value) {
    if (!_formSubmitted) return null;

    if (value == null || value.isEmpty) {
      return 'Please enter an amount';
    }
    if (double.tryParse(value) == null) {
      return 'Please enter a valid number';
    }
    if (double.parse(value) <= 0) {
      return 'Amount must be greater than zero';
    }
    return null;
  }

  void _initializeSplits() {
    if (widget.expense != null) {
      _splits = {
        for (var split in widget.expense!.splits)
          split.userId: split.amount ?? 0.0
      };
    } else {
      double equalSplit = widget.tripParticipants.isNotEmpty
          ? double.tryParse(_amountController.text) ??
              0 / widget.tripParticipants.length
          : 0.0;
      _splits = {
        for (var user in widget.tripParticipants) user.userId: equalSplit
      };
    }
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: _transactionDate,
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
          builder: (BuildContext context, Widget? child) {
            return Theme(
              data: ThemeData.light().copyWith(
                primaryColor: AppTheme.primaryColor,
                colorScheme:
                    const ColorScheme.light(primary: AppTheme.primaryColor),
                buttonTheme:
                    const ButtonThemeData(textTheme: ButtonTextTheme.primary),
              ),
              child: child!,
            );
          },
        );
        if (picked != null && picked != _transactionDate) {
          setState(() {
            _transactionDate = picked;
          });
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Transaction Date',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(DateFormat('MMM dd, yyyy').format(_transactionDate)),
            const Icon(Icons.calendar_today, color: AppTheme.primaryColor),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.removeListener(_onFormChanged);
    _amountController.removeListener(_onFormChanged);
    _currencyController.removeListener(_onFormChanged);
    _notesController.removeListener(_onFormChanged);
    _titleController.dispose();
    _amountController.dispose();
    _currencyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Widget _buildParticipantSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8.0,
          children: widget.tripParticipants.map((user) {
            bool isSelected = _selectedParticipants.contains(user.userId);
            return FilterChip(
              label: Text(user.fullName ?? 'User ${user.userId}'),
              selected: isSelected,
              onSelected: (bool selected) {
                setState(() {
                  if (selected) {
                    _selectedParticipants.add(user.userId);
                  } else {
                    _selectedParticipants.remove(user.userId);
                  }
                  _recalculateSplits();
                });
              },
            );
          }).toList(),
        ),
        if (_selectedParticipants.isEmpty)
          const Text(
            'Please select at least one participant',
            style: TextStyle(color: Colors.red, fontSize: 12),
          ),
      ],
    );
  }

  Widget _buildSplitMethodSelector() {
    return DropdownButtonFormField<SplitMethod>(
      value: _splitMethod,
      items: SplitMethod.values.map((method) {
        return DropdownMenuItem(
          value: method,
          child: Text(method.toString().split('.').last.capitalize()),
        );
      }).toList(),
      onChanged: (SplitMethod? newValue) {
        if (newValue != null) {
          setState(() {
            _splitMethod = newValue;
            _recalculateSplits();
          });
        }
      },
      decoration: const InputDecoration(
        labelText: 'Split Method',
        border: OutlineInputBorder(),
      ),
    );
  }

  List<Widget> _buildPaidByFields() {
    final theme = Theme.of(context);
    return _paidBy.entries.map((entry) {
      UserPublicInfo user =
          widget.tripParticipants.firstWhere((u) => u.userId == entry.key);
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(user.fullName ?? 'User ${user.userId}'),
            ),
            Expanded(
              flex: 3,
              child: TextFormField(
                initialValue: entry.value.toString(),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                onChanged: (value) {
                  setState(() {
                    _paidBy[entry.key] = double.tryParse(value) ?? 0;
                  });
                },
                decoration: InputDecoration(
                  hintStyle: TextStyle(color: theme.hintColor),
                  labelStyle: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.7)),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(
                        color: theme.colorScheme.onSurface.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: theme.colorScheme.primary),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(
                        color: theme.colorScheme.onSurface.withOpacity(0.3)),
                  ),
                ),
                onTap: () {
                  Future.delayed(const Duration(milliseconds: 100), () {
                    final controller = TextEditingController.fromValue(
                      TextEditingValue(
                        text: entry.value.toString(),
                        selection: TextSelection(
                          baseOffset: 0,
                          extentOffset: entry.value.toString().length,
                        ),
                      ),
                    );
                    controller.selection = TextSelection(
                      baseOffset: 0,
                      extentOffset: controller.text.length,
                    );
                  });
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle),
              onPressed: () {
                setState(() {
                  _paidBy.remove(entry.key);
                });
              },
            ),
          ],
        ),
      );
    }).toList();
  }

  void _addPayer() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        int? selectedUserId;
        return AlertDialog(
          title: const Text('Add Payer'),
          content: DropdownButtonFormField<int>(
            value: selectedUserId,
            items: widget.tripParticipants
                .where((user) => !_paidBy.containsKey(user.userId))
                .map((user) {
              return DropdownMenuItem(
                value: user.userId,
                child: Text(user.fullName ?? 'User ${user.userId}'),
              );
            }).toList(),
            onChanged: (value) {
              selectedUserId = value;
            },
            decoration: const InputDecoration(
              labelText: 'Select Payer',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                if (selectedUserId != null) {
                  setState(() {
                    _paidBy[selectedUserId!] = 0;
                  });
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildSplitFields() {
    double totalAmount = double.tryParse(_amountController.text) ?? 0;
    int participantCount = _selectedParticipants.length;

    Widget buildSplitSummary() {
      String summaryText;
      switch (_splitMethod) {
        case SplitMethod.equal:
          double equalSplit =
              participantCount > 0 ? totalAmount / participantCount : 0;
          summaryText =
              'Split equally: ${equalSplit.toStringAsFixed(2)} ${_currencyController.text} per person';
          break;
        case SplitMethod.unequal:
          summaryText = 'Split unequally among $participantCount members';
          break;
        case SplitMethod.percentage:
          summaryText = 'Split by percentage among $participantCount members';
          break;
        case SplitMethod.shares:
          summaryText = 'Split by shares among $participantCount members';
          break;
      }

      return Card(
        color: Theme.of(context).colorScheme.surface,
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                summaryText,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              ..._selectedParticipants.map((userId) {
                UserPublicInfo user = widget.tripParticipants
                    .firstWhere((u) => u.userId == userId);
                double splitValue = _splits[userId] ?? 0;
                double amount = 0;
                switch (_splitMethod) {
                  case SplitMethod.equal:
                    amount = totalAmount / participantCount;
                    break;
                  case SplitMethod.unequal:
                    amount = splitValue;
                    break;
                  case SplitMethod.percentage:
                    amount = totalAmount * splitValue / 100;
                    break;
                  case SplitMethod.shares:
                    int totalShares = _splits.values
                        .fold(0, (sum, value) => sum + value.round());
                    amount = totalAmount * splitValue / totalShares;
                    break;
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(
                    '${user.fullName}: ${amount.toStringAsFixed(2)} ${_currencyController.text}',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface),
                  ),
                );
              }),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _showSplitDetailsModal,
                child: const Text('View/Edit Split Details'),
              ),
            ],
          ),
        ),
      );
    }

    return buildSplitSummary();
  }

  bool _isFormValid() {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return false;
    }

    double totalAmount = double.tryParse(_amountController.text) ?? 0;
    double totalPaid = _paidBy.values.fold(0, (sum, amount) => sum + (amount));

    if (_selectedParticipants.isEmpty) {
      return false;
    }

    if ((totalPaid - totalAmount).abs() >= 0.01) {
      return false;
    }

    if (_selectedParticipants.length == 1) {
      return true;
    }

    double totalSplit = _remainingToSplit();
    return totalSplit.abs() < 0.01 || _isFormChanged;
  }

  double _remainingToSplit() {
    double totalAmount = double.tryParse(_amountController.text) ?? 0;
    double splitAmount = 0;

    switch (_splitMethod) {
      case SplitMethod.equal:
      case SplitMethod.unequal:
        splitAmount = _splits.values.fold(0, (sum, amount) => sum + amount);
        break;
      case SplitMethod.percentage:
        splitAmount = _splits.values.fold(0, (sum, percentage) {
          return sum + (totalAmount * percentage / 100);
        });
        break;
      case SplitMethod.shares:
        int totalShares =
            _splits.values.fold(0, (sum, shares) => sum + shares.round());
        if (totalShares > 0) {
          splitAmount = _splits.values.fold(0, (sum, shares) {
            return sum + (totalAmount * shares / totalShares);
          });
        }
        break;
    }

    return totalAmount - splitAmount;
  }

  void _showSplitDetailsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.9,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              expand: false,
              builder: (_, controller) {
                return SplitDetailsView(
                  participants: widget.tripParticipants,
                  selectedParticipants: _selectedParticipants,
                  splits: _splits,
                  splitMethod: _splitMethod,
                  totalAmount: double.tryParse(_amountController.text) ?? 0,
                  currency: _currencyController.text,
                  onSplitUpdated: (newSplits) {
                    setModalState(() {
                      _splits = Map.from(newSplits);
                    });
                    setState(() {
                      _splits = Map.from(newSplits);
                    });
                  },
                  getCurrencyCode: getCurrencyCode,
                  remainingToSplit: _remainingToSplit,
                );
              },
            );
          },
        );
      },
    );
  }

  void _recalculateSplits() {
    double totalAmount = double.tryParse(_amountController.text) ?? 0;
    int participantCount = _selectedParticipants.length;

    switch (_splitMethod) {
      case SplitMethod.equal:
        // Handle the case when there's only one participant
        double equalSplit =
            participantCount > 0 ? totalAmount / participantCount : totalAmount;
        for (int userId in _selectedParticipants) {
          _splits[userId] = equalSplit;
        }
        break;
      case SplitMethod.unequal:
        // For unequal, we should ensure that the total split equals the total amount
        if (_splits.isEmpty ||
            (_splits.values.fold(0.0, (sum, value) => sum + value) -
                        totalAmount)
                    .abs() >
                0.01) {
          for (int userId in _selectedParticipants) {
            _splits[userId] = totalAmount / participantCount;
          }
        }
        break;
      case SplitMethod.percentage:
        double totalPercentage =
            _splits.values.fold(0, (sum, value) => sum + value);
        if (totalPercentage != 100 || _splits.length != participantCount) {
          double equalPercentage =
              participantCount > 0 ? 100 / participantCount : 100;
          for (int userId in _selectedParticipants) {
            _splits[userId] = equalPercentage;
          }
        }
        break;
      case SplitMethod.shares:
        int totalShares =
            _splits.values.fold(0, (sum, value) => sum + value.round());
        if (totalShares == 0 || _splits.length != participantCount) {
          for (int userId in _selectedParticipants) {
            _splits[userId] = 1;
          }
        }
        break;
    }

    // Remove splits for unselected participants
    _splits.removeWhere((userId, _) => !_selectedParticipants.contains(userId));
  }

  void _saveExpense() {
    setState(() {
      _formSubmitted = true;
    });
    if (_formKey.currentState!.validate()) {
      final expenseBloc = context.read<ExpenseBloc>();
      final authNotifier = context.read<AuthNotifier>();

      double totalAmount = double.tryParse(_amountController.text) ?? 0;

      // Remove payees with zero amounts
      _paidBy.removeWhere((_, amount) => amount == 0);

      double totalPayments =
          _paidBy.values.fold(0, (sum, amount) => sum + amount);
      if ((totalPayments - totalAmount).abs() > 0.01) {
        SnackbarUtil.showSnackbar(
            "Total payments must equal the expense amount",
            type: SnackbarType.error);
        return;
      }

      // Create payments from _paidBy (now only non-zero amounts)
      List<ExpensePayment> payments = _paidBy.entries
          .map((entry) =>
              ExpensePayment(userId: entry.key, amountPaid: entry.value))
          .toList();

      // Create splits based on the split method
      List<ExpenseSplit> splits = [];
      switch (_splitMethod) {
        case SplitMethod.equal:
          splits = _selectedParticipants
              .map((userId) => ExpenseSplit(userId: userId, amount: null))
              .toList();
          break;
        case SplitMethod.unequal:
        case SplitMethod.percentage:
        case SplitMethod.shares:
          splits = _splits.entries
              .where((entry) => _selectedParticipants.contains(entry.key))
              .map((entry) =>
                  ExpenseSplit(userId: entry.key, amount: entry.value))
              .toList();
          break;
      }

      final expense = ExpenseModel(
        expenseId: widget.expense?.expenseId,
        tripId: widget.tripId,
        amount: totalAmount,
        description: _titleController.text,
        category: _categoryController.text,
        currency: _currencyController.text,
        createdBy: authNotifier.postgresUserId!,
        createdAt: widget.expense?.createdAt ?? DateTime.now(),
        updatedAt: widget.expense?.updatedAt ?? DateTime.now(),
        splitMethod: _splitMethod.toString().split('.').last,
        splits: splits,
        payments: payments,
        isIndependent: false,
        status: 'pending',
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        transactionDate: _transactionDate,
      );

      if (widget.expense == null) {
        expenseBloc.add(AddExpense(expense));
      } else {
        expenseBloc.add(UpdateExpense(expense));
      }
    } else {
      // If validation fails, scroll to the top of the form to show errors
      Scrollable.ensureVisible(
        _formKey.currentContext!,
        alignment: 0.0,
        duration: const Duration(milliseconds: 300),
      );
    }
  }

  Widget _buildAmountField() {
    return CustomTextFormField(
      controller: _amountController,
      labelText: 'Amount',
      hintText: 'Enter the amount',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      validator: _validateAmount,
      onTap: () {
        _amountController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _amountController.text.length,
        );
      },
      onChanged: (value) {
        setState(() {
          _recalculateSplits();
        });
      },
    );
  }

  Widget _buildRemainingAmountDisplay() {
    double totalAmount = double.tryParse(_amountController.text) ?? 0;
    double totalPaid = _paidBy.values.fold(0, (sum, amount) => sum + amount);
    double totalSplit = 0;

    switch (_splitMethod) {
      case SplitMethod.equal:
      case SplitMethod.unequal:
        totalSplit = _splits.values.fold(0, (sum, amount) => sum + amount);
        break;
      case SplitMethod.percentage:
        double totalPercentage =
            _splits.values.fold(0, (sum, amount) => sum + amount);
        totalSplit = totalAmount * (totalPercentage / 100);
        break;
      case SplitMethod.shares:
        int totalShares =
            _splits.values.fold(0, (sum, amount) => sum + amount.round());
        totalSplit = totalShares > 0 ? totalAmount : 0;
        break;
    }

    double remainingToPay = totalAmount - totalPaid;
    double remainingToSplit = totalAmount - totalSplit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Remaining to pay: ${remainingToPay.toStringAsFixed(2)} ${_currencyController.text}',
          style: TextStyle(
            fontSize: 14,
            color: remainingToPay.abs() < 0.01
                ? Colors.green
                : Theme.of(context).colorScheme.error,
          ),
        ),
        Text(
          'Remaining to split: ${remainingToSplit.toStringAsFixed(2)} ${_currencyController.text}',
          style: TextStyle(
            fontSize: 14,
            color: remainingToSplit.abs() < 0.01
                ? Colors.green
                : Theme.of(context).colorScheme.error,
          ),
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    return CustomTextFormField(
      controller: _notesController,
      labelText: 'Notes (Optional)',
      hintText: 'Add any additional notes',
      maxLines: 3,
    );
  }

  void _updateCategory(String title) {
    final expenseBloc = context.read<ExpenseBloc>();
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (title.length > 3) {
        expenseBloc.add(PredictExpenseCategory(title));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.expenseBloc,
      child: BlocConsumer<ExpenseBloc, ExpenseState>(
        listener: (context, state) {
          if (state is ExpenseCategoryPredicted) {
            setState(() {
              _categoryIcon = _getCategoryIcon(state.category);
              _categoryController.text = state.category;
            });
          }
          if (state is ExpensesLoaded) {
            SnackbarUtil.showSnackbar(
              widget.expense == null
                  ? 'Expense added successfully'
                  : 'Expense updated successfully',
              type: SnackbarType.success,
            );
            Navigator.pop(context, true); // Pass true to indicate success
          } else if (state is ExpenseError) {
            SnackbarUtil.showSnackbar(state.message, type: SnackbarType.error);
            // Don't pop the screen on error, allow the user to correct the issue
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title:
                  Text(widget.expense == null ? 'Add Expense' : 'Edit Expense'),
            ),
            body: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomTextFormField(
                          controller: _titleController,
                          labelText: 'Title',
                          onChanged: _updateCategory,
                          prefixIcon: GestureDetector(
                            onTap: _showCategorySelectionDialog,
                            child: Icon(_categoryIcon),
                          ),
                          validator: (value) => _validateField(value, 'Title'),
                          hintText: 'Enter the Title of the expense',
                        ),
                        const SizedBox(height: 16),
                        _buildDatePicker(),
                        const SizedBox(height: 16),
                        _buildAmountField(),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _currencyController.text.isEmpty
                              ? 'INR'
                              : _currencyController.text,
                          items: currencies.map((String currency) {
                            return DropdownMenuItem<String>(
                              value: currency,
                              child: Text(currency),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _currencyController.text = newValue!;
                            });
                          },
                          decoration: const InputDecoration(
                            labelText: 'Currency',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text('Paid By',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        ..._buildPaidByFields(),
                        ElevatedButton(
                          onPressed: _addPayer,
                          child: const Text('Add Payer'),
                        ),
                        const SizedBox(height: 16),
                        _buildRemainingAmountDisplay(),
                        const SizedBox(height: 24),
                        const Text('Split Between',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        _buildParticipantSelector(),
                        const SizedBox(height: 16),
                        _buildSplitMethodSelector(),
                        const SizedBox(height: 16),
                        _buildSplitFields(),
                        const SizedBox(height: 16),
                        _buildNotesField(),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: state is ExpenseLoading
                                ? null
                                : (_isFormValid() ? _saveExpense : null),
                            child: Text(widget.expense == null
                                ? 'Add Expense'
                                : 'Update Expense'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (state is ExpenseLoading)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: const Center(
                      child:
                          CustomLoadingIndicator(message: 'Saving expense...'),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showCategorySelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Category'),
          content: SingleChildScrollView(
            child: ListBody(
              children: allCategories.map((String category) {
                return ListTile(
                  leading: Icon(_getCategoryIcon(category)),
                  title: Text(category),
                  onTap: () {
                    setState(() {
                      _categoryController.text = category;
                      _categoryIcon = _getCategoryIcon(category);
                    });
                    Navigator.of(context).pop();
                    if (widget.expense != null) {
                      context.read<ExpenseBloc>().add(UpdateExpenseCategory(
                          widget.expense!.expenseId!, category));
                    }
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'transportation':
        return Icons.directions_car;
      case 'accommodation':
        return Icons.hotel;
      case 'entertainment':
        return Icons.movie;
      case 'shopping':
        return Icons.shopping_cart;
      case 'health':
        return Icons.local_hospital;
      case 'education':
        return Icons.school;
      case 'utilities':
        return Icons.flash_on;
      case 'personal':
        return Icons.person;
      case 'gifts':
        return Icons.card_giftcard;
      case 'travel':
        return Icons.flight;
      case 'business':
        return Icons.business;
      case 'investments':
        return Icons.trending_up;
      case 'bills':
        return Icons.receipt;
      case 'subscriptions':
        return Icons.subscriptions;
      default:
        return Icons.category;
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
