import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../models/payment_order.dart';
import 'app_bootstrap.dart';

/// Result of creating an invoice through the `create-invoice` Edge Function.
class InvoiceResult {
  final String externalId;
  final String invoiceUrl;
  final String invoiceId;
  final double amount;

  const InvoiceResult({
    required this.externalId,
    required this.invoiceUrl,
    required this.invoiceId,
    required this.amount,
  });
}

/// Payment service for the First Gear Gym checkout.
///
/// All trusted payment logic lives on the server (Supabase Edge Functions).
/// The Flutter client only:
///   1. Requests invoice creation from `create-invoice`.
///   2. Opens the returned Xendit checkout URL in a WebView.
///   3. Re-reads the server-owned order status from Supabase. Closing the
///      checkout page is never treated as proof of payment.
class PaymentService {
  PaymentService._();

  static final PaymentService instance = PaymentService._();

  SupabaseClient get _client {
    final error = AppBootstrap.lastError;
    if (error != null) {
      throw Exception('Supabase is not available: $error');
    }
    return Supabase.instance.client;
  }

  /// Creates a pending order and a Xendit invoice for the given cart summary.
  ///
  /// The Edge Function stores the order with the service-role key and returns
  /// the hosted Xendit checkout URL plus the order's `external_id`.
  Future<InvoiceResult> createInvoice({
    required String productName,
    required double amount,
    required String customerName,
    required String email,
    required String phone,
    required String streetAddress,
    required String city,
    required String province,
    required String postalCode,
  }) async {
    if (!AppConfig.isConfigured) {
      throw Exception('Supabase credentials are not configured.');
    }
    if (productName.trim().isEmpty) {
      throw Exception('An order description is required.');
    }
    if (!amount.isFinite || amount <= 0) {
      throw Exception('The order total must be greater than zero.');
    }

    try {
      final response = await _client.functions.invoke(
        AppConfig.createInvoiceFunction,
        body: <String, dynamic>{
          'product_name': productName.trim(),
          'amount': double.parse(amount.toStringAsFixed(2)),
          'customer': <String, dynamic>{
            'name': customerName.trim(),
            'email': email.trim(),
            'phone': phone.trim(),
            'street_address': streetAddress.trim(),
            'city': city.trim(),
            'province': province.trim(),
            'postal_code': postalCode.trim(),
          },
        },
      );

      final data = _asMap(response.data);
      _throwIfError(data);

      final invoiceUrl = (data['invoice_url'] ?? '').toString();
      final externalId = (data['external_id'] ?? '').toString();

      if (invoiceUrl.isEmpty) {
        throw Exception('Xendit did not return a checkout URL.');
      }
      if (externalId.isEmpty) {
        throw Exception('The server did not return an order reference.');
      }

      return InvoiceResult(
        externalId: externalId,
        invoiceUrl: invoiceUrl,
        invoiceId: (data['invoice_id'] ?? '').toString(),
        amount: (data['amount'] as num? ?? amount).toDouble(),
      );
    } on FunctionException catch (error) {
      throw Exception(_functionErrorMessage(error));
    } catch (error) {
      throw Exception(error.toString().replaceFirst('Exception: ', '').trim());
    }
  }

  /// Reads the server-owned order status for [externalId].
  Future<String> checkOrderStatus(String externalId) async {
    if (externalId.isEmpty) return 'PENDING';

    final record = await _client
        .from('orders')
        .select('status')
        .eq('external_id', externalId)
        .maybeSingle();

    return (record?['status'] ?? 'PENDING').toString().toUpperCase();
  }

  /// Polls Supabase for a short while so a slightly delayed Xendit webhook
  /// still resolves before the user is told the order is pending.
  Future<String> waitForFinalStatus(
    String externalId, {
    int attempts = 5,
    Duration delay = const Duration(seconds: 2),
  }) async {
    var status = await checkOrderStatus(externalId);
    for (var attempt = 1; attempt < attempts; attempt++) {
      if (status == 'PAID' || status == 'FAILED' || status == 'EXPIRED') {
        break;
      }
      await Future<void>.delayed(delay);
      status = await checkOrderStatus(externalId);
    }
    return status;
  }

  /// Order history for the Order History screen.
  Future<List<PaymentOrder>> fetchOrders({int limit = 100}) async {
    final response = await _client
        .from('orders')
        .select('external_id, status, product_name, amount, created_at')
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map((row) => PaymentOrder.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  static Map<String, dynamic> _asMap(Object? data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String && data.isNotEmpty) {
      return <String, dynamic>{'error': data};
    }
    return <String, dynamic>{};
  }

  static void _throwIfError(Map<String, dynamic> data) {
    final message = data['error'] ?? data['message'];
    if (message != null && message.toString().trim().isNotEmpty) {
      throw Exception(message.toString());
    }
  }

  static String _functionErrorMessage(FunctionException error) {
    final details = error.details;
    if (details is Map) {
      final message = details['error'] ?? details['message'];
      if (message != null) return message.toString();
    }
    if (details is String && details.isNotEmpty) return details;
    return 'The payment server answered with HTTP ${error.status}.';
  }
}
