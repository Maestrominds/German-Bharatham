import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'ui_common.dart';
import '../services/api_config.dart';

class AboutUsPage extends StatefulWidget {
  const AboutUsPage({super.key});

  @override
  State<AboutUsPage> createState() => _AboutUsPageState();
}

class _AboutUsPageState extends State<AboutUsPage> {
  String? _content;
  bool _loading = true;

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
          _content = data['aboutUs'] as String? ?? '';
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
      title: "About Us",
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4E7F6D)))
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final text = _content?.isNotEmpty == true
        ? _content!
        : 'German Bharatham helps students and professionals find jobs, accommodation, food & grocery, services, and community resources in Germany.';

    // Split by double newlines into paragraphs
    final paragraphs = text
        .split(RegExp(r'\n{2,}'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero banner
        Container(
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
              Icon(Icons.flag, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'German Bharatham',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Content cards — one per paragraph
        ...paragraphs.isEmpty
            ? [_infoCard(icon: Icons.info_outline, content: text)]
            : paragraphs.asMap().entries.map((entry) {
                const icons = [
                  Icons.info_outline,
                  Icons.star_border,
                  Icons.handshake_outlined,
                  Icons.people_outline,
                  Icons.public,
                ];
                final icon = icons[entry.key % icons.length];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _infoCard(icon: icon, content: entry.value),
                );
              }),
      ],
    );
  }

  Widget _infoCard({required IconData icon, required String content}) {
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
}
