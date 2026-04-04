import 'dart:convert';
import 'package:flutter/material.dart';
import 'home.dart';
import 'profile.dart';
import 'search.dart';
import 'user_profiles_page.dart';
import 'accommodation.dart';
import 'accommodation_details.dart';
import 'food_details.dart';
import 'guide_details.dart';
import 'job_details.dart';
import 'models/community_model.dart';
import 'models/food_grocery_model.dart';
import 'models/job_model.dart';
import 'models/service_model.dart';
import 'saved_food_manager.dart';
import 'saved_job_manager.dart';
import 'saved_manager.dart';
import 'saved_guides_manager.dart';
import 'saved_service_manager.dart';
import 'service_details.dart';
import 'services/api_config.dart';
import 'user_session.dart';

class SavedPage extends StatefulWidget {
  const SavedPage({super.key});

  @override
  State<SavedPage> createState() => _SavedPageState();
}

class _SavedPageState extends State<SavedPage> {
  int _currentIndex = 3;
  int _selectedCategory = 0;

  Future<_SavedLists> _loadSaved() async {
    final uid = UserSession.instance.userId;
    if (uid != null && uid.trim().isNotEmpty) {
      SavedManager.instance.switchUser(uid);
      await Future.wait([
        SavedFoodManager.instance.switchUser(uid),
        SavedJobManager.instance.switchUser(uid),
        SavedServiceManager.instance.switchUser(uid),
        SavedGuidesManager.instance.switchUser(uid),
      ]);
    }

    await SavedManager.instance.initialize();

    await Future.wait([
      SavedFoodManager.instance.initialize(),
      SavedJobManager.instance.initialize(),
      SavedServiceManager.instance.initialize(),
    ]);

    final guides = await SavedGuidesManager.instance.getSavedItems();

    return _SavedLists(
      accommodations: List.from(SavedManager.instance.savedAccommodations),
      foods: List.from(SavedFoodManager.instance.savedFoodItems),
      jobs: List.from(SavedJobManager.instance.getSavedItems()),
      services: List.from(SavedServiceManager.instance.getSavedItems()),
      guides: List.from(guides),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Saved"),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),

      /// BODY
      body: Column(
        children: [
          /// CATEGORY ROW
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildCategory("All", 0),
                  _buildCategory("Accommodation", 1),
                  _buildCategory("Food", 2),
                  _buildCategory("Jobs", 3),
                  _buildCategory("Services", 4),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          /// SAVED ITEMS LIST
          Expanded(
            child: FutureBuilder<_SavedLists>(
              future: _loadSaved(),
              builder: (context, snapshot) {
              final data = snapshot.data;

              final displayedAccommodations =
                (_selectedCategory == 0 || _selectedCategory == 1)
                  ? (data?.accommodations ?? const <Accommodation>[])
                  : const <Accommodation>[];

              final displayedFoods =
                (_selectedCategory == 0 || _selectedCategory == 2)
                  ? (data?.foods ?? const <FoodGrocery>[])
                  : const <FoodGrocery>[];

              final displayedJobs =
                (_selectedCategory == 0 || _selectedCategory == 3)
                  ? (data?.jobs ?? const <Job>[])
                  : const <Job>[];

              final displayedServices =
                (_selectedCategory == 0 || _selectedCategory == 4)
                  ? (data?.services ?? const <Service>[])
                  : const <Service>[];

              // Guides only show in "All" view.
              final displayedGuides = _selectedCategory == 0
                ? (data?.guides ?? const <CommunityPost>[])
                : const <CommunityPost>[];

              final isEmpty = displayedAccommodations.isEmpty &&
                displayedFoods.isEmpty &&
                displayedJobs.isEmpty &&
                displayedServices.isEmpty &&
                displayedGuides.isEmpty;

                if (isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/bookmark.png',
                          height: 48,
                          width: 48,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No saved items yet",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Tap the bookmark icon on any listing to save it",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final totalCount = displayedAccommodations.length +
                  displayedFoods.length +
                  displayedJobs.length +
                  displayedServices.length +
                  displayedGuides.length;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: totalCount,
                  itemBuilder: (context, index) {
                    var idx = index;

                    if (idx < displayedAccommodations.length) {
                      final item = displayedAccommodations[idx];
                      return _SavedAccommodationCard(
                        item: item,
                        onRemove: () {
                          setState(() {
                            SavedManager.instance.toggle(item);
                          });
                        },
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AccommodationDetailPage(item: item),
                            ),
                          );
                        },
                      );
                    }

                    idx -= displayedAccommodations.length;

                    if (idx < displayedFoods.length) {
                      final item = displayedFoods[idx];
                      return _SavedFoodCard(
                        item: item,
                        onRemove: () async {
                          await SavedFoodManager.instance.toggle(item);
                          if (!context.mounted) return;
                          setState(() {});
                        },
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FoodDetailPage(item: item),
                            ),
                          );
                        },
                      );
                    }

                    idx -= displayedFoods.length;

                    if (idx < displayedJobs.length) {
                      final item = displayedJobs[idx];
                      return _SavedJobCard(
                        item: item,
                        onRemove: () async {
                          await SavedJobManager.instance.toggle(item);
                          if (!context.mounted) return;
                          setState(() {});
                        },
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => JobDetailsPage(item: item),
                            ),
                          );
                        },
                      );
                    }

                    idx -= displayedJobs.length;

                    if (idx < displayedServices.length) {
                      final item = displayedServices[idx];
                      return _SavedServiceCard(
                        item: item,
                        onRemove: () async {
                          await SavedServiceManager.instance.toggle(item);
                          if (!context.mounted) return;
                          setState(() {});
                        },
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ServiceDetailsPage(item: item),
                            ),
                          );
                        },
                      );
                    }

                    idx -= displayedServices.length;

                    final guide = displayedGuides[idx];

                    return _SavedGuideCard(
                      guide: guide,
                      onRemove: () async {
                        await SavedGuidesManager.instance.toggle(guide);
                        if (!context.mounted) return;
                        setState(() {});
                      },
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GuideDetailsPage(guide: guide),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      /// BOTTOM NAVIGATION
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF3A7D6B),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == _currentIndex) return;
          setState(() => _currentIndex = index);
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const SearchPage()),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const UserProfilesPage()),
            );
          } else if (index == 4) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            );
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/images/home.png',
              height: 24,
              color: _currentIndex == 0 ? const Color(0xFF3A7D6B) : Colors.grey,
              errorBuilder: (_, _, _) => Image.asset(
                'assets/images/warning.png',
                height: 24,
                color: _currentIndex == 0 ? const Color(0xFF3A7D6B) : Colors.grey,
              ),
            ),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/images/search.png',
              height: 24,
              color: _currentIndex == 1 ? const Color(0xFF3A7D6B) : Colors.grey,
              errorBuilder: (_, _, _) => Image.asset(
                'assets/images/warning.png',
                height: 24,
                color: _currentIndex == 1 ? const Color(0xFF3A7D6B) : Colors.grey,
              ),
            ),
            label: "Search",
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/images/social.png',
              height: 24,
              color: _currentIndex == 2 ? const Color(0xFF3A7D6B) : Colors.grey,
              errorBuilder: (_, _, _) => Image.asset(
                'assets/images/warning.png',
                height: 24,
                color: _currentIndex == 2 ? const Color(0xFF3A7D6B) : Colors.grey,
              ),
            ),
            label: "Profiles",
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/images/bookmark.png',
              height: 24,
              color: _currentIndex == 3 ? const Color(0xFF3A7D6B) : Colors.grey,
              errorBuilder: (_, _, _) => Image.asset(
                'assets/images/warning.png',
                height: 24,
                color: _currentIndex == 3 ? const Color(0xFF3A7D6B) : Colors.grey,
              ),
            ),
            label: "Saved",
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/images/profile.png',
              height: 24,
              color: _currentIndex == 4 ? const Color(0xFF3A7D6B) : Colors.grey,
              errorBuilder: (_, _, _) => Image.asset(
                'assets/images/warning.png',
                height: 24,
                color: _currentIndex == 4 ? const Color(0xFF3A7D6B) : Colors.grey,
              ),
            ),
            label: "Profile",
          ),
        ],
      ),
    );
  }

  /// CATEGORY BUTTON
  Widget _buildCategory(String title, int index) {
    final bool isSelected = _selectedCategory == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = index;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3A7D6B) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Card for displaying a saved accommodation
class _SavedAccommodationCard extends StatelessWidget {
  final Accommodation item;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  const _SavedAccommodationCard({
    required this.item,
    required this.onRemove,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// IMAGE
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: item.image.startsWith('http')
                  ? Image.network(
                      item.image,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _placeholder(),
                    )
                  : Image.asset(
                      item.image,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _placeholder(),
                    ),
            ),
            const SizedBox(width: 12),

            /// DETAILS
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      /// REMOVE (unsave) button
                      InkWell(
                        onTap: onRemove,
                        child: Image.asset(
                          'assets/images/bookmark.png',
                          width: 18,
                          height: 18,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/location.png',
                        width: 13,
                        height: 13,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.location,
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/star.png',
                        width: 13,
                        height: 13,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        (item.averageRating ?? 0.0).toStringAsFixed(1),
                        style: const TextStyle(fontSize: 12),
                      ),
                      const Spacer(),
                      if (item.price > 0)
                        Text(
                          "€${item.price}/mo",
                          style: const TextStyle(
                            color: Color(0xFF16A34A),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
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

  Widget _placeholder() => Container(
        width: 80,
        height: 80,
        color: const Color(0xFFE8F5E9),
        child: Center(
          child: Image.asset(
            'assets/images/home.png',
            width: 36,
            height: 36,
            color: const Color(0xFF4F7F67),
            errorBuilder: (_, _, _) => const SizedBox(width: 36, height: 36),
          ),
        ),
      );
}

class _SavedLists {
  final List<Accommodation> accommodations;
  final List<FoodGrocery> foods;
  final List<Job> jobs;
  final List<Service> services;
  final List<CommunityPost> guides;

  const _SavedLists({
    required this.accommodations,
    required this.foods,
    required this.jobs,
    required this.services,
    required this.guides,
  });
}

class _SavedThumbnail extends StatelessWidget {
  final String? image;
  final String fallbackAsset;
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const _SavedThumbnail({
    required this.image,
    required this.fallbackAsset,
    required this.width,
    required this.height,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final img = (image ?? '').trim();
    final fallback = Image.asset(fallbackAsset, width: width, height: height, fit: BoxFit.cover);

    Widget child;
    if (img.isEmpty) {
      child = fallback;
    } else if (img.startsWith('data:')) {
      // Base64 encoded image
      try {
        final bytes = base64Decode(img.split(',').last);
        child = Image.memory(
          bytes,
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback,
        );
      } catch (_) {
        child = fallback;
      }
    } else if (img.startsWith('http://') || img.startsWith('https://')) {
      child = Image.network(
        img,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      );
    } else if (img.startsWith('assets/')) {
      child = Image.asset(
        img,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      );
    } else {
      // Relative server path (e.g. /uploads/... or uploads/...)
      final url = ApiConfig.getImageUrl(img);
      child = Image.network(
        url,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      );
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: child,
    );
  }
}

class _SavedFoodCard extends StatelessWidget {
  final FoodGrocery item;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _SavedFoodCard({
    required this.item,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final rating = item.averageRating > 0
        ? item.averageRating.toStringAsFixed(1)
        : (item.rating > 0 ? item.rating.toStringAsFixed(1) : '4.5');
    final location = item.city.trim().isNotEmpty
        ? item.city
        : (item.location.trim().isNotEmpty ? item.location : item.address);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SavedThumbnail(
              image: item.image,
              fallbackAsset: 'assets/images/restaurant.jpg',
              width: 80,
              height: 80,
              borderRadius: BorderRadius.circular(10),
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
                          item.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: onRemove,
                        child: Image.asset(
                          'assets/images/bookmark.png',
                          width: 18,
                          height: 18,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/location.png',
                        width: 13,
                        height: 13,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/star.png',
                        width: 13,
                        height: 13,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(rating, style: const TextStyle(fontSize: 12)),
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

class _SavedJobCard extends StatelessWidget {
  final Job item;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _SavedJobCard({
    required this.item,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final location = [item.city.trim(), (item.state ?? '').trim()]
        .where((e) => e.isNotEmpty)
        .join(', ');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SavedThumbnail(
              image: item.companyLogo,
              fallbackAsset: 'assets/images/google.png',
              width: 80,
              height: 80,
              borderRadius: BorderRadius.circular(10),
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
                          item.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: onRemove,
                        child: Image.asset(
                          'assets/images/bookmark.png',
                          width: 18,
                          height: 18,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (item.company.trim().isNotEmpty)
                    Text(
                      item.company,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/location.png',
                        width: 13,
                        height: 13,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location.isNotEmpty ? location : item.location,
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
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

class _SavedServiceCard extends StatelessWidget {
  final Service item;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _SavedServiceCard({
    required this.item,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final location = item.city.trim().isNotEmpty
        ? item.city
        : (item.address ?? '').trim();

    final displayImage = item.images.isNotEmpty
      ? item.images.first
      : (item.image ?? '');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SavedThumbnail(
              image: displayImage,
              fallbackAsset: 'assets/images/service.jpg',
              width: 80,
              height: 80,
              borderRadius: BorderRadius.circular(10),
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
                          item.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: onRemove,
                        child: Image.asset(
                          'assets/images/bookmark.png',
                          width: 18,
                          height: 18,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if ((item.provider ?? '').trim().isNotEmpty)
                    Text(
                      item.provider!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/location.png',
                        width: 13,
                        height: 13,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.serviceType,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
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

class SavedCard extends StatelessWidget {
  final String title;
  final String location;
  final String rating;
  final String image;
  final String? status;
  final Color? statusColor;

  const SavedCard({
    super.key,
    required this.title,
    required this.location,
    required this.rating,
    required this.image,
    this.status,
    this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              image: DecorationImage(
                image: AssetImage(image),
                fit: BoxFit.cover,
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
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Image.asset(
                      'assets/images/bookmark.png',
                      width: 18,
                      height: 18,
                      color: Colors.grey,
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
                    const SizedBox(width: 4),
                    Text(
                      location,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Image.asset(
                      'assets/images/star.png',
                      width: 14,
                      height: 14,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      rating,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const Spacer(),
                    if (status != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedGuideCard extends StatelessWidget {
  final CommunityPost guide;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  const _SavedGuideCard({
    required this.guide,
    required this.onRemove,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    guide.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
                InkWell(
                  onTap: onRemove,
                  child: Image.asset(
                    'assets/images/bookmark.png',
                    width: 18,
                    height: 18,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              "${guide.author} • ${guide.date}",
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}