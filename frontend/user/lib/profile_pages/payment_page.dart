import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../services/api_config.dart';
import '../user_session.dart';
import '../user_profiles_page.dart';

class PaymentPage extends StatefulWidget {
  final String orderId;
  final String keyId;
  final dynamic amount;
  final String currency;
  final String planId;

  const PaymentPage({super.key, required this.orderId, required this.keyId, this.amount, required this.currency, required this.planId});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  late Razorpay _razorpay;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    // Delay to allow UI to render then open checkout
    WidgetsBinding.instance.addPostFrameCallback((_) => _startCheckout());
  }

  @override
  void dispose() {
    try {
      _razorpay.clear();
    } catch (_) {}
    super.dispose();
  }

  Future<void> _startCheckout() async {
    if (_started) return;
    _started = true;

    final options = {
      'key': widget.keyId,
      'order_id': widget.orderId,
      'name': 'German Bharatham',
      'description': widget.planId,
      'prefill': {
        'contact': UserSession.instance.phone ?? '',
        'email': UserSession.instance.email ?? ''
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to open checkout: $e')));
      Navigator.of(context).pop();
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final token = UserSession.instance.token;
    if (token == null) return;

    try {
      final resp = await http.post(
        Uri.parse(ApiConfig.subscriptionVerifyEndpoint),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: jsonEncode({
          "razorpay_payment_id": response.paymentId,
          "razorpay_order_id": response.orderId,
          "razorpay_signature": response.signature,
          "planId": widget.planId
        }),
      );

      if (resp.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Payment verified — subscription activated")));
        // Return success to caller so it can decide where to navigate
        Navigator.of(context).pop(true);
      } else {
        final body = jsonDecode(resp.body);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(body["message"] ?? "Verification failed")));
        Navigator.of(context).pop(false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      Navigator.of(context).pop();
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Payment failed or cancelled")));
    Navigator.of(context).pop();
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("External wallet: ${response.walletName}")));
  }

  @override
  Widget build(BuildContext context) {
    final amountDisplay = widget.amount != null
        ? '₹${(widget.amount / 100).toStringAsFixed(0)}'
        : '';

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo / Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF3ECFCF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6C63FF).withOpacity(0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 28),

                // Title
                const Text(
                  'Secure Payment',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  'German Bharatham — ${widget.planId.toUpperCase()} Plan',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.55),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),

                // Amount
                if (amountDisplay.isNotEmpty)
                  Text(
                    amountDisplay,
                    style: const TextStyle(
                      color: Color(0xFF3ECFCF),
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),

                const SizedBox(height: 36),

                // Loading indicator
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      const Color(0xFF6C63FF).withOpacity(0.9),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  'Opening Razorpay checkout…',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 48),

                // Powered by badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shield_outlined,
                        size: 14, color: Colors.white.withOpacity(0.3)),
                    const SizedBox(width: 6),
                    Text(
                      'Powered by Razorpay  •  256-bit SSL',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
