import 'package:flutter/material.dart';
import 'models/second_hand_store_model.dart';
import 'services/api_service.dart';
import 'services/cache_service.dart';
import 'widgets/optimized_image.dart';
import 'second_hand_store_details.dart';

class SecondHandStorePage extends StatefulWidget {
  const SecondHandStorePage({super.key});

  @override
  State<SecondHandStorePage> createState() => _SecondHandStorePageState();
}

class _SecondHandStorePageState extends State<SecondHandStorePage> {
  List<SecondHandStoreItem> allItems = [];
  List<SecondHandStoreItem> filteredItems = [];
  bool isLoading = true;
  String searchQuery = '';
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFromCache();
    _fetchItems();
  }

  Future<void> _loadFromCache() async {
    try {
      final cached = await CacheService.get('second_hand_page');
      if (cached == null || !mounted) return;
      final items = await ApiService.parseSecondHandJson(cached);
      if (!mounted) return;
      setState(() {
        allItems = items.where((item) => item.status == 'Active').toList();
        _applyLocalFilters();
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Cache load error: $e');
    }
  }

  Future<void> _fetchItems() async {
    try {
      if (!mounted) return;
      if (allItems.isEmpty) {
        setState(() {
          isLoading = true;
          errorMessage = null;
        });
      }

      final items = await ApiService.getSecondHandStoreListings();
      
      await CacheService.set(
        'second_hand_page',
        ApiService.secondHandToJson(items),
      );

      if (!mounted) return;
      setState(() {
        allItems = items.where((item) => item.status == 'Active').toList();
        _applyLocalFilters();
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'Unable to load items: $e';
        isLoading = false;
      });
    }
  }

  void _applyLocalFilters() {
    List<SecondHandStoreItem> result = List.from(allItems);
    final q = searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((item) {
        return item.title.toLowerCase().contains(q) ||
            item.description.toLowerCase().contains(q);
      }).toList();
    }
    filteredItems = result;
  }

  void _onSearchChanged(String val) {
    setState(() {
      searchQuery = val;
      _applyLocalFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Second Hand Store',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: _buildSearchBar(),
          ),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search items...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading && allItems.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF4E7F6D)));
    }
    if (errorMessage != null && allItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(errorMessage!, style: TextStyle(color: Colors.red.shade400)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchItems,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4E7F6D)),
              child: const Text('Retry'),
            )
          ],
        ),
      );
    }
    if (filteredItems.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _fetchItems,
      color: const Color(0xFF4E7F6D),
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: filteredItems.length,
        itemBuilder: (context, index) {
          return _buildItemCard(filteredItems[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            searchQuery.isEmpty ? 'No items available' : 'No items match your search',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(SecondHandStoreItem item) {
    String? imageUrl = item.images.isNotEmpty ? item.images.first : null;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SecondHandStoreDetailsPage(item: item),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: Container(
                width: double.infinity,
                color: Colors.grey.shade50,
                child: imageUrl != null
                    ? OptimizedImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                      )
                    : Center(
                        child: Icon(Icons.shopping_bag_outlined,
                            size: 40, color: Colors.grey.shade300),
                      ),
              ),
            ),
            // Details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (item.price.isNotEmpty)
                    Text(
                      item.price,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF4E7F6D),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.local_shipping_outlined, size: 12, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.deliveryOption.isNotEmpty ? item.deliveryOption : 'Not specified',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
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
}
