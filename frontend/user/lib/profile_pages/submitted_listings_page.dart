import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../user_session.dart';
import '../services/api_config.dart';
import 'ui_common.dart';
import 'create_listing_form.dart';

class SubmittedListingsPage extends StatefulWidget {
  const SubmittedListingsPage({super.key});

  @override
  State<SubmittedListingsPage> createState() => _SubmittedListingsPageState();
}

class _SubmittedListingsPageState extends State<SubmittedListingsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;
  String? _error;

  List<dynamic> _accommodations = [];
  List<dynamic> _jobs = [];
  List<dynamic> _services = [];
  List<dynamic> _secondHand = [];
  List<dynamic> _events = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _fetchListings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchListings() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = UserSession.instance.token;
      if (token == null) {
        throw Exception("You must be logged in to view your listings.");
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/user/listings'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _accommodations = data['Accommodation'] ?? [];
          _jobs = data['Jobs'] ?? [];
          _services = data['Services'] ?? [];
          _secondHand = data['Second Hand Store'] ?? [];
          _events = data['Events'] ?? [];
          _loading = false;
        });
      } else {
        throw Exception("Server returned code ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _deleteListing(String category, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Listing"),
        content: const Text("Are you sure you want to delete this listing? This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final token = UserSession.instance.token;
      if (token == null) return;

      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/user/listings/$category/$id'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final json = jsonDecode(response.body);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(json['message'] ?? 'Deleted successfully')),
        );
        _fetchListings(); // Refresh list
      } else {
        throw Exception(json['message'] ?? 'Failed to delete listing');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Widget _statusBadge(String status) {
    Color bg;
    Color fg;
    final displayStatus = status.trim().toUpperCase();

    if (displayStatus == 'ACTIVE' || displayStatus == 'APPROVED') {
      bg = const Color(0xFFE8F5E9);
      fg = const Color(0xFF2E7D32);
    } else if (displayStatus == 'REJECTED') {
      bg = const Color(0xFFFFEBEE);
      fg = const Color(0xFFC62828);
    } else {
      // Pending
      bg = const Color(0xFFFFF8E1);
      fg = const Color(0xFFF57F17);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _listingItem(String category, Map<String, dynamic> item) {
    final id = item['_id'] ?? '';
    final title = item['title'] ?? item['serviceName'] ?? 'Untitled';
    final status = item['status'] ?? 'Pending';
    final dateStr = item['createdAt'] != null 
        ? DateTime.parse(item['createdAt']).toLocal().toString().split(' ')[0]
        : '';

    final statusUpper = status.toString().toUpperCase();
    final bool isPending = statusUpper == 'PENDING';
    final bool isRejected = statusUpper == 'REJECTED';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _statusBadge(status),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              "Submitted on: $dateStr",
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isPending) ...[
                  TextButton.icon(
                    onPressed: () async {
                      final success = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreateListingFormPage(
                            category: category,
                            initialData: item,
                          ),
                        ),
                      );
                      if (success == true) {
                        _fetchListings();
                      }
                    },
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text("Edit"),
                    style: TextButton.styleFrom(foregroundColor: primaryGreen),
                  ),
                  const SizedBox(width: 8),
                ],
                if (isPending || isRejected) ...[
                  TextButton.icon(
                    onPressed: () => _deleteListing(category, id),
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text("Delete"),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ],
                if (statusUpper == 'ACTIVE' || statusUpper == 'APPROVED')
                  const Text(
                    "Approved listings cannot be edited or deleted",
                    style: TextStyle(color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic),
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _listingsList(String category, List<dynamic> items) {
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchListings,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.list_alt, size: 64, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(
                        "No $category listings yet",
                        style: const TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchListings,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = Map<String, dynamic>.from(items[index]);
          return _listingItem(category, item);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        appBar: appBar(context, "Submitted Listings"),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_error!, style: const TextStyle(color: Colors.red)),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _fetchListings,
                            style: buttonStyle(),
                            child: const Text("Retry", style: TextStyle(color: Colors.white)),
                          )
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: [
                      Container(
                        color: Colors.white,
                        child: TabBar(
                          controller: _tabController,
                          isScrollable: true,
                          labelColor: primaryGreen,
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: primaryGreen,
                          tabs: const [
                            Tab(text: "Accommodation"),
                            Tab(text: "Jobs"),
                            Tab(text: "Expat Services"),
                            Tab(text: "Second Hand Store"),
                            Tab(text: "Events"),
                          ],
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _listingsList("Accommodation", _accommodations),
                            _listingsList("Jobs", _jobs),
                            _listingsList("Services", _services),
                            _listingsList("Second Hand Store", _secondHand),
                            _listingsList("Events", _events),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
