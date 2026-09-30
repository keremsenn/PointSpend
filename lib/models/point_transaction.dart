enum TransactionType { income, expense }

class PointTransaction {
  const PointTransaction({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.type,
  });

  final String title;
  final String subtitle;
  final String amount;
  final TransactionType type;
}
