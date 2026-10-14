enum TransactionType { income, expense }

extension TransactionTypeX on TransactionType {
  String get value => switch (this) {
    TransactionType.income => 'income',
    TransactionType.expense => 'expense',
  };

  static TransactionType fromValue(String value) {
    switch (value) {
      case 'income':
        return TransactionType.income;
      case 'expense':
        return TransactionType.expense;
      default:
        return TransactionType.expense;
    }
  }
}

class PointTransaction {
  const PointTransaction({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.type,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String subtitle;
  final String amount;
  final TransactionType type;
  final DateTime createdAt;

  PointTransaction copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? amount,
    TransactionType? type,
    DateTime? createdAt,
  }) {
    return PointTransaction(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'amount': amount,
      'type': type.value,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PointTransaction.fromMap(Map<String, dynamic> map) {
    return PointTransaction(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      subtitle: map['subtitle'] as String? ?? '',
      amount: map['amount'] as String? ?? '0',
      type: TransactionTypeX.fromValue(map['type'] as String? ?? 'expense'),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
