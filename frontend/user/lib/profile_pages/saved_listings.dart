import 'package:flutter/material.dart';

import '../accommodation.dart';
import '../accommodation_details.dart';
import '../food_details.dart';
import '../job_details.dart';
import '../models/food_grocery_model.dart';
import '../models/job_model.dart';
import '../models/service_model.dart';
import '../models/community_model.dart';
import '../saved_food_manager.dart';
import '../saved_guides_manager.dart';
import '../saved_job_manager.dart';
import '../saved_manager.dart';
import '../saved_service_manager.dart';
import '../service_details.dart';
import '../guide_details.dart';
import 'ui_common.dart';

class SavedListingsPage extends StatefulWidget {
  const SavedListingsPage({super.key});

  @override
  State<SavedListingsPage> createState() => _SavedListingsPageState();
}

class _SavedListingsPageState extends State<SavedListingsPage> {
  late final Future<_ProfileSavedLists> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadAllSaved();
  }

  Future<_ProfileSavedLists> _loadAllSaved() async {
    await SavedManager.instance.initialize();
    await SavedFoodManager.instance.initialize();
    await SavedJobManager.instance.initialize();
    await SavedServiceManager.instance.initialize();

    final guides = await SavedGuidesManager.instance.getSavedItems();

    return _ProfileSavedLists(
      accommodations: List.of(SavedManager.instance.savedAccommodations),
      foods: List.of(SavedFoodManager.instance.savedFoodItems),
      jobs: List.of(SavedJobManager.instance.savedJobs),
      services: List.of(SavedServiceManager.instance.savedServices),
      guides: List.of(guides),
    );
  }

  void _refresh() {
    setState(() {
      _future = _loadAllSaved();
    });
  }

  @override
  Widget build(BuildContext context) {
    return basePage(
      context: context,
      title: "Saved Listings",
      child: FutureBuilder<_ProfileSavedLists>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data;
          if (data == null) {
            return const Text('Failed to load saved listings');
          }

          final isEmpty = data.accommodations.isEmpty &&
              data.foods.isEmpty &&
              data.jobs.isEmpty &&
              data.services.isEmpty &&
              data.guides.isEmpty;

          if (isEmpty) {
            return const Text('No saved listings yet');
          }

          return Column(
            children: [
              ...data.accommodations.map(
                (acc) => _SavedListingCard(
                  title: acc.title,
                  subtitle: acc.location,
                  image: acc.image,
                  fallbackAsset: 'assets/images/rooms.jpg',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AccommodationDetailPage(item: acc),
                      ),
                    );
                  },
                  onRemove: () {
                    SavedManager.instance.toggle(acc);
                    _refresh();
                  },
                ),
              ),
              ...data.foods.map(
                (food) => _SavedListingCard(
                  title: food.title,
                  subtitle: food.city.trim().isNotEmpty
                      ? food.city
                      : (food.location.trim().isNotEmpty ? food.location : food.address),
                  image: food.image,
                  fallbackAsset: 'assets/images/restaurant.jpg',
                  trailingLine: _ratingLine(
                    food.averageRating > 0
                        ? food.averageRating.toStringAsFixed(1)
                        : (food.rating > 0 ? food.rating.toStringAsFixed(1) : '4.5'),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => FoodDetailPage(item: food)),
                    );
                  },
                  onRemove: () async {
                    await SavedFoodManager.instance.toggle(food);
                    _refresh();
                  },
                ),
              ),
              ...data.jobs.map(
                (job) => _SavedListingCard(
                  title: job.title,
                  subtitle: [job.city.trim(), (job.state ?? '').trim()]
                      .where((e) => e.isNotEmpty)
                      .join(', '),
                  image: job.companyLogo,
                  fallbackAsset: 'assets/images/google.png',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => JobDetailsPage(item: job)),
                    );
                  },
                  onRemove: () async {
                    await SavedJobManager.instance.toggle(job);
                    _refresh();
                  },
                ),
              ),
              ...data.services.map(
                (service) => _SavedListingCard(
                  title: service.title,
                  subtitle: service.city.trim().isNotEmpty
                      ? service.city
                      : (service.address ?? ''),
                  image: service.images.isNotEmpty ? service.images.first : service.image,
                  fallbackAsset: 'assets/images/service.jpg',
                  trailingLine: Text(
                    service.serviceType,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ServiceDetailsPage(item: service),
                      ),
                    );
                  },
                  onRemove: () async {
                    await SavedServiceManager.instance.toggle(service);
                    _refresh();
                  },
                ),
              ),
              ...data.guides.map(
                (guide) => _SavedListingCard(
                  title: guide.title,
                  subtitle: guide.author,
                  image: null,
                  fallbackAsset: 'assets/images/guide.jpg',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => GuideDetailsPage(guide: guide)),
                    );
                  },
                  onRemove: () async {
                    await SavedGuidesManager.instance.toggle(guide);
                    _refresh();
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileSavedLists {
  final List<Accommodation> accommodations;
  final List<FoodGrocery> foods;
  final List<Job> jobs;
  final List<Service> services;
  final List<CommunityPost> guides;

  const _ProfileSavedLists({
    required this.accommodations,
    required this.foods,
    required this.jobs,
    required this.services,
    required this.guides,
  });
}

Widget _ratingLine(String rating) {
  return Row(
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
  );
}

class _SavedListingCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? image;
  final String fallbackAsset;
  final Widget? trailingLine;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _SavedListingCard({
    required this.title,
    required this.subtitle,
    required this.image,
    required this.fallbackAsset,
    required this.onTap,
    required this.onRemove,
    this.trailingLine,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: _cardDecoration(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _thumbnail(
              image: image,
              fallbackAsset: fallbackAsset,
              width: 64,
              height: 64,
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
                          title,
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
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/location.png',
                        width: 13,
                        height: 13,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          subtitle,
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (trailingLine != null) ...[
                    const SizedBox(height: 6),
                    trailingLine!,
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Use shared `basePage` from `ui_common.dart`.

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 6,
        offset: const Offset(0, 3),
      ),
    ],
  );
}

Widget _thumbnail({
  required String? image,
  required String fallbackAsset,
  required double width,
  required double height,
  required BorderRadius borderRadius,
}) {
  final img = (image ?? '').trim();

  Widget child;
  if (img.isEmpty) {
    child = Image.asset(fallbackAsset, width: width, height: height, fit: BoxFit.cover);
  } else if (img.startsWith('http')) {
    child = Image.network(
      img,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Image.asset(
        fallbackAsset,
        width: width,
        height: height,
        fit: BoxFit.cover,
      ),
    );
  } else if (img.startsWith('assets/')) {
    child = Image.asset(
      img,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Image.asset(
        fallbackAsset,
        width: width,
        height: height,
        fit: BoxFit.cover,
      ),
    );
  } else {
    child = Image.asset(fallbackAsset, width: width, height: height, fit: BoxFit.cover);
  }

  return ClipRRect(borderRadius: borderRadius, child: child);
}
