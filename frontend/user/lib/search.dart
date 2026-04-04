import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'accommodation.dart';
import 'accommodation_details.dart';
import 'food_grocery.dart';
import 'home.dart';
import 'jobs.dart';
import 'models/food_grocery_model.dart';
import 'models/job_model.dart';
import 'models/service_model.dart';
import 'profile.dart';
import 'saved.dart';
import 'saved_manager.dart';
import 'services.dart';
import 'services/api_config.dart';
import 'services/api_service.dart';
import 'services/cache_service.dart';
import 'saved_food_manager.dart';
import 'saved_job_manager.dart';
import 'saved_service_manager.dart';
import 'user_profiles_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  int selectedTab = 0;
  int bottomIndex = 1;

  bool isLoading = true;
  String? errorMessage;

  String searchQuery = '';
  Timer? _searchDebounce;

  List<Accommodation> _allAccommodations = [];
  List<Job> _allJobs = [];
  List<FoodGrocery> _allFood = [];
  List<Service> _allServices = [];
  bool _fullDataLoaded = false;
  bool _fullDataLoading = false;

  final tabs = [
    "All",
    "My Accommodations",
    "My Food & Grocery",
    "My Jobs",
    "My Services",
  ];

  String _searchHint() {
    switch (selectedTab) {
      case 1:
        return "Search my accommodations...";
      case 2:
        return "Search my food & grocery...";
      case 3:
        return "Search my jobs...";
      case 4:
        return "Search my services...";
      default:
        return "Search anything...";
    }
  }

  @override
  void initState() {
    super.initState();
    _initSaved();
    _loadQuickThenLazyRefresh();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _initSaved() async {
    await Future.wait([
      SavedJobManager.instance.initialize(),
      SavedFoodManager.instance.initialize(),
      SavedServiceManager.instance.initialize(),
    ]);
  }

  Future<void> _loadQuickThenLazyRefresh() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    await _loadFromCache(limitPerModule: 3);

    if (!mounted) return;
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _loadAll() async {
    await _refreshAll(showLoaderIfEmpty: true);
  }

  Future<void> _loadFromCache({int? limitPerModule}) async {
    bool hasAnyData = false;

    try {
      final cached = await Future.wait<String?>([
        CacheService.get('search_accommodations'),
        CacheService.get('search_jobs'),
        CacheService.get('search_food'),
        CacheService.get('search_services'),
      ]);

      final acc = _parseAccommodations(cached[0], maxItems: limitPerModule);
      final jobs = _parseJobs(cached[1], maxItems: limitPerModule);
      final food = _parseFood(cached[2], maxItems: limitPerModule);
      final services = await _parseServicesFromCache(cached[3], maxItems: limitPerModule);

      hasAnyData =
          acc.isNotEmpty || jobs.isNotEmpty || food.isNotEmpty || services.isNotEmpty;

      if (!mounted) return;
      if (hasAnyData) {
        setState(() {
          _allAccommodations = acc;
          _allJobs = jobs;
          _allFood = food;
          _allServices = services;
          isLoading = false;
          errorMessage = null;
        });
      }
    } catch (_) {}

    if (!mounted) return;
    if (!hasAnyData) {
      setState(() {
        isLoading = true;
      });
    }
  }

  Future<void> _refreshAll({required bool showLoaderIfEmpty}) async {
    if (_fullDataLoading) return;
    _fullDataLoading = true;

    if (showLoaderIfEmpty && mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    Future<List<T>?> safeFetch<T>(Future<List<T>> future) async {
      try {
        return await future;
      } catch (_) {
        return null;
      }
    }

    final results = await Future.wait<dynamic>([
      safeFetch<Accommodation>(_fetchAccommodations()),
      safeFetch<Job>(_fetchJobs()),
      safeFetch<FoodGrocery>(_fetchFood()),
      safeFetch<Service>(_fetchServices()),
    ]);

    if (!mounted) {
      _fullDataLoading = false;
      return;
    }

    final accResult = results[0] as List<Accommodation>?;
    final jobsResult = results[1] as List<Job>?;
    final foodResult = results[2] as List<FoodGrocery>?;
    final servicesResult = results[3] as List<Service>?;

    final anySuccess =
        accResult != null || jobsResult != null || foodResult != null || servicesResult != null;

    setState(() {
      if (accResult != null) _allAccommodations = accResult;
      if (jobsResult != null) _allJobs = jobsResult;
      if (foodResult != null) _allFood = foodResult;
      if (servicesResult != null) _allServices = servicesResult;

      final hasVisibleData = _allAccommodations.isNotEmpty ||
          _allJobs.isNotEmpty ||
          _allFood.isNotEmpty ||
          _allServices.isNotEmpty;

      errorMessage = (!anySuccess && !hasVisibleData) ? 'Failed to load data' : null;
      isLoading = false;
    });

    _fullDataLoaded = anySuccess;
    _fullDataLoading = false;
  }

  void _ensureFullDataLoaded() {
    if (_fullDataLoaded || _fullDataLoading) return;
    unawaited(_refreshAll(showLoaderIfEmpty: false));
  }

  List<dynamic> _parseListBody(String body) {
    final decoded = jsonDecode(body);
    if (decoded is List) return decoded;
    if (decoded is Map<String, dynamic> && decoded['data'] is List) {
      return decoded['data'] as List;
    }
    return const [];
  }

  List<Accommodation> _parseAccommodations(String? raw, {int? maxItems}) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = _parseListBody(raw);
      final items = list
          .whereType<Map<String, dynamic>>()
          .map(Accommodation.fromJson)
          .toList();
      for (final item in items) {
        item.isSaved = SavedManager.instance.isSaved(item.id);
      }
      if (maxItems != null && maxItems > 0 && items.length > maxItems) {
        return items.take(maxItems).toList();
      }
      return items;
    } catch (_) {
      return const [];
    }
  }

  List<Job> _parseJobs(String? raw, {int? maxItems}) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = _parseListBody(raw);
      final items = list
          .whereType<Map<String, dynamic>>()
          .map(Job.fromJson)
          .where((j) => j.status.toLowerCase() == 'active')
          .toList();
      if (maxItems != null && maxItems > 0 && items.length > maxItems) {
        return items.take(maxItems).toList();
      }
      return items;
    } catch (_) {
      return const [];
    }
  }

  List<FoodGrocery> _parseFood(String? raw, {int? maxItems}) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = _parseListBody(raw);
      final items = list
          .whereType<Map<String, dynamic>>()
          .map(FoodGrocery.fromJson)
          .where((f) => f.status.toLowerCase() == 'active')
          .toList();
      if (maxItems != null && maxItems > 0 && items.length > maxItems) {
        return items.take(maxItems).toList();
      }
      return items;
    } catch (_) {
      return const [];
    }
  }

  List<Service> _parseServices(String? raw, {int? maxItems}) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = _parseListBody(raw);
      final items = <Service>[];
      for (final e in list.whereType<Map<String, dynamic>>()) {
        try {
          final parsed = Service.fromJson(e);
          if (parsed.status.toLowerCase() == 'active') {
            items.add(parsed);
          }
        } catch (_) {
          // Skip malformed listing but keep rendering the rest.
        }
      }
      if (maxItems != null && maxItems > 0 && items.length > maxItems) {
        return items.take(maxItems).toList();
      }
      return items;
    } catch (_) {
      return const [];
    }
  }

  Future<List<Service>> _parseServicesFromCache(String? raw, {int? maxItems}) async {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final parsed = await ApiService.parseServicesJson(raw);
      final items = parsed.where((s) => s.status.toLowerCase() == 'active').toList();
      if (maxItems != null && maxItems > 0 && items.length > maxItems) {
        return items.take(maxItems).toList();
      }
      return items;
    } catch (_) {
      // Backward compatibility for older cached payload shapes.
      return _parseServices(raw, maxItems: maxItems);
    }
  }

  Future<List<Accommodation>> _fetchAccommodations() async {
    final response = await http
        .get(Uri.parse(ApiConfig.accommodationEndpoint))
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) return const [];
    await CacheService.set('search_accommodations', response.body);
    return _parseAccommodations(response.body);
  }

  Future<List<Job>> _fetchJobs() async {
    final response = await http
        .get(Uri.parse('${ApiConfig.baseUrl}/api/jobs/user'))
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) return const [];
    await CacheService.set('search_jobs', response.body);
    return _parseJobs(response.body);
  }

  Future<List<FoodGrocery>> _fetchFood() async {
    final response = await http
        .get(Uri.parse(ApiConfig.foodEndpoint))
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) return const [];
    await CacheService.set('search_food', response.body);
    return _parseFood(response.body);
  }

  Future<List<Service>> _fetchServices() async {
    final items = await ApiService.getServicesListings();
    await CacheService.set('search_services', ApiService.servicesToJson(items));
    return items.where((s) => s.status.toLowerCase() == 'active').toList();
  }

  List<Accommodation> get _accommodationsFiltered {
    final q = searchQuery.trim().toLowerCase();
    if (q.isEmpty) return List.from(_allAccommodations);
    return _allAccommodations.where((a) {
      return a.title.toLowerCase().contains(q) ||
          a.location.toLowerCase().contains(q) ||
          a.description.toLowerCase().contains(q) ||
          a.propertyType.toLowerCase().contains(q);
    }).toList();
  }

  List<Job> get _jobsFiltered {
    final q = searchQuery.trim().toLowerCase();
    if (q.isEmpty) return List.from(_allJobs);
    return _allJobs.where((j) {
      return j.title.toLowerCase().contains(q) ||
          j.company.toLowerCase().contains(q) ||
          j.city.toLowerCase().contains(q) ||
          j.jobType.toLowerCase().contains(q);
    }).toList();
  }

  List<FoodGrocery> get _foodFiltered {
    final q = searchQuery.trim().toLowerCase();
    if (q.isEmpty) return List.from(_allFood);
    return _allFood.where((f) {
      return f.title.toLowerCase().contains(q) ||
          f.city.toLowerCase().contains(q) ||
          f.subCategory.toLowerCase().contains(q);
    }).toList();
  }

  List<Service> get _servicesFiltered {
    final q = searchQuery.trim().toLowerCase();
    if (q.isEmpty) return List.from(_allServices);
    return _allServices.where((s) {
      final provider = (s.provider ?? '').toLowerCase();
      return s.title.toLowerCase().contains(q) ||
          s.serviceType.toLowerCase().contains(q) ||
          s.city.toLowerCase().contains(q) ||
          provider.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      },
      child: Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
  title: const Text("Search"),
  centerTitle: true,
  backgroundColor: Colors.white,
  foregroundColor: Colors.black,
  elevation: 0,

  automaticallyImplyLeading: false,
  leading: null,
),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _searchBar(),
            const SizedBox(height: 14),
            _categoryTabs(),
            const SizedBox(height: 12),
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
                            style: const TextStyle(color: Colors.grey),
                          ),
                        )
                      : _resultsBody(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _bottomNav(),
    ),
    );
  }

  /// 🔍 SEARCH BAR
  Widget _searchBar() {
    return TextField(
      onChanged: (value) {
        _searchDebounce?.cancel();
        _searchDebounce = Timer(const Duration(milliseconds: 200), () {
          if (!mounted) return;
          setState(() {
            searchQuery = value;
          });
        });
      },
      decoration: InputDecoration(
        hintText: _searchHint(),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12),
          child: Image.asset('assets/images/search.png', width: 20),
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  /// 🔘 CATEGORY TABS
  Widget _categoryTabs() {
    return SizedBox(
      height: 32,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => setState(() => selectedTab = index),
            child: _chip(tabs[index], selectedTab == index),
          );
        },
      ),
    );
  }

  Widget _chip(String text, bool selected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF4E7F6D) : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: selected ? Colors.white : Colors.grey,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, VoidCallback onViewAll) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          InkWell(
            onTap: onViewAll,
            child: const Text(
              'View all',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultsBody() {
    if (selectedTab != 0) {
      _ensureFullDataLoaded();
    }

    if (selectedTab == 0) {
      return _allResults();
    }

    if (selectedTab == 1) {
      final list = _accommodationsFiltered;
      return list.isEmpty
          ? const Center(child: Text('No accommodations found'))
          : ListView.builder(
              itemCount: list.length,
              itemBuilder: (context, i) {
                final item = list[i];
                return AccommodationCard(
                  accommodation: item,
                  onBookmarkTap: () {
                    setState(() {
                      SavedManager.instance.toggle(item);
                      item.isSaved = SavedManager.instance.isSaved(item.id);
                    });
                  },
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AccommodationDetailPage(item: item),
                      ),
                    );
                  },
                );
              },
            );
    }

    if (selectedTab == 2) {
      final list = _foodFiltered;
      return list.isEmpty
          ? const Center(child: Text('No food & grocery found'))
          : ListView.builder(
              itemCount: list.length,
              itemBuilder: (context, i) {
                return FoodCard(item: list[i], onRefresh: () => _loadAll());
              },
            );
    }

    if (selectedTab == 3) {
      final list = _jobsFiltered;
      return list.isEmpty
          ? const Center(child: Text('No jobs found'))
          : ListView.builder(
              itemCount: list.length,
              itemBuilder: (context, i) {
                return JobCard(item: list[i], onRefresh: () => _loadAll());
              },
            );
    }

    final list = _servicesFiltered;
    return list.isEmpty
        ? const Center(child: Text('No services found'))
        : ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, i) {
              return ServiceCard(item: list[i], onRefresh: () => _loadAll());
            },
          );
  }

  Widget _allResults() {
    final accommodations = _accommodationsFiltered;
    final food = _foodFiltered;
    final jobs = _jobsFiltered;
    final services = _servicesFiltered;

    final nothingFound =
        accommodations.isEmpty && food.isEmpty && jobs.isEmpty && services.isEmpty;
    if (nothingFound) {
      return const Center(child: Text('No results found'));
    }

    return ListView(
      children: [
        if (accommodations.isNotEmpty) ...[
          _sectionHeader('My Accommodations', () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AccommodationPage()));
          }),
          ...accommodations.take(2).map(
                (item) => AccommodationCard(
                  accommodation: item,
                  onBookmarkTap: () {
                    setState(() {
                      SavedManager.instance.toggle(item);
                      item.isSaved = SavedManager.instance.isSaved(item.id);
                    });
                  },
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AccommodationDetailPage(item: item),
                      ),
                    );
                  },
                ),
              ),
          const SizedBox(height: 18),
        ],
        if (jobs.isNotEmpty) ...[
          _sectionHeader('My Jobs', () {
            Navigator.push(
                context, MaterialPageRoute(builder: (_) => const JobsPage()));
          }),
          ...jobs.take(2)
              .map((item) => JobCard(item: item, onRefresh: () => _loadAll())),
          const SizedBox(height: 18),
        ],
        if (food.isNotEmpty) ...[
          _sectionHeader('My Food & Grocery', () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const FoodGroceryPage()));
          }),
          ...food.take(2)
              .map((item) => FoodCard(item: item, onRefresh: () => _loadAll())),
          const SizedBox(height: 18),
        ],
        if (services.isNotEmpty) ...[
          _sectionHeader('My Services', () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ServicesPage()));
          }),
          ...services.take(2)
              .map((item) => ServiceCard(item: item, onRefresh: () => _loadAll())),
        ],
      ],
    );
  }

  /// 🔻 CUSTOM BOTTOM NAV
  Widget _bottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: BottomNavigationBar(
        currentIndex: bottomIndex,
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF4E7F6D),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const HomePage()));
          }
          if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const UserProfilesPage()),
            );
          }
          if (index == 3) {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const SavedPage()));
          }
          if (index == 4) {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const ProfilePage()));
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/images/home.png',
              height: 24,
              color: bottomIndex == 0 ? const Color(0xFF4E7F6D) : Colors.grey,
              errorBuilder: (_, __, ___) => Icon(
                Icons.home,
                size: 24,
                color: bottomIndex == 0 ? const Color(0xFF4E7F6D) : Colors.grey,
              ),
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/images/search.png',
              height: 24,
              color: bottomIndex == 1 ? const Color(0xFF4E7F6D) : Colors.grey,
              errorBuilder: (_, __, ___) => Icon(
                Icons.search,
                size: 24,
                color: bottomIndex == 1 ? const Color(0xFF4E7F6D) : Colors.grey,
              ),
            ),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/images/social.png',
              height: 24,
              color: bottomIndex == 2 ? const Color(0xFF4E7F6D) : Colors.grey,
              errorBuilder: (_, __, ___) => Icon(
                Icons.people,
                size: 24,
                color: bottomIndex == 2 ? const Color(0xFF4E7F6D) : Colors.grey,
              ),
            ),
            label: 'Profiles',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/images/bookmark.png',
              height: 24,
              color: bottomIndex == 3 ? const Color(0xFF4E7F6D) : Colors.grey,
              errorBuilder: (_, __, ___) => Icon(
                Icons.bookmark,
                size: 24,
                color: bottomIndex == 3 ? const Color(0xFF4E7F6D) : Colors.grey,
              ),
            ),
            label: 'Saved',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/images/profile.png',
              height: 24,
              color: bottomIndex == 4 ? const Color(0xFF4E7F6D) : Colors.grey,
              errorBuilder: (_, __, ___) => Icon(
                Icons.person,
                size: 24,
                color: bottomIndex == 4 ? const Color(0xFF4E7F6D) : Colors.grey,
              ),
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
