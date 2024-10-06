import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vayu_flutter_app/data/models/expense_model.dart';
import 'package:vayu_flutter_app/data/repositories/expense_repository.dart';

// Define events
abstract class ExpenseEvent {}

class LoadExpenses extends ExpenseEvent {
  final int tripId;
  LoadExpenses(this.tripId);
}

class AddExpense extends ExpenseEvent {
  final ExpenseModel expense;
  AddExpense(this.expense);
}

class UpdateExpense extends ExpenseEvent {
  final ExpenseModel expense;
  UpdateExpense(this.expense);
}

class DeleteExpense extends ExpenseEvent {
  final int expenseId;
  final int tripId;
  DeleteExpense(this.expenseId, this.tripId);
}

// Define states
abstract class ExpenseState {}

class ExpenseInitial extends ExpenseState {}

class ExpenseLoading extends ExpenseState {}

class ExpensesLoaded extends ExpenseState {
  final TripExpenseSummary summary;
  final int page;
  final int perPage;

  ExpensesLoaded({
    required this.summary,
    required this.page,
    required this.perPage,
  });
}

class ExpenseError extends ExpenseState {
  final String message;
  ExpenseError(this.message);
}

class ExpenseUpdated extends ExpenseState {
  final ExpenseModel expense;
  ExpenseUpdated(this.expense);
}

class ExpenseBloc extends Bloc<ExpenseEvent, ExpenseState> {
  final ExpenseRepository _expenseRepository;

  ExpenseBloc(this._expenseRepository) : super(ExpenseInitial()) {
    on<LoadExpenses>(_onLoadExpenses);
    on<AddExpense>((event, emit) async {
      emit(ExpenseLoading());
      try {
        await _expenseRepository.addExpense(event.expense);
        final response =
            await _expenseRepository.getExpenses(event.expense.tripId);
        emit(ExpensesLoaded(
          summary: response.summary,
          page: response.page,
          perPage: response.perPage,
        ));
      } catch (e) {
        emit(ExpenseError(e.toString()));
      }
    });
    on<UpdateExpense>(_onUpdateExpense);
    on<DeleteExpense>(_onDeleteExpense);
  }

  Future<void> _onLoadExpenses(
      LoadExpenses event, Emitter<ExpenseState> emit) async {
    emit(ExpenseLoading());
    try {
      final response = await _expenseRepository.getExpenses(event.tripId);
      emit(ExpensesLoaded(
        summary: response.summary,
        page: response.page,
        perPage: response.perPage,
      ));
    } catch (e) {
      emit(ExpenseError(e.toString()));
    }
  }

  Future<void> _onUpdateExpense(
      UpdateExpense event, Emitter<ExpenseState> emit) async {
    try {
      emit(ExpenseLoading());

      await _expenseRepository.updateExpense(event.expense);
      emit(ExpenseUpdated(event.expense));

      final response =
          await _expenseRepository.getExpenses(event.expense.tripId);
      emit(ExpensesLoaded(
        summary: response.summary,
        page: response.page,
        perPage: response.perPage,
      ));
    } catch (e) {
      emit(ExpenseError(e.toString()));
    }
  }

  Future<void> _onDeleteExpense(
      DeleteExpense event, Emitter<ExpenseState> emit) async {
    emit(ExpenseLoading());
    try {
      await _expenseRepository.deleteExpense(event.expenseId);
      final response = await _expenseRepository.getExpenses(event.tripId);
      emit(ExpensesLoaded(
        summary: response.summary,
        page: response.page,
        perPage: response.perPage,
      ));
    } catch (e) {
      emit(ExpenseError('Failed to delete expense: ${e.toString()}'));
    }
  }
}
