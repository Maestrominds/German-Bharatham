import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_config.dart';
import '../user_session.dart';

class PaymentHistoryPage extends StatefulWidget {
  const PaymentHistoryPage({Key? key}) : super(key: key);

  @override
  State<PaymentHistoryPage> createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _payments = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = UserSession.instance.token;
      if (token == null) {
        setState(() {
          _error = 'Not logged in';
          _loading = false;
        });
        return;
      }
      final res = await http.get(
        Uri.parse(ApiConfig.paymentHistoryEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (res.statusCode == 200) {
        final decoded = res.body.isNotEmpty ? jsonDecode(res.body) : [];
        List<dynamic> data = [];
        if (decoded is List) {
          data = decoded;
        } else if (decoded is Map && decoded['data'] is List) {
          data = decoded['data'];
        } else if (decoded is Map && decoded['payments'] is List) {
          data = decoded['payments'];
        }

        final parsed = data.whereType<Map>().map((e) => Map<String, dynamic>.from(
              e.map((k, v) => MapEntry(k.toString(), v)),
            ));

        setState(() {
          _payments = parsed.toList();
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load payment history';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _payments.isEmpty
                  ? const Center(child: Text('No payment history found.'))
                  : ListView(
                      children: [
                        DataTable(
                          columns: const [
                            DataColumn(label: Text('Date')),
                            DataColumn(label: Text('Plan')),
                            DataColumn(label: Text('Amount')),
                            DataColumn(label: Text('Status')),
                          ],
                          rows: _payments.map((p) {
                            return DataRow(cells: [
                              DataCell(Text(p['date'] ?? '')),
                              DataCell(Text(p['plan'] ?? '')),
                              DataCell(Text(p['amount']?.toString() ?? '')),
                              DataCell(Text(p['status'] ?? '')),
                            ]);
                          }).toList(),
                        ),
                      ],
                    ),
    );
  }
}
