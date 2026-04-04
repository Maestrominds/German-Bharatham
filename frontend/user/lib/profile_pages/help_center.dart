import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../services/api_config.dart';
import 'ui_common.dart';

class _FaqItem {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});
}

class HelpCenterPage extends StatefulWidget {
  const HelpCenterPage({super.key});

  @override
  State<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends State<HelpCenterPage> {
  List<_FaqItem> _faqs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFaqs();
  }

  Future<void> _loadFaqs() async {
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/help-center'));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
        if (data is List) {
          final fetched = data
              .whereType<Map<String, dynamic>>()
              .map((e) => _FaqItem(
                    question: (e['question'] ?? '').toString().trim(),
                    answer: (e['answer'] ?? '').toString().trim(),
                  ))
              .where((e) => e.question.isNotEmpty && e.answer.isNotEmpty)
              .toList();

          if (fetched.isNotEmpty) {
            setState(() {
              _faqs = fetched;
            });
          }
        }
      }
    } catch (_) {
      // keep empty on error to avoid stale hardcoded FAQs
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return basePage(
      context: context,
      title: "Help Center",
      child: _loading
          ? const Padding(
              padding: EdgeInsets.only(top: 20),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF4E7F6D)),
              ),
            )
          : Column(
              children: [
                if (_faqs.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: Text(
                      'No help center items available.',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  )
                else
                  ..._faqs.map(
                    (faq) => helpTile(
                      faq.question,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => _HelpAnswerPage(faq: faq),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
    );
  }
}

class _HelpAnswerPage extends StatelessWidget {
  final _FaqItem faq;

  const _HelpAnswerPage({required this.faq});

  @override
  Widget build(BuildContext context) {
    return basePage(
      context: context,
      title: 'Help Center',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              faq.question,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              faq.answer,
              style: const TextStyle(
                fontSize: 16,
                height: 1.6,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
