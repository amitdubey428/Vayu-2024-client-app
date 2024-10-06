import 'package:vayu_flutter_app/data/models/expense_model.dart';
import 'package:vayu_flutter_app/services/api_service.dart';
import 'dart:convert';

class ExpenseService {
  final ApiService _apiService;

  ExpenseService(this._apiService);

  Future<TripExpenseResponse> getExpenses(int tripId) async {
    final response = await _apiService.get('/expenses/trip/$tripId');
    final jsonData = jsonDecode(response.body);
    return TripExpenseResponse.fromJson(jsonData);
  }

  Future<void> addExpense(ExpenseModel expense) async {
    final response =
        await _apiService.post('/expenses', body: expense.toJson());
    if (response.statusCode >= 400) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['detail'] ?? 'Failed to add expense');
    }
  }

  Future<void> updateExpense(ExpenseModel expense) async {
    await _apiService.put('/expenses/${expense.expenseId}',
        body: expense.toJson());
  }

  Future<void> deleteExpense(int expenseId) async {
    await _apiService.delete('/expenses/$expenseId');
  }
}
