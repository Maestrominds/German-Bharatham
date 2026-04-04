import 'package:flutter/material.dart';
import 'models/service_model.dart';

class ServiceFilterPage extends StatefulWidget {
  final List<Service> allItems;

  const ServiceFilterPage({super.key, required this.allItems});

  @override
  State<ServiceFilterPage> createState() => _ServiceFilterPageState();
}

class _ServiceFilterPageState extends State<ServiceFilterPage> {
  final TextEditingController _locationController = TextEditingController();

  int selectedServiceType = 0;
  late final List<String> _serviceTypeLabels;
  late final List<String> _serviceTypeKeys;

  static const double _defaultMaxPrice = 5000;
  late final double _maxPrice;
  late RangeValues _priceRange;

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

  static double? _extractFirstEuroAmount(String? raw) {
    if (raw == null) return null;
    final s = raw.trim();
    if (s.isEmpty) return null;
    final cleaned = s.replaceAll(',', '');
    final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(cleaned);
    if (match == null) return null;
    return double.tryParse(match.group(1) ?? '');
  }

  @override
  void initState() {
    super.initState();

    // Service types: use fixed list ordering for consistent UX.
    _serviceTypeLabels = ['All', ..._fixedServiceTypes];
    _serviceTypeKeys = ['', ..._fixedServiceTypes.map((e) => e.toLowerCase())];

    // Price range: compute a sensible max from current data.
    double computedMax = 0;
    for (final item in widget.allItems) {
      final amount = _extractFirstEuroAmount(item.priceRange);
      if (amount != null && amount > computedMax) computedMax = amount;
    }
    _maxPrice = (computedMax > 0) ? computedMax : _defaultMaxPrice;
    _priceRange = RangeValues(0, _maxPrice);
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    List<Service> result = List.from(widget.allItems);

    final locationQuery = _locationController.text.trim().toLowerCase();
    if (locationQuery.isNotEmpty) {
      result = result.where((item) {
        return item.city.toLowerCase().contains(locationQuery) ||
            (item.address ?? '').toLowerCase().contains(locationQuery) ||
            item.title.toLowerCase().contains(locationQuery) ||
            (item.provider ?? '').toLowerCase().contains(locationQuery);
      }).toList();
    }

    if (selectedServiceType != 0) {
      final targetKey = _serviceTypeKeys[selectedServiceType];
      result = result.where((item) {
        return item.serviceType.toLowerCase().contains(targetKey);
      }).toList();
    }

    // Price range filter (keeps items with no/unknown price).
    if (_priceRange.start > 0 || _priceRange.end < _maxPrice) {
      result = result.where((item) {
        final amount = _extractFirstEuroAmount(item.priceRange);
        if (amount == null) return true;
        return amount >= _priceRange.start && amount <= _priceRange.end;
      }).toList();
    }

    Navigator.pop(context, result);
  }

  void _resetFilters() {
    setState(() {
      _locationController.clear();
      selectedServiceType = 0;
      _priceRange = RangeValues(0, _maxPrice);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Filters',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: Image.asset(
            'assets/images/left-arrow.png',
            height: 22,
            width: 22,
            color: Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _resetFilters,
            child: const Text(
              'Reset',
              style: TextStyle(
                color: Color(0xFF4E7F6D),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset(
                  'assets/images/location.png',
                  height: 16,
                  width: 16,
                  color: const Color(0xFF4E7F6D),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Location',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                hintText: 'Enter location or area',
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Image.asset(
                    'assets/images/location.png',
                    height: 18,
                    width: 18,
                    color: const Color(0xFF4E7F6D),
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
            const SizedBox(height: 28),

            /// SERVICE TYPE FILTER
            Row(
              children: [
                Image.asset(
                  'assets/images/handshake.png',
                  height: 16,
                  width: 16,
                  color: const Color(0xFF4E7F6D),
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.miscellaneous_services,
                    size: 16,
                    color: Color(0xFF4E7F6D),
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Service Type',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(_serviceTypeLabels.length, (index) {
                final isSelected = selectedServiceType == index;
                return GestureDetector(
                  onTap: () => setState(() => selectedServiceType = index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF4E7F6D)
                          : const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Text(
                      _serviceTypeLabels[index],
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black54,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 28),

            /// PRICE RANGE FILTER
            Row(
              children: [
                const Icon(Icons.euro, size: 16, color: Color(0xFF4E7F6D)),
                const SizedBox(width: 6),
                Text(
                  'Price Range: €${_priceRange.start.toInt()} - €${_priceRange.end.toInt()}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: const Color(0xFF4E7F6D),
                inactiveTrackColor: const Color(0xFFD1E8DF),
                thumbColor: const Color(0xFF4E7F6D),
                overlayColor: const Color(0xFF4E7F6D).withOpacity(0.15),
                rangeThumbShape: const RoundRangeSliderThumbShape(
                  enabledThumbRadius: 10,
                ),
              ),
              child: RangeSlider(
                values: _priceRange,
                min: 0,
                max: _maxPrice,
                divisions: 20,
                onChanged: (v) => setState(() => _priceRange = v),
              ),
            ),
            const SizedBox(height: 40),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE5E7EB),
                      foregroundColor: Colors.black,
                      elevation: 0,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4E7F6D),
                      elevation: 0,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _applyFilters,
                    child: const Text(
                      'Apply',
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
          ],
        ),
      ),
    );
  }
}
