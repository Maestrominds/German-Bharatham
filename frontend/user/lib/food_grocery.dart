import 'package:flutter/material.dart';
import 'food_details.dart';
import 'food_filter_page.dart';
import 'models/food_grocery_model.dart';
import 'saved_food_manager.dart';
import 'services/api_service.dart';
import 'services/api_config.dart';
import 'services/cache_service.dart';
import 'widgets/star_rating_widget.dart';

class FoodGroceryPage extends StatefulWidget {
  const FoodGroceryPage({super.key});

  @override
  State<FoodGroceryPage> createState() => _FoodGroceryPageState();
}

class _FoodGroceryPageState extends State<FoodGroceryPage> {
  String get baseUrl => ApiConfig.baseUrl;
  List<FoodGrocery> allItems = [];
  List<FoodGrocery> filteredItems = [];
  bool isLoading = true;
  String searchQuery = '';
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    SavedFoodManager.instance.initialize();
    // Cache-first: Load from cache immediately
    _loadFoodItemsFromCache();
    // Then fetch fresh data in background
    _loadFoodItems();
  }

  /// Load food items from cache (instant)
  Future<void> _loadFoodItemsFromCache() async {
    try {
      final cached = await CacheService.get('food_page_1');
      if (cached == null || !mounted) return;

      final items = await ApiService.parseFoodGroceryJson(cached);
      if (!mounted) return;

      setState(() {
        allItems = items.where((item) => item.status == 'Active').toList();
        filteredItems = allItems;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Food cache load error: $e');
    }
  }

  Future<void> _loadFoodItems() async {
    try {
      if (!mounted) return;
      if (allItems.isEmpty) {
        setState(() {
          isLoading = true;
          errorMessage = null;
        });
      }

      final items = await ApiService.getFoodGroceryListings();

      // Cache the response
      await CacheService.set(
        'food_page_1',
        ApiService.foodGroceryToJson(items),
      );

      if (!mounted) return;
      setState(() {
        allItems = items.where((item) => item.status == 'Active').toList();
        filteredItems = allItems;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage =
            'Unable to load food items. Please check your internet or try again.';
        isLoading = false;
      });
    }
  }

  void _filterItems(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredItems = allItems;
      } else {
        filteredItems = allItems.where((item) {
          return item.title.toLowerCase().contains(query.toLowerCase()) ||
              item.city.toLowerCase().contains(query.toLowerCase()) ||
              item.subCategory.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _showFilters() async {
    final result = await Navigator.push<List<FoodGrocery>>(
      context,
      MaterialPageRoute(
        builder: (context) => FoodFilterPage(allItems: allItems),
      ),
    );

    if (!mounted) return;
    if (result != null) {
      setState(() {
        filteredItems = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Image.asset(
            'assets/images/left-arrow.png',
            height: 22,
            width: 22,
            color: Colors.black,
          ),
        ),
        title: const Text("Food & Grocery"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// ðŸ” Search Bar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: _filterItems,
                    decoration: InputDecoration(
                      hintText: "Search Food & grocery",
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

            const SizedBox(height: 16),

            /// ðŸ“‹ List
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF4E7F6D),
                      ),
                    )
                  : (errorMessage != null)
                  ? Center(
                      child: Text(
                        errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : filteredItems.isEmpty
                  ? const Center(
                      child: Text(
                        'No food items found',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        return FoodCard(
                          item: filteredItems[index],
                          onRefresh: _loadFoodItems,
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

class FoodCard extends StatefulWidget {
  final FoodGrocery item;
  final VoidCallback onRefresh;

  const FoodCard({super.key, required this.item, required this.onRefresh});

  @override
  State<FoodCard> createState() => _FoodCardState();
}

class _FoodCardState extends State<FoodCard> {
  late bool isSaved;

  @override
  void initState() {
    super.initState();
    isSaved = SavedFoodManager.instance.isSaved(widget.item.id);
  }

  void _toggleSave() async {
    final nowSaved = await SavedFoodManager.instance.toggle(widget.item);
    if (!mounted) return;
    setState(() {
      isSaved = nowSaved;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          nowSaved ? 'Saved to bookmarks' : 'Removed from bookmarks',
        ),
        duration: const Duration(seconds: 1),
        backgroundColor: const Color(0xFF4E7F6D),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                FoodDetailPage(item: widget.item, onRefresh: widget.onRefresh),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: widget.item.image != null && widget.item.image!.isNotEmpty
                  ? (widget.item.image!.startsWith('http')
                        ? Image.network(
                            widget.item.image!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _placeholderImage(),
                          )
                        : Image.asset(
                            widget.item.image!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _placeholderImage(),
                          ))
                  : _placeholderImage(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.item.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: _toggleSave,
                        child: Image.asset(
                          'assets/images/bookmark.png',
                          width: 18,
                          height: 18,
                          color: isSaved
                              ? const Color(0xFF4E7F6D)
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/location.png',
                        width: 14,
                        height: 14,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${widget.item.city}, ${widget.item.state ?? 'Bavaria'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      StarRatingWidget(
                        rating: widget.item.averageRating,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '${widget.item.averageRating > 0 ? widget.item.averageRating.toStringAsFixed(1) : "4.5"} (${widget.item.totalRatings})',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Image.asset(
                        'assets/images/location.png',
                        width: 12,
                        height: 12,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '1.2km',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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

  Widget _placeholderImage() {
    return Container(
      width: 80,
      height: 80,
      color: const Color(0xFFE8F5E9),
      child: Center(
        child: Image.asset(
          'assets/images/grocery-store.png',
          width: 36,
          height: 36,
          color: const Color(0xFF4E7F6D),
          errorBuilder: (_, _, _) => const SizedBox(width: 36, height: 36),
        ),
      ),
    );
  }
}
