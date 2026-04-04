import 'package:flutter/material.dart';
import 'accommodation.dart';

class FilterPage extends StatefulWidget {
  final List<Accommodation> allAccommodations;

  const FilterPage({super.key, required this.allAccommodations});

  @override
  State<FilterPage> createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  final TextEditingController _locationController = TextEditingController();

  double _minRent = 0;
  late double _maxRent;
  late double _selectedMaxRent;

  // Room Type: 0=All,1=Apartment,2=Shared Room,3=WG,4=Studio,5=Temporary Stay
  int selectedRoomType = 0;

  static const List<String> roomTypeLabels = [
    'All',
    'Apartment',
    'Shared Room',
    'Temporary Stay',
  ];

  static const List<String> roomTypeKeys = [
    '',
    'apartment',
    'shared',
    'temporary',
  ];

  @override
  void initState() {
    super.initState();
    _minRent = 0;
    _maxRent = 2000;
    _selectedMaxRent = 2000;
    if (widget.allAccommodations.isNotEmpty) {
      final prices = widget.allAccommodations
          .map((a) => a.price.toDouble())
          .where((p) => p > 0)
          .toList();
      if (prices.isNotEmpty) {
        prices.sort();
        _maxRent = prices.last;
        _selectedMaxRent = _maxRent;
      }
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    List<Accommodation> result = List.from(widget.allAccommodations);

    // 1. Location filter
    final locationQuery = _locationController.text.trim().toLowerCase();
    if (locationQuery.isNotEmpty) {
      result = result.where((acc) {
        return acc.location.toLowerCase().contains(locationQuery) ||
            acc.title.toLowerCase().contains(locationQuery) ||
            acc.description.toLowerCase().contains(locationQuery);
      }).toList();
    }

    // 2. Rent range filter (include items with price 0 only if min is 0)
    result = result.where((acc) {
      if (acc.price <= 0) return _minRent == 0;
      return acc.price >= _minRent && acc.price <= _selectedMaxRent;
    }).toList();

    // 3. Room type filter
    if (selectedRoomType != 0) {
      final targetKey = roomTypeKeys[selectedRoomType];
      result = result.where((acc) {
        return acc.propertyType.toLowerCase().contains(targetKey);
      }).toList();
    }

    Navigator.pop(context, result);
  }

  void _resetFilters() {
    setState(() {
      _locationController.clear();
      _minRent = 0;
      _selectedMaxRent = _maxRent;
      selectedRoomType = 0;
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
          "Filters",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
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
              "Reset",
              style: TextStyle(
                color: Color(0xFF4F7F6C),
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
            /// LOCATION / AREA
            Row(
              children: [
                Image.asset(
                  'assets/images/location.png',
                  height: 16,
                  width: 16,
                  color: const Color(0xFF4F7F6C),
                ),
                const SizedBox(width: 6),
                const Text(
                  "Location / Area",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                hintText: "Enter city, area or neighbourhood",
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Image.asset(
                    'assets/images/location.png',
                    height: 18,
                    width: 18,
                    color: const Color(0xFF4F7F6C),
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

            /// RENT RANGE
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.euro,
                      size: 16,
                      color: Color(0xFF4F7F6C),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      "Rent Range",
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                  ],
                ),
                Text(
                  "€0 – €${_selectedMaxRent.toInt()}",
                  style: const TextStyle(
                    color: Color(0xFF4F7F6C),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            RangeSlider(
              values: RangeValues(_minRent, _selectedMaxRent),
              min: 0,
              max: _maxRent > 0 ? _maxRent : 2000,
              divisions: _maxRent > 0 ? (_maxRent / 100).round().clamp(1, 100) : 20,
              activeColor: const Color(0xFF4F7F6C),
              inactiveColor: const Color(0xFFD1D5DB),
              labels: RangeLabels(
                '€${_minRent.toInt()}',
                '€${_selectedMaxRent.toInt()}',
              ),
              onChanged: (RangeValues values) {
                setState(() {
                  _minRent = values.start;
                  _selectedMaxRent = values.end;
                });
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('€0', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                Text(
                  '€${_maxRent.toInt()}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),

            const SizedBox(height: 28),

            /// ROOM TYPE
            Row(
              children: [
                const Icon(
                  Icons.meeting_room_outlined,
                  size: 16,
                  color: Color(0xFF4F7F6C),
                ),
                const SizedBox(width: 6),
                const Text(
                  "Room Type",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(roomTypeLabels.length, (index) {
                final isSelected = selectedRoomType == index;
                return GestureDetector(
                  onTap: () => setState(() => selectedRoomType = index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF4F7F6C)
                          : const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Text(
                      roomTypeLabels[index],
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

            const SizedBox(height: 40),

            /// BUTTONS
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
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F7F6C),
                      elevation: 0,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _applyFilters,
                    child: const Text(
                      "Apply",
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
