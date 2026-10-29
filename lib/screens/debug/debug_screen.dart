import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/product_service.dart';

/// Debug-only screen for testing cart, auth, and product seeding.
/// Only reachable in debug builds (see home_screen.dart drawer entry).
class DebugScreen extends StatelessWidget {
  const DebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Menu'),
        backgroundColor: const Color(0xFF121212),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFF1E1E1E),
      body: ListView(
        children: [
          const ListTile(
            leading: Icon(Icons.bug_report, color: Color(0xFFE50914)),
            title: Text(
              'Debug Actions',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            subtitle: Text(
              'DEBUG BUILD ONLY — do not ship',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
          const Divider(color: Color(0xFF333333)),

          // ---- Cart actions ----
          ListTile(
            leading: const Icon(Icons.shopping_cart, color: Colors.white70),
            title: const Text(
              'Clear Cart',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Remove all items from the cart',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            onTap: () {
              context.read<CartProvider>().clear();
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Cart cleared')));
              Navigator.pop(context);
            },
          ),

          ListTile(
            leading: const Icon(Icons.print, color: Colors.white70),
            title: const Text(
              'Log Cart to Console',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Prints cart contents to IDE console / DevTools',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            onTap: () {
              final cart = context.read<CartProvider>();
              developer.log('=== DEBUG CART ===');
              for (final entry in cart.items.entries) {
                developer.log(
                  '${entry.value.product.name} x${entry.value.quantity} = ₱${entry.value.lineTotal}',
                  name: 'DebugScreen',
                );
              }
              developer.log(
                'Total: ₱${cart.total} | Items: ${cart.itemCount}',
                name: 'DebugScreen',
              );
              developer.log('==================', name: 'DebugScreen');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cart logged to console')),
              );
              Navigator.pop(context);
            },
          ),

          const Divider(color: Color(0xFF333333)),

          // ---- Product actions ----
          ListTile(
            leading: const Icon(Icons.inventory, color: Colors.white70),
            title: const Text(
              'Re-seed Sample Products',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Wipes Firestore products and re-adds demo items',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              await context.read<ProductService>().seedSampleProducts();
              messenger.showSnackBar(
                const SnackBar(content: Text('Products re-seeded')),
              );
              navigator.pop();
            },
          ),

          const Divider(color: Color(0xFF333333)),

          // ---- Auth actions ----
          ListTile(
            leading: const Icon(Icons.login, color: Colors.white70),
            title: const Text(
              'Login as Test User',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Attempts sign-in with test@example.com',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              await context.read<AuthProvider>().signIn(
                'test@example.com',
                'password123',
              );
              messenger.showSnackBar(
                const SnackBar(content: Text('Test login attempted')),
              );
              navigator.pop();
            },
          ),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.white70),
            title: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              await context.read<AuthProvider>().signOut();
              messenger.showSnackBar(
                const SnackBar(content: Text('Signed out')),
              );
              navigator.pop();
            },
          ),

          const Divider(color: Color(0xFF333333)),

          // ---- App info ----
          ListTile(
            leading: const Icon(Icons.info, color: Colors.white70),
            title: const Text(
              'App Info',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'FIRST GEAR GYM · v1.0.0+1 · Debug Build',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
