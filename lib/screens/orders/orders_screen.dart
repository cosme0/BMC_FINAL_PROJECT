import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../services/order_service.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userId = auth.user?.uid;
    if (userId == null) {
      return const Scaffold(body: Center(child: Text('Please log in')));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: StreamBuilder<List<OrderModel>>(
        stream: OrderService().streamOrdersForUser(userId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final orders = snap.data ?? [];
          if (orders.isEmpty) {
            return const Center(child: Text('No orders yet'));
          }
          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, i) {
              final o = orders[i];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ExpansionTile(
                  title: Text('Order ${o.id.substring(0, 6)}'),
                  subtitle: Text(
                      '${o.createdAt.toLocal()} • ${o.status} • \$${o.total.toStringAsFixed(2)}'),
                  children: o.items
                      .map((it) => ListTile(
                            title: Text((it['name'] ?? '').toString()),
                            trailing: Text('x${it['quantity']}'),
                          ))
                      .toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
