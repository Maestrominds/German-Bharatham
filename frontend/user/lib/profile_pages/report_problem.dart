import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/api_config.dart';
import '../user_session.dart';
import 'ui_common.dart';

class ReportProblemPage extends StatefulWidget {
  const ReportProblemPage({super.key});

  @override
  State<ReportProblemPage> createState() => _ReportProblemPageState();
}

class _ReportProblemPageState extends State<ReportProblemPage> {
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    final subject = _subjectController.text.trim();
    final description = _descriptionController.text.trim();

    if (subject.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill subject and problem details')),
      );
      return;
    }

    final token = UserSession.instance.token;
    if (token == null || token.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login again')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final payload = jsonEncode({
        'subject': subject,
        'description': description,
      });

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final endpoints = [
        '${ApiConfig.baseUrl}/api/problem-reports',
      ];

      http.Response? response;
      for (final endpoint in endpoints) {
        try {
          final r = await http.post(
            Uri.parse(endpoint),
            headers: headers,
            body: payload,
          );
          response = r;
          if (r.statusCode == 201 || r.statusCode == 200) {
            break;
          }
        } catch (_) {
          continue;
        }
      }

      if (!mounted) return;

      if (response != null && (response.statusCode == 201 || response.statusCode == 200)) {
        _subjectController.clear();
        _descriptionController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report submitted successfully'),
            backgroundColor: primaryGreen,
          ),
        );
        return;
      }

      String message = 'Failed to submit report';
      try {
        final parsed = jsonDecode(response?.body ?? '');
        if (parsed is Map && parsed['message'] != null) {
          message = parsed['message'].toString();
        }
      } catch (_) {}

      if (message == 'Failed to submit report' && (response?.body ?? '').trim().isNotEmpty) {
        message = response!.body.toString();
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error. Please try again.')),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return basePage(
      context: context,
      title: "Report a Problem",
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: TextField(
              controller: _subjectController,
              decoration: InputDecoration(
                hintText: "Subject",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: TextField(
              controller: _descriptionController,
              minLines: 4,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: "Describe your problem",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: buttonStyle(),
              onPressed: _submitting ? null : _submitReport,
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      "Submit",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

            ),
          ),
        ],
      ),
    );
  }
}
