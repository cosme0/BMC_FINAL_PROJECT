import 'package:flutter_final_project/models/product.dart';
import 'package:flutter_final_project/providers/cart_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cart adds and totals', () {
    final cart = CartProvider();
    final p = Product(
      id: '1',
      name: 'Test',
      description: 'desc',
      price: 10.0,
      imageUrl: '',
      stock: 5,
      category: 'General',
    );
    cart.add(p, quantity: 2);
    expect(cart.itemCount, 2);
    expect(cart.total, 20.0);
    cart.updateQuantity('1', 1);
    expect(cart.total, 10.0);
    cart.remove('1');
    expect(cart.items, isEmpty);
  });
}
