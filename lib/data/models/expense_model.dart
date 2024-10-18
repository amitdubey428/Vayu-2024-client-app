import 'package:equatable/equatable.dart';
import 'dart:developer' as developer;

class CurrencySummary {
  final double totalTripSpend;
  final double userTotalSpend;
  final double userShare;
  final double userBalance;

  CurrencySummary({
    required this.totalTripSpend,
    required this.userTotalSpend,
    required this.userShare,
    required this.userBalance,
  });

  factory CurrencySummary.fromJson(Map<String, dynamic> json) {
    return CurrencySummary(
      totalTripSpend: double.parse(json['total_trip_spend'].toString()),
      userTotalSpend: double.parse(json['user_total_spend'].toString()),
      userShare: double.parse(json['user_share'].toString()),
      userBalance: double.parse(json['user_balance'].toString()),
    );
  }
}

class TripExpenseSummary {
  final List<ExpenseModel> expenses;
  final Map<String, CurrencySummary> currencySummaries;
  final int totalCount;

  TripExpenseSummary({
    required this.expenses,
    required this.currencySummaries,
    required this.totalCount,
  });

  factory TripExpenseSummary.fromJson(Map<String, dynamic> json) {
    return TripExpenseSummary(
      expenses: (json['expenses'] as List)
          .map((e) => ExpenseModel.fromJson(e))
          .toList(),
      currencySummaries:
          (json['currency_summaries'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, CurrencySummary.fromJson(value)),
      ),
      totalCount: json['total_count'],
    );
  }
}

class TripExpenseResponse {
  final TripExpenseSummary summary;
  final int page;
  final int perPage;

  TripExpenseResponse({
    required this.summary,
    required this.page,
    required this.perPage,
  });

  factory TripExpenseResponse.fromJson(Map<String, dynamic> json) {
    return TripExpenseResponse(
      summary: TripExpenseSummary.fromJson(json['summary']),
      page: json['page'],
      perPage: json['per_page'],
    );
  }
}

class PaginatedExpenseResponse {
  final List<ExpenseModel> items;
  final int total;
  final int page;
  final int perPage;

  PaginatedExpenseResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.perPage,
  });

  factory PaginatedExpenseResponse.fromJson(Map<String, dynamic> json) {
    try {
      return PaginatedExpenseResponse(
        items: (json['items'] as List)
            .map((item) => ExpenseModel.fromJson(item))
            .toList(),
        total: json['total'],
        page: json['page'],
        perPage: json['per_page'],
      );
    } catch (e, stackTrace) {
      developer.log('Error parsing PaginatedExpenseResponse: $e');
      developer.log('JSON data: $json');
      developer.log('StackTrace: $stackTrace');
      rethrow;
    }
  }
}

class ExpenseModel extends Equatable {
  final int? expenseId;
  final int tripId;
  final double amount;
  final String description;
  final String category;
  final String currency;
  final int createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String splitMethod;
  final List<ExpenseSplit> splits;
  final List<ExpensePayment> payments;
  final bool isIndependent;
  final String status;
  final String? notes;
  final DateTime transactionDate;

  const ExpenseModel({
    this.expenseId,
    required this.tripId,
    required this.amount,
    required this.description,
    required this.category,
    required this.currency,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.splitMethod,
    required this.splits,
    required this.payments,
    this.isIndependent = false,
    required this.status,
    this.notes,
    required this.transactionDate,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      expenseId: json['expense_id'],
      tripId: json['trip_id'],
      amount: json['amount'] != null
          ? (json['amount'] is String
              ? double.parse(json['amount'])
              : json['amount'].toDouble())
          : json['total_amount'] != null
              ? (json['total_amount'] is String
                  ? double.parse(json['total_amount'])
                  : json['total_amount'].toDouble())
              : 0.0,
      description: json['description'],
      category: json['category'],
      currency: json['currency'],
      createdBy: json['created_by'],
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(
          json['updated_at'] ?? DateTime.now().toIso8601String()),
      splitMethod: json['split_method'] ?? 'equal',
      splits: (json['splits'] as List?)
              ?.map((s) => ExpenseSplit.fromJson(s))
              .toList() ??
          [],
      payments: (json['payments'] as List?)
              ?.map((p) => ExpensePayment.fromJson(p))
              .toList() ??
          [],
      isIndependent: json['is_independent'] ?? false,
      status: json['status'] as String,
      notes: json['notes'],
      transactionDate: DateTime.parse(json['transaction_date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'expense_id': expenseId,
      'trip_id': tripId,
      'amount': amount,
      'description': description,
      'category': category,
      'currency': currency,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'split_method': splitMethod,
      'splits': splits.map((s) => s.toJson()).toList(),
      'payments': payments.map((p) => p.toJson()).toList(),
      'is_independent': isIndependent,
      'notes': notes,
      'transaction_date': transactionDate.toIso8601String(),
    };
  }

  ExpenseModel copyWith({
    int? expenseId,
    int? tripId,
    double? amount,
    String? description,
    String? category,
    String? currency,
    int? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? splitMethod,
    List<ExpenseSplit>? splits,
    List<ExpensePayment>? payments,
    bool? isIndependent,
    String? status,
    String? notes,
    DateTime? transactionDate,
  }) {
    return ExpenseModel(
      expenseId: expenseId ?? this.expenseId,
      tripId: tripId ?? this.tripId,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      category: category ?? this.category,
      currency: currency ?? this.currency,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      splits: splits ?? this.splits,
      payments: payments ?? this.payments,
      isIndependent: isIndependent ?? this.isIndependent,
      splitMethod: splitMethod ?? this.splitMethod,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      transactionDate: transactionDate ?? this.transactionDate,
    );
  }

  @override
  List<Object?> get props => [
        expenseId,
        tripId,
        amount,
        description,
        category,
        currency,
        createdBy,
        createdAt,
        updatedAt,
        splits,
        payments,
        isIndependent,
        splitMethod,
        status,
        notes,
        transactionDate,
      ];
}

class ExpenseSplit extends Equatable {
  final int userId;
  final double? amount;

  const ExpenseSplit({required this.userId, this.amount});

  factory ExpenseSplit.fromJson(Map<String, dynamic> json) {
    return ExpenseSplit(
      userId: json['user_id'],
      amount: json['amount'] != null
          ? (json['amount'] is String
              ? double.parse(json['amount'])
              : json['amount'].toDouble())
          : null,
    );
  }

  ExpenseSplit copyWith({double? amount}) {
    return ExpenseSplit(
      userId: userId,
      amount: amount ?? this.amount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'amount': amount,
    };
  }

  @override
  List<Object?> get props => [userId, amount];
}

class ExpensePayment extends Equatable {
  final int userId;
  final double amountPaid;

  const ExpensePayment({required this.userId, required this.amountPaid});

  factory ExpensePayment.fromJson(Map<String, dynamic> json) {
    return ExpensePayment(
      userId: json['user_id'],
      amountPaid: json['amount_paid'] is String
          ? double.parse(json['amount_paid'])
          : json['amount_paid'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'amount_paid': amountPaid,
    };
  }

  @override
  List<Object?> get props => [userId, amountPaid];
}

class CategoryPrediction {
  final String category;
  final double confidence;

  CategoryPrediction({required this.category, required this.confidence});

  factory CategoryPrediction.fromJson(Map<String, dynamic> json) {
    return CategoryPrediction(
      category: json['category'],
      confidence: json['confidence'].toDouble(),
    );
  }
}
