class OrderModel {
  final String id;
  final String userId;
  final List<Map<String, dynamic>> items;
  final double total;
  final String status;
  final String? customerName;
  final String? phone;
  final String? address;
  final String? paymentMethod;
  final DateTime createdAt;

  const OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.total,
    required this.status,
    this.customerName,
    this.phone,
    this.address,
    this.paymentMethod,
    required this.createdAt,
  });

  factory OrderModel.fromMap(Map<String, dynamic> data, String id) {
    final ts = data['createdAt'];
    DateTime created;
    if (ts is DateTime) {
      created = ts;
    } else if (ts != null && ts.runtimeType.toString().contains('Timestamp')) {
      created = (ts as dynamic).toDate() as DateTime;
    } else {
      created = DateTime.tryParse(ts?.toString() ?? '') ?? DateTime.now();
    }
    return OrderModel(
      id: id,
      userId: (data['userId'] ?? '').toString(),
      items: (data['items'] as List? ?? []).cast<Map<String, dynamic>>(),
      total: (data['total'] as num? ?? 0).toDouble(),
      status: (data['status'] ?? 'pending').toString(),
      customerName: data['customerName']?.toString(),
      phone: data['phone']?.toString(),
      address: data['address']?.toString(),
      paymentMethod: data['paymentMethod']?.toString(),
      createdAt: created,
    );
  }
}
