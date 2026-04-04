import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'ui_common.dart';
import '../services/api_config.dart';

class ContactUsPage extends StatefulWidget {
  const ContactUsPage({super.key});

  @override
  State<ContactUsPage> createState() => _ContactUsPageState();
}

class _ContactUsPageState extends State<ContactUsPage> {
  String? _content;
  bool _loading = true;

  Map<String, String> _extractContactFields(String text) {
    final result = <String, String>{};
    final lines = text
        .split(RegExp(r'\n+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    for (final line in lines) {
      final idx = line.indexOf(':');
      if (idx <= 0 || idx >= line.length - 1) continue;
      final key = line.substring(0, idx).trim().toLowerCase();
      final value = line.substring(idx + 1).trim();
      if (value.isEmpty) continue;

      if (key.contains('email')) result['email'] = value;
      if (key.contains('phone') || key.contains('mobile')) result['phone'] = value;
      if (key.contains('address') || key.contains('office') || key.contains('location')) result['address'] = value;
      if (key == 'name' || key.contains('company')) result['name'] = value;
    }

    return result;
  }

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final res = await http.get(Uri.parse(ApiConfig.settingsPublicEndpoint));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        setState(() {
          _content = data['contactInfo'] as String? ?? '';
          _loading = false;
        });
        return;
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return basePage(
      context: context,
      title: "Contact Us",
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4E7F6D)))
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    // If server returned contact info text, show as paragraph cards
    if (_content != null && _content!.isNotEmpty) {
      final fields = _extractContactFields(_content!);

      if (fields.isNotEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _heroBanner(),
            const SizedBox(height: 16),
            if (fields['email'] != null)
              _contactTile(icon: Icons.email_outlined, label: 'Email', value: fields['email']!),
            if (fields['email'] != null) const SizedBox(height: 12),
            if (fields['phone'] != null)
              _contactTile(icon: Icons.phone_outlined, label: 'Phone', value: fields['phone']!),
            if (fields['phone'] != null) const SizedBox(height: 12),
            if (fields['address'] != null)
              _contactTile(
                icon: Icons.location_on_outlined,
                iconWidget: Image.asset(
                  'assets/images/location.png',
                  width: 22,
                  height: 22,
                ),
                label: 'Address',
                value: fields['address']!,
              ),
            if (fields['address'] != null) const SizedBox(height: 12),
            if (fields['name'] != null)
              _contactTile(icon: Icons.badge_outlined, label: 'Name', value: fields['name']!),
          ],
        );
      }

      final paragraphs = _content!
          .split(RegExp(r'\n{2,}'))
          .map((p) => p.trim())
          .where((p) => p.isNotEmpty)
          .toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heroBanner(),
          const SizedBox(height: 16),
          ...paragraphs.isEmpty
              ? [_contentCard(icon: Icons.contact_mail_outlined, content: _content!)]
              : paragraphs.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _contentCard(
                    icon: [Icons.contact_mail_outlined, Icons.phone_outlined, Icons.location_on_outlined][e.key % 3],
                    content: e.value,
                  ),
                )),
        ],
      );
    }

    // Fallback: structured cards
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heroBanner(),
        const SizedBox(height: 16),
        _contactTile(icon: Icons.email_outlined, label: 'Email', value: 'support@germanbharatham.com'),
        const SizedBox(height: 12),
        _contactTile(icon: Icons.phone_outlined, label: 'Phone', value: '+49 123 456 789'),
        const SizedBox(height: 12),
        _contactTile(
          icon: Icons.location_on_outlined,
          iconWidget: Image.asset(
            'assets/images/location.png',
            width: 22,
            height: 22,
          ),
          label: 'Office',
          value: 'Berlin, Germany',
        ),
      ],
    );
  }

  Widget _heroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4E7F6D), Color(0xFF3A7D6B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.contact_support, color: Colors.white, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Get in Touch',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contentCard({required IconData icon, required String content}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF4E7F6D), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              content,
              style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactTile({required IconData icon, Widget? iconWidget, required String label, required String value}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: iconWidget ?? Icon(icon, color: const Color(0xFF4E7F6D), size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
            ],
          ),
        ],
      ),
    );
  }
}
