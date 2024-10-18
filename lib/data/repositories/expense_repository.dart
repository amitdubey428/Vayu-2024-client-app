import 'package:vayu_flutter_app/services/expense_service.dart';
import 'package:vayu_flutter_app/data/models/expense_model.dart';

class ExpenseRepository {
  final ExpenseService _expenseService;

  ExpenseRepository(this._expenseService);

  Future<TripExpenseResponse> getExpenses(int tripId) async {
    return await _expenseService.getExpenses(tripId);
  }

  Future<void> addExpense(ExpenseModel expense) async {
    try {
      await _expenseService.addExpense(expense);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> updateExpense(ExpenseModel expense) async {
    await _expenseService.updateExpense(expense);
  }

  Future<void> deleteExpense(int expenseId) async {
    await _expenseService.deleteExpense(expenseId);
  }

  Future<CategoryPrediction> predictCategory(String description) async {
    return await _expenseService.predictCategory(description);
  }

  Future<void> updateExpenseCategory(int expenseId, String category) async {
    await _expenseService.updateExpenseCategory(expenseId, category);
  }
}
