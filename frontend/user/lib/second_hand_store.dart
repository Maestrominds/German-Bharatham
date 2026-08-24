import 'package:flutter/material.dart';

class SecondHandStorePage extends StatelessWidget {
  const SecondHandStorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Second Hand Store'),
        backgroundColor: const Color(0xFF4E7F6D),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Second Hand Store Listings (Coming Soon)'),
      ),
    );
  }
}
