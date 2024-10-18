import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vayu_flutter_app/blocs/expense/expense_bloc.dart';
import 'package:vayu_flutter_app/data/models/expense_model.dart';
import 'package:vayu_flutter_app/data/models/user_model.dart';
import 'package:vayu_flutter_app/shared/widgets/custom_text_form_field.dart';

class RecordPaymentScreen extends StatefulWidget {
  final ExpenseModel expense;
  final List<UserModel> tripParticipants;

  const RecordPaymentScreen({
    super.key,
    required this.expense,
    required this.tripParticipants,
  });

  @override
  State<RecordPaymentScreen> createState() => _RecordPaymentScreenState();
}

class _RecordPaymentScreenState extends State<RecordPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  int? _selectedUserId;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Payment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<int>(
                value: _selectedUserId,
                items: widget.tripParticipants.map((user) {
                  return DropdownMenuItem<int>(
                    value: user.uid.hashCode,
                    child: Text(user.fullName ?? 'User ${user.uid}'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedUserId = value;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Payer',
                ),
                validator: (value) =>
                    value == null ? 'Please select a payer' : null,
              ),
              const SizedBox(height: 16),
              CustomTextFormField(
                controller: _amountController,
                labelText: 'Amount',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
                hintText: 'Amount',
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _recordPayment,
                  child: const Text('Record Payment'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _recordPayment() {
    if (_formKey.currentState!.validate()) {
      final payment = ExpensePayment(
        userId: _selectedUserId!,
        amountPaid: double.parse(_amountController.text),
      );
      final updatedExpense = widget.expense.copyWith(
        payments: [...widget.expense.payments, payment],
      );
      context.read<ExpenseBloc>().add(UpdateExpense(updatedExpense));
      Navigator.pop(context);
    }
  }
}
