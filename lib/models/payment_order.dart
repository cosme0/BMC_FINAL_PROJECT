/// A row from the Supabase `orders` table (guest checkout).
class PaymentOrder {
  final String externalId;
  final String status;
  final String productName;
  final double amount;
  final DateTime createdAt;

  const PaymentOrder({
    required this.externalId,
    required this.status,
    required this.productName,
    required this.amount,
    required this.createdAt,
  });

  bool get isPaid => status.toUpperCase() == 'PAID';

  factory PaymentOrder.fromMap(Map<String, dynamic> data) {
    return PaymentOrder(
      externalId: (data['external_id'] ?? '').toString(),
      status: (data['status'] ?? 'PENDING').toString(),
      productName: (data['product_name'] ?? 'Order').toString(),
      amount: (data['amount'] as num? ?? 0).toDouble(),
      createdAt:
          DateTime.tryParse((data['created_at'] ?? '').toString())?.toLocal() ??
          DateTime.now(),
    );
  }
}
