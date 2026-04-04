import 'package:flutter/material.dart';

const Color primaryGreen = Color(0xFF4E7F6D);

PreferredSizeWidget appBar(BuildContext context, String title) {
  return AppBar(
    title: Text(title),
    centerTitle: true,
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
    elevation: 0,
    leading: IconButton(
      onPressed: () {
        Navigator.pop(context);
      },
      icon: Image.asset(
        'assets/images/left-arrow.png',
        width: 22,
        height: 22,
      ),
    ),
  );
}

Widget basePage({
  required BuildContext context,
  required String title,
  required Widget child,
}) {
  return Scaffold(
    backgroundColor: const Color(0xFFF7F8FA),
    appBar: appBar(context, title),
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
