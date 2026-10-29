import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Hosts the Xendit checkout page returned by the `create-invoice` Edge
/// Function.
///
/// Closing this screen is **not** proof of payment. The caller must re-read
/// the server-owned order status from Supabase when the user taps **Done**.
class XenditWebViewScreen extends StatefulWidget {
  /// Hosted Xendit invoice URL.
  final String invoiceUrl;

  /// Order reference returned alongside the invoice.
  final String externalId;

  /// Human-readable order description (for display only).
  final String productName;

  const XenditWebViewScreen({
    super.key,
    required this.invoiceUrl,
    required this.externalId,
    required this.productName,
  });

  @override
  State<XenditWebViewScreen> createState() => _XenditWebViewScreenState();
}

class _XenditWebViewScreenState extends State<XenditWebViewScreen> {
  WebViewController? _controller;
  bool _isLoading = true;
  String? _loadError;

  /// webview_flutter supports Android, iOS and macOS. On web, Windows and
  /// Linux we open the checkout in the system browser instead.
  bool get _supportsEmbeddedWebView =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  @override
  void initState() {
    super.initState();

    if (_supportsEmbeddedWebView) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0xFF121212))
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (_) {
              if (!mounted) return;
              setState(() {
                _isLoading = true;
                _loadError = null;
              });
            },
            onPageFinished: (_) {
              if (!mounted) return;
              setState(() => _isLoading = false);
            },
            onWebResourceError: (error) {
              if (!mounted) return;
              setState(() {
                _isLoading = false;
                _loadError = error.description;
              });
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.invoiceUrl));
    } else {
      _openInBrowser();
    }
  }

  Future<void> _openInBrowser() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final opened = await launchUrl(
        Uri.parse(widget.invoiceUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (!opened) {
          _loadError = 'The checkout page could not be opened.';
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = '$error';
      });
    }
  }

  void _retry() {
    if (_supportsEmbeddedWebView) {
      _controller?.loadRequest(Uri.parse(widget.invoiceUrl));
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    } else {
      _openInBrowser();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xendit Checkout'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context, widget.externalId),
            icon: const Icon(Icons.check),
            label: const Text('Done'),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!_supportsEmbeddedWebView) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.open_in_browser, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Checkout opened in your browser',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Complete the payment on the Xendit page, then return here '
                'and tap "Done" to verify the order status.',
                textAlign: TextAlign.center,
              ),
              if (_loadError != null) ...[
                const SizedBox(height: 12),
                Text(
                  _loadError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.orange),
                ),
              ],
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _openInBrowser,
                icon: const Icon(Icons.refresh),
                label: const Text('Re-open Xendit checkout'),
              ),
              const SizedBox(height: 12),
              Text(
                'Reference: ${widget.externalId}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    final controller = _controller;
    if (controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        WebViewWidget(controller: controller),
        if (_isLoading) const Center(child: CircularProgressIndicator()),
        if (_loadError != null && !_isLoading)
          ColoredBox(
            color: const Color(0xFF121212),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 12),
                    const Text(
                      'Failed to load the checkout page',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(_loadError!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _retry,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
