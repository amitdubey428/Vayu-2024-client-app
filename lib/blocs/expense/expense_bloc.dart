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

class PredictExpenseCategory extends ExpenseEvent {
  final String description;
  PredictExpenseCategory(this.description);
}

class UpdateExpenseCategory extends ExpenseEvent {
  final int expenseId;
  final String category;
  UpdateExpenseCategory(this.expenseId, this.category);
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

class ExpenseCategoryPredicted extends ExpenseState {
  final String category;
  final double confidence;
  ExpenseCategoryPredicted(this.category, this.confidence);
}

class ExpenseCategoryUpdated extends ExpenseState {}

class ExpenseBloc extends Bloc<ExpenseEvent, ExpenseState> {
  final ExpenseRepository _expenseRepository;

  ExpenseBloc(this._expenseRepository) : super(ExpenseInitial()) {
    on<LoadExpenses>(_onLoadExpenses);
    on<AddExpense>(_onAddExpense);
    on<UpdateExpense>(_onUpdateExpense);
    on<DeleteExpense>(_onDeleteExpense);
    on<PredictExpenseCategory>(_onPredictExpenseCategory);
    on<UpdateExpenseCategory>(_onUpdateExpenseCategory);
  }

  Future<void> _onAddExpense(
      AddExpense event, Emitter<ExpenseState> emit) async {
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

  Future<void> _onPredictExpenseCategory(
    PredictExpenseCategory event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(ExpenseLoading());
    try {
      final prediction =
          await _expenseRepository.predictCategory(event.description);
      emit(
          ExpenseCategoryPredicted(prediction.category, prediction.confidence));
    } catch (e) {
      emit(ExpenseError(e.toString()));
    }
  }

  Future<void> _onUpdateExpenseCategory(
    UpdateExpenseCategory event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(ExpenseLoading());
    try {
      await _expenseRepository.updateExpenseCategory(
          event.expenseId, event.category);
      emit(ExpenseCategoryUpdated());
    } catch (e) {
      emit(ExpenseError(e.toString()));
    }
  }
}
