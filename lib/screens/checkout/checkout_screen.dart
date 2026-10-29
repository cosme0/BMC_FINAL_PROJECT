import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../providers/cart_provider.dart';
import '../../services/payment_service.dart';
import '../../services/product_service.dart';
import '../orders/orders_screen.dart';
import '../xendit_webview_screen.dart';

String _formatPhp(double amount) =>
    '${AppConfig.currencySymbol}${amount.toStringAsFixed(2)}';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _provinceController = TextEditingController();
  final _postalCodeController = TextEditingController();
  bool _placing = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _provinceController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    if (!_formKey.currentState!.validate()) return;
    final cart = context.read<CartProvider>();
    if (cart.items.isEmpty || _placing) return;

    final orderedQuantities = <String, int>{
      for (final item in cart.items.values) item.product.id: item.quantity,
    };

    setState(() => _placing = true);

    final InvoiceResult invoice;
    try {
      invoice = await PaymentService.instance.createInvoice(
        productName: _buildOrderDescription(cart),
        amount: cart.total,
        customerName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        streetAddress: _addressController.text.trim(),
        city: _cityController.text.trim(),
        province: _provinceController.text.trim(),
        postalCode: _postalCodeController.text.trim(),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _placing = false);
      _showError('Payment could not be started: $error');
      return;
    }

    if (!mounted) return;
    setState(() => _placing = false);

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => XenditWebViewScreen(
          invoiceUrl: invoice.invoiceUrl,
          externalId: invoice.externalId,
          productName: _buildOrderDescription(cart),
        ),
      ),
    );

    if (!mounted) return;
    // An order and invoice now exist on the server.
    cart.clear();

    try {
      final status = await PaymentService.instance.waitForFinalStatus(
        invoice.externalId,
      );
      if (!mounted) return;
      if (status == 'PAID') {
        try {
          await ProductService().decrementStockForOrder(
            orderId: invoice.externalId,
            quantities: orderedQuantities,
          );
        } catch (error) {
          if (!mounted) return;
          _showError(
            'Payment succeeded, but stock could not be updated. '
            'Please contact the store.\n$error',
          );
        }
      }
      await _showResult(status, invoice.externalId);
    } catch (error) {
      if (!mounted) return;
      _showError(
        'Order created (${invoice.externalId}), but the payment status could '
        'not be verified. Check My Orders in a moment.\n$error',
      );
    }
  }

  String _buildOrderDescription(CartProvider cart) {
    final items = cart.items.values
        .map((item) => '${item.product.name} x${item.quantity}')
        .join(', ');
    const maxLength = 180;
    if (items.length <= maxLength) return items;
    return '${items.substring(0, maxLength - 3)}...';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }

  Future<void> _showResult(String status, String externalId) async {
    final paid = status == 'PAID';
    final failed = status == 'FAILED' || status == 'EXPIRED';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        icon: Icon(
          paid
              ? Icons.check_circle
              : failed
              ? Icons.cancel
              : Icons.schedule,
          color: paid
              ? Colors.green
              : failed
              ? Colors.red
              : Colors.orange,
          size: 48,
        ),
        title: Text(
          paid
              ? 'Payment verified!'
              : failed
              ? 'Payment not completed'
              : 'Payment pending',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              paid
                  ? 'Supabase confirmed your order as PAID.'
                  : failed
                  ? 'Xendit reported this order as $status.'
                  : 'Xendit has not confirmed the payment yet. If you already '
                        'paid, the webhook may still be processing.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            Text(
              'Ref: $externalId',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OrdersScreen()),
              );
            },
            child: const Text('View orders'),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryForm() {
    return Form(
      key: _formKey,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contact & Delivery Details',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Fill in your details before continuing to payment.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _nameController,
              label: 'Full name',
              icon: Icons.person_outline,
            ),
            _buildTextField(
              controller: _emailController,
              label: 'Email address',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) return 'Enter your email address';
                if (!text.contains('@') ||
                    !text.split('@').last.contains('.')) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),
            _buildTextField(
              controller: _phoneController,
              label: 'Phone number',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            _buildTextField(
              controller: _addressController,
              label: 'House number, street, barangay',
              icon: Icons.home_outlined,
              textCapitalization: TextCapitalization.words,
            ),
            _buildTextField(
              controller: _cityController,
              label: 'City / municipality',
              icon: Icons.location_city_outlined,
              textCapitalization: TextCapitalization.words,
            ),
            _buildTextField(
              controller: _provinceController,
              label: 'Province',
              icon: Icons.map_outlined,
              textCapitalization: TextCapitalization.words,
            ),
            _buildTextField(
              controller: _postalCodeController,
              label: 'Postal code',
              icon: Icons.markunread_mailbox_outlined,
              keyboardType: TextInputType.number,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool isLast = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.white70),
          labelStyle: const TextStyle(color: Colors.white70),
          errorStyle: const TextStyle(color: Color(0xFFFF8A80)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.white24),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE50914)),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFFF8A80)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFFF8A80)),
          ),
        ),
        validator:
            validator ??
            (value) {
              if (value == null || value.trim().isEmpty) {
                return 'This field is required';
              }
              return null;
            },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('CHECKOUT')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Order Summary',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          ...cart.items.values.map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      item.product.imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox(
                        width: 60,
                        height: 60,
                        child: ColoredBox(
                          color: Color(0xFF2A2A2A),
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.white54,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.product.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatPhp(item.product.price),
                          style: const TextStyle(
                            color: Color(0xFFE50914),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Qty: ${item.quantity}  •  Subtotal: '
                          '${_formatPhp(item.lineTotal)}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (cart.items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Your cart is empty',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _formatPhp(cart.total),
                  style: const TextStyle(
                    color: Color(0xFFE50914),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _buildDeliveryForm(),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lock_outline, color: Color(0xFFE50914)),
                    const SizedBox(width: 8),
                    Text(
                      'Secure payment via Xendit',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Tap the button below to open the hosted Xendit checkout. '
                  'Choose GCash, Maya, card, or QR Ph there. When you finish, '
                  'return here and tap "Done" so the app can verify the '
                  'payment with Supabase.',
                  style: TextStyle(color: Colors.white70, height: 1.4),
                ),
                const SizedBox(height: 12),
                const Row(
                  children: [
                    Icon(Icons.verified_user, size: 16, color: Colors.white54),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'The app never marks an order as paid itself - only '
                        'the Xendit webhook can do that.',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE50914),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: (cart.items.isEmpty || _placing) ? null : _pay,
              child: _placing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'PAY ${_formatPhp(cart.total)} WITH XENDIT',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
