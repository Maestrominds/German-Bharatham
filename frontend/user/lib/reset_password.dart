import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'services/api_config.dart';

class ResetPasswordPage extends StatefulWidget {
  final String token;
  const ResetPasswordPage({super.key, required this.token});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  static const primaryGreen = Color(0xFF4E7F6D);

  final _newPasswordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _loading = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String? _message;
  bool _isError = false;
  bool _success = false;

  Widget _eyeToggleIcon({required bool obscured}) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            'assets/images/eye.png',
            width: 22,
            height: 22,
            fit: BoxFit.contain,
            color: obscured ? Colors.black45 : primaryGreen,
            colorBlendMode: BlendMode.srcIn,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
          if (obscured)
            IgnorePointer(
              child: CustomPaint(
                size: const Size.square(24),
                painter: _EyeSlashPainter(color: Colors.black54),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    final newPass = _newPasswordController.text.trim();
    final confirm = _confirmController.text.trim();

    if (newPass.isEmpty || confirm.isEmpty) {
      setState(() { _message = 'Please fill in both fields.'; _isError = true; });
      return;
    }
    if (newPass.length < 6) {
      setState(() { _message = 'Password must be at least 6 characters.'; _isError = true; });
      return;
    }
    if (newPass != confirm) {
      setState(() { _message = 'Passwords do not match.'; _isError = true; });
      return;
    }

    setState(() { _loading = true; _message = null; _isError = false; });

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/user/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': widget.token, 'newPassword': newPass}),
      );

      Map<String, dynamic>? data;
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) data = decoded;
      } catch (_) {}

      final ok = response.statusCode >= 200 && response.statusCode < 300;
      final msg = data?['message']?.toString() ??
          (ok ? 'Password reset successfully!' : 'Failed to reset password.');

      setState(() {
        _isError = !ok;
        _message = msg;
        _success = ok;
      });

      if (ok && mounted) {
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      setState(() {
        _isError = true;
        _message = 'Network error. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Image.asset(
            'assets/images/left-arrow.png',
            width: 24,
            height: 24,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(Icons.arrow_back, color: Colors.white),
          ),
        ),
        title: const Text('Reset Password'),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Enter your new password below.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _newPasswordController,
              obscureText: _obscureNew,
              decoration: InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  icon: _eyeToggleIcon(obscured: _obscureNew),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmController,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  icon: _eyeToggleIcon(obscured: _obscureConfirm),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: (_loading || _success) ? null : _resetPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Reset Password', style: TextStyle(color: Colors.white)),
              ),
            ),
            if (_message != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    _success ? Icons.check_circle_outline : Icons.error_outline,
                    color: _isError ? Colors.red : primaryGreen,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _message!,
                      style: TextStyle(color: _isError ? Colors.red : Colors.black87),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EyeSlashPainter extends CustomPainter {
  final Color color;
  const _EyeSlashPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const inset = 4.0;
    canvas.drawLine(
      Offset(inset, size.height - inset),
      Offset(size.width - inset, inset),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _EyeSlashPainter oldDelegate) => oldDelegate.color != color;
}
