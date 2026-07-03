import 'package:flutter/material.dart';

const Color primaryGreen = Color(0xFF4E7F6D);

PreferredSizeWidget appBar(BuildContext context, String title, {bool showLeading = true}) {
  return AppBar(
    title: Text(title),
    centerTitle: true,
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
    elevation: 0,
    automaticallyImplyLeading: showLeading,
    leading: showLeading
        ? IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Image.asset(
              'assets/images/left-arrow.png',
              width: 22,
              height: 22,
            ),
          )
        : null,
  );
}

Widget basePage({
  required BuildContext context,
  required String title,
  required Widget child,
  bool showLeading = true,
}) {
  return Scaffold(
    backgroundColor: const Color(0xFFF7F8FA),
    appBar: appBar(context, title, showLeading: showLeading),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: child,
    ),
  );
}

Widget infoCard(String title, String value) {
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 6,
          offset: const Offset(0, 3),
        )
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

Widget helpTile(String text, {VoidCallback? onTap}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
    ),
    child: ListTile(
      title: Text(text, style: const TextStyle(fontSize: 14)),
      trailing: Image.asset(
        'assets/images/right-arrow.png',
        width: 18,
        height: 18,
        color: Colors.grey,
      ),
      onTap: onTap,
    ),
  );
}

Widget inputField(String hint) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    child: TextField(
      maxLines: hint.contains("Describe") ? 4 : 1,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    ),
  );
}

ButtonStyle buttonStyle() {
  return ElevatedButton.styleFrom(
    backgroundColor: primaryGreen,
    minimumSize: const Size(double.infinity, 48),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  );
}

String getFriendlyErrorMessage(dynamic e) {
  final str = e.toString().toLowerCase();
  if (str.contains('socketexception') || str.contains('connection failed') || str.contains('handshake failed') || str.contains('network_error')) {
    return 'No internet connection. Please check your network connection and try again.';
  }
  if (str.contains('timeoutexception') || str.contains('timeout')) {
    return 'The connection timed out. The server might be waking up or offline. Please try again.';
  }
  if (str.contains('formatexception')) {
    return 'Received an invalid response format from server. Please try again later.';
  }
  String msg = e.toString();
  if (msg.startsWith('Exception: ')) {
    msg = msg.substring('Exception: '.length);
  }
  return msg;
}

void showErrorSnackBar(BuildContext context, dynamic error) {
  final message = getFriendlyErrorMessage(error);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red[850],
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      duration: const Duration(seconds: 4),
    ),
  );
}
