import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'models/service_model.dart';
import 'saved_service_manager.dart';
import 'service_details.dart';
import 'service_filter_page.dart';
import 'services/api_service.dart';
import 'services/cache_service.dart';

class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  List<Service> allItems = [];
  List<Service> filteredItems = [];
  bool isLoading = true;
  String searchQuery = '';
  String? errorMessage;
  List<Service>? _filterOverrideItems;

  int _selectedTypeIndex = 0;
  List<String> _typeChips = const ['All'];

  static const List<String> _fixedServiceTypes = [
    'Immigration',
    'Legal',
    'Financial',
    'Tax',
    'Consultation',
    'Home Services',
    'Tuition & Coaching',
    'IT Services',
    'Education',
    'Relocation',
    'Translation',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    SavedServiceManager.instance.initialize();
    // Cache-first: Load from cache immediately
    _loadServicesFromCache();
    // Then fetch fresh data in background
    _loadServices();
  }

  /// Load services from cache (instant)
  Future<void> _loadServicesFromCache() async {
    try {
      final cached = await CacheService.get('services_page_1');
      if (cached == null || !mounted) return;

      final items = await ApiService.parseServicesJson(cached);
      if (!mounted) return;

      setState(() {
        allItems = items.where((item) => item.status == 'Active').toList();
        _filterOverrideItems = null;
        _rebuildTypeChips();
        _selectedTypeIndex = 0;
        _applyLocalFilters();
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Services cache load error: $e');
    }
  }

  Future<void> _loadServices() async {
    try {
      if (!mounted) return;
      if (allItems.isEmpty) {
        setState(() {
          isLoading = true;
          errorMessage = null;
        });
      }

      final items = await ApiService.getServicesListings();

      // Cache the response
      await CacheService.set(
        'services_page_1',
        ApiService.servicesToJson(items),
      );

      if (!mounted) return;
      setState(() {
        allItems = items.where((item) => item.status == 'Active').toList();
        _filterOverrideItems = null;
        _rebuildTypeChips();
        _selectedTypeIndex = 0;
        _applyLocalFilters();
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'Unable to load services. Please check your internet or try again.';
        isLoading = false;
      });
    }
  }

  void _rebuildTypeChips() {
    final existing = allItems
        .map((e) => e.serviceType.trim())
        .where((e) => e.isNotEmpty)
        .toSet();

    // Keep a consistent order but only show types that exist.
    final ordered = <String>[];
    for (final t in _fixedServiceTypes) {
      if (existing.contains(t)) ordered.add(t);
    }

    // Append any unknown/custom types.
    final extras = existing.where((t) => !_fixedServiceTypes.contains(t)).toList();
    extras.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    _typeChips = ['All', ...ordered, ...extras];

    // If current selection is now invalid, reset to All.
    if (_selectedTypeIndex < 0 || _selectedTypeIndex >= _typeChips.length) {
      _selectedTypeIndex = 0;
    }
  }

  void _applyLocalFilters() {
    final base = _filterOverrideItems ?? allItems;
    List<Service> result = List.from(base);

    // Chip filter by type
    if (_selectedTypeIndex != 0 && _selectedTypeIndex < _typeChips.length) {
      final selected = _typeChips[_selectedTypeIndex].toLowerCase();
      result = result.where((item) => item.serviceType.toLowerCase().contains(selected)).toList();
    }

    final q = searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((item) {
        return item.title.toLowerCase().contains(q) ||
            item.serviceType.toLowerCase().contains(q) ||
            item.city.toLowerCase().contains(q) ||
            (item.provider ?? '').toLowerCase().contains(q);
      }).toList();
    }

    setState(() {
      filteredItems = result;
    });
  }

  void _filterItems(String query) {
    setState(() {
      searchQuery = query;
    });
    _applyLocalFilters();
  }

  Future<void> _showFilters() async {
    final result = await Navigator.push<List<Service>>(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceFilterPage(allItems: allItems),
      ),
    );

    if (!mounted) return;
    if (result != null) {
      setState(() {
        _filterOverrideItems = result;
      });
      _applyLocalFilters();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Image.asset('assets/images/left-arrow.png', height: 22, width: 22, color: Colors.black),
        ),
        title: const Text("Services", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: _filterItems,
                    decoration: InputDecoration(
                      hintText: 'Search Services',
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Image.asset(
                          'assets/images/search.png',
                          height: 20,
                          width: 20,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _showFilters,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Image.asset(
                      'assets/images/sort.png',
                      height: 22,
                      width: 22,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _typeChips.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final isSelected = _selectedTypeIndex == index;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedTypeIndex = index);
                      _applyLocalFilters();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF4E7F6D)
                            : const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Center(
                        child: Text(
                          _typeChips[index],
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black54,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF4E7F6D)))
                  : (errorMessage != null)
                      ? Center(
                          child: Text(
                            errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : filteredItems.isEmpty
                          ? const Center(
                              child: Text(
                                'No services available',
                                style: TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              itemCount: filteredItems.length,
                              itemBuilder: (context, index) {
                                return ServiceCard(
                                  item: filteredItems[index],
                                  onRefresh: _loadServices,
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class ServiceCard extends StatefulWidget {
  final Service item;
  final VoidCallback onRefresh;

  const ServiceCard({super.key, required this.item, required this.onRefresh});

  @override
  State<ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<ServiceCard> {
  late bool isSaved;
  late final String _displayImage;
  
  @override
  void initState() {
    super.initState();
    isSaved = SavedServiceManager.instance.isSaved(widget.item.id);
    _displayImage = widget.item.images.isNotEmpty
        ? widget.item.images.first
        : (widget.item.image ?? '');
  }
  
  void _toggleSave() async {
    final nowSaved = await SavedServiceManager.instance.toggle(widget.item);
    setState(() => isSaved = nowSaved);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(nowSaved ? 'Saved to bookmarks' : 'Removed from bookmarks'),
        duration: const Duration(seconds: 1),
        backgroundColor: const Color(0xFF4E7F6D),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locationText = widget.item.city.trim().isNotEmpty
        ? widget.item.city
        : (widget.item.address ?? '');

    final displayRating = (widget.item.averageRating > 0)
        ? widget.item.averageRating.toStringAsFixed(1)
        : '4.5';

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ServiceDetailsPage(item: widget.item, onRefresh: widget.onRefresh)),
        );
        setState(() => isSaved = SavedServiceManager.instance.isSaved(widget.item.id));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.grey.shade200,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _buildServiceImage(
                  _displayImage,
                  width: 60,
                  height: 60,
                  placeholderAsset: 'assets/images/service.jpg',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.item.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: _toggleSave,
                        child: Image.asset(
                          'assets/images/bookmark.png',
                          width: 22,
                          height: 22,
                          color: isSaved ? const Color(0xFF4E7F6D) : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/location.png',
                        width: 16,
                        height: 16,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          locationText,
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.item.serviceType,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/star.png',
                        width: 14,
                        height: 14,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        displayRating,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildServiceImage(
  String src, {
  required double width,
  required double height,
  required String placeholderAsset,
}) {
  if (src.trim().isEmpty) {
    return Image.asset(
      placeholderAsset,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
  }

  if (src.startsWith('data:image')) {
    try {
      final Uint8List bytes = base64Decode(src.split(',').last);
      return Image.memory(
        bytes,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset(
          placeholderAsset,
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      );
    } catch (_) {
      return Image.asset(
        placeholderAsset,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      );
    }
  }

  if (src.startsWith('http://') || src.startsWith('https://')) {
    return Image.network(
      src,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Image.asset(
        placeholderAsset,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }

  return Image.asset(
    src,
    width: width,
    height: height,
    fit: BoxFit.cover,
    errorBuilder: (_, __, ___) => Image.asset(
      placeholderAsset,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    ),
  );
}
