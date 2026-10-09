enum TxType { expense, income }

/// Immutable value object for a single income/expense entry.
class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.date,
    this.note = '',
  });

  final String id;
  final double amount;
  final TxType type;
  final String categoryId;
  final DateTime date;
  final String note;

  bool get isExpense => type == TxType.expense;

  TransactionModel copyWith({
    double? amount,
    TxType? type,
    String? categoryId,
    DateTime? date,
    String? note,
  }) {
    return TransactionModel(
      id: id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'type': type.name,
        'categoryId': categoryId,
        'date': date.toIso8601String(),
        'note': note,
      };

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: TxType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => TxType.expense,
      ),
      categoryId: json['categoryId'] as String,
      date: DateTime.parse(json['date'] as String),
      note: (json['note'] as String?) ?? '',
    );
  }
}
