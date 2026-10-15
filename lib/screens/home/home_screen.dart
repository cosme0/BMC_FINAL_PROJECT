import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/product_service.dart';
import '../../widgets/product_card.dart';
import '../cart/cart_screen.dart';
import '../orders/orders_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProductService _productService = ProductService();
  String _query = '';
  String _category = 'All';

  @override
  void initState() {
    super.initState();
    _productService.seedSampleProducts().catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'lib/img/logoV2.jpg',
              height: 32,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.local_fire_department,
                  color: Color(0xFFE50914)),
            ),
            const SizedBox(width: 8),
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
                children: [
                  TextSpan(text: 'FIRST '),
                  TextSpan(
                    text: 'GEAR',
                    style: TextStyle(color: Color(0xFFE50914)),
                  ),
                  TextSpan(text: ' GYM'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CartScreen()),
                ),
              ),
              if (cart.itemCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: CircleAvatar(
                    radius: 9,
                    backgroundColor: const Color(0xFFE50914),
                    child: Text(
                      cart.itemCount.toString(),
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF1E1E1E),
        child: ListView(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF121212)),
              accountName: Text(auth.user?.displayName ?? 'User'),
              accountEmail: Text(auth.user?.email ?? ''),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Color(0xFFE50914),
                child: Icon(Icons.person, color: Colors.white),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home, color: Colors.white),
              title: const Text('Home', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long, color: Colors.white),
              title: const Text('My Orders', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const OrdersScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Colors.white),
              title: const Text('Profile', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()));
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                hintText: 'Search products',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
            ),
          ),
          SizedBox(
            height: 44,
            child: StreamBuilder<List<Product>>(
              stream: _productService.streamProducts(),
              builder: (context, snap) {
                final cats = <String>{'All'};
                if (snap.hasData) {
                  for (final p in snap.data!) { cats.add(p.category); }
                }
                return ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  children: cats
                      .map((c) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ChoiceChip(
                              label: Text(c),
                              selected: _category == c,
                              onSelected: (_) => setState(() => _category = c),
                              selectedColor: const Color(0xFFE50914),
                              backgroundColor: const Color(0xFF1E1E1E),
                              labelStyle: TextStyle(
                                color: _category == c
                                    ? Colors.white
                                    : Colors.white70,
                              ),
                            ),
                          ))
                      .toList(),
                );
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: _productService.streamProducts(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: Color(0xFFE50914)));
                }
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}',
                      style: const TextStyle(color: Colors.white)));
                }
                final products = (snap.data ?? [])
                    .where((p) =>
                        (_category == 'All' || p.category == _category) &&
                        (p.name.toLowerCase().contains(_query) ||
                            p.description.toLowerCase().contains(_query)))
                    .toList();
                if (products.isEmpty) {
                  return const Center(
                      child: Text('No products found',
                          style: TextStyle(color: Colors.white70)));
                }
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxis = constraints.maxWidth > 700 ? 3 : 2;
                    return GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxis,
                        childAspectRatio: 0.72,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, i) =>
                          ProductCard(product: products[i]),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
