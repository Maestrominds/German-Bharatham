import 'package:flutter/material.dart';
import 'models/food_grocery_model.dart';

class FoodFilterPage extends StatefulWidget {
  final List<FoodGrocery> allItems;

  const FoodFilterPage({super.key, required this.allItems});

  @override
  State<FoodFilterPage> createState() => _FoodFilterPageState();
}

class _FoodFilterPageState extends State<FoodFilterPage> {
  final TextEditingController _locationController = TextEditingController();

  // Food Type: 0=All, 1=Restaurant, 2=Cafe, 3=Fast Food, 4=Grocery
  int selectedFoodType = 0;

  static const List<String> foodTypeLabels = [
    'All',
    'Restaurant',
    'Cafe',
    'Fast Food',
    'Grocery',
  ];

  static const List<String> foodTypeKeys = [
    '',
    'restaurant',
    'cafe',
    'fast food',
    'grocery',
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    List<FoodGrocery> result = List.from(widget.allItems);

    // 1. Location filter
    final locationQuery = _locationController.text.trim().toLowerCase();
    if (locationQuery.isNotEmpty) {
      result = result.where((item) {
        return item.city.toLowerCase().contains(locationQuery) ||
            item.address.toLowerCase().contains(locationQuery) ||
            item.title.toLowerCase().contains(locationQuery);
      }).toList();
    }

    // 2. Food type filter
    if (selectedFoodType != 0) {
      final targetKey = foodTypeKeys[selectedFoodType];
      result = result.where((item) {
        return item.subCategory.toLowerCase().contains(targetKey);
      }).toList();
    }

    Navigator.pop(context, result);
  }

  void _resetFilters() {
    setState(() {
      _locationController.clear();
      selectedFoodType = 0;
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
            /// LOCATION
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
                  "Location",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                hintText: "Enter location or area",
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

            /// FOOD TYPE
            Row(
              children: [
                Image.asset(
                  'assets/images/grocery-store.png',
                  height: 16,
                  width: 16,
                  color: const Color(0xFF4E7F6D),
                ),
                const SizedBox(width: 6),
                const Text(
                  "Food Type",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(foodTypeLabels.length, (index) {
                final isSelected = selectedFoodType == index;
                return GestureDetector(
                  onTap: () => setState(() => selectedFoodType = index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF4E7F6D)
                          : const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Text(
                      foodTypeLabels[index],
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
                      backgroundColor: const Color(0xFF4E7F6D),
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
