import 'package:flutter/material.dart';
import 'models/community_model.dart';

class CommunityFilterPage extends StatefulWidget {
  final List<CommunityPost> allPosts;

  const CommunityFilterPage({super.key, required this.allPosts});

  @override
  State<CommunityFilterPage> createState() => _CommunityFilterPageState();
}

class _CommunityFilterPageState extends State<CommunityFilterPage> {

  final TextEditingController _searchController = TextEditingController();

  // Category selection
  int selectedCategory = 0;

  static const List<String> categoryLabels = [
    "All",
    "Guide",
    "Visa",
    "Housing",
    "Student Life",
    "Jobs"
  ];

  static const List<String> categoryKeys = [
    "",
    "guide",
    "visa",
    "housing",
    "student",
    "jobs"
  ];

  void _applyFilters() {

    List<CommunityPost> result = List.from(widget.allPosts);

    /// 1. Search filter
    final query = _searchController.text.trim().toLowerCase();

    if (query.isNotEmpty) {
      result = result.where((post) {
        return post.title.toLowerCase().contains(query) ||
            post.description.toLowerCase().contains(query) ||
            post.category.toLowerCase().contains(query);
      }).toList();
    }

    /// 2. Category filter
    if (selectedCategory != 0) {
      final key = categoryKeys[selectedCategory];

      result = result.where((post) {
        return post.category.toLowerCase().contains(key);
      }).toList();
    }

    Navigator.pop(context, result);
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      selectedCategory = 0;
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
          "Community Filters",
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
          )
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// SEARCH
            Row(
              children: [
                Image.asset(
                  'assets/images/search.png',
                  height: 16,
                  width: 16,
                  color: const Color(0xFF4F7F6C),
                ),
                const SizedBox(width: 6),
                const Text(
                  "Search",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ],
            ),

            const SizedBox(height: 8),

            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search community posts",
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Image.asset(
                    'assets/images/search.png',
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

            const SizedBox(height: 30),

            /// CATEGORY
            Row(
              children: [
                Image.asset(
                  'assets/images/sort.png',
                  height: 16,
                  width: 16,
                  color: const Color(0xFF4F7F6C),
                ),
                const SizedBox(width: 6),
                const Text(
                  "Category",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Wrap(
              spacing: 10,
              runSpacing: 10,

              children: List.generate(categoryLabels.length, (index) {

                final isSelected = selectedCategory == index;

                return GestureDetector(

                  onTap: () {
                    setState(() {
                      selectedCategory = index;
                    });
                  },

                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 9),

                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF4F7F6C)
                          : const Color(0xFFE5E7EB),

                      borderRadius: BorderRadius.circular(22),
                    ),

                    child: Text(
                      categoryLabels[index],

                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : Colors.black54,

                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }),
            ),

            const Spacer(),

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
            )
          ],
        ),
      ),
    );
  }
}