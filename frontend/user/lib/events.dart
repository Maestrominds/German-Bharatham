import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'event_details.dart';
import 'models/event_model.dart';
import 'services/api_config.dart';
import 'services/api_service.dart';
import 'services/cache_service.dart';
import 'widgets/optimized_image.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  static const Color primaryGreen = Color(0xFF4E7F6D);
  static const Color bgColor = Color(0xFFF7F8FA);

  // Data
  List<EventItem> happeningNowEvents = [];
  List<EventItem> upcomingEvents = [];
  List<EventItem> movieEvents = [];
  List<EventItem> classEvents = [];
  List<EventItem> allEvents = [];
  bool isLoading = true;
  String? errorMessage;

  // Filter States
  String selectedWhen = 'all'; // all, today, this_weekend, this_week, this_month
  String selectedCity = 'All';
  String? selectedCategory;
  String? selectedLanguage;
  bool filterFreeOnly = false;
  bool filterFamilyFriendly = false;
  bool filterEnglishSubtitles = false;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  List<String> dynamicCities = ['All', 'Online'];

  final List<Map<String, String>> whenOptions = [
    {'label': 'All Dates', 'value': 'all'},
    {'label': 'Today', 'value': 'today'},
    {'label': 'This Weekend', 'value': 'this_weekend'},
    {'label': 'This Week', 'value': 'this_week'},
    {'label': 'This Month', 'value': 'this_month'},
  ];

  final List<Map<String, String>> categoryOptions = [
    {'label': 'All Categories', 'value': ''},
    {'label': 'Festivals & Celebrations', 'value': 'festivals'},
    {'label': 'Movies & Screenings', 'value': 'movies'},
    {'label': 'Music, Dance & Theatre', 'value': 'performing_arts'},
    {'label': 'Classes & Workshops', 'value': 'classes'},
    {'label': 'Food Events', 'value': 'food'},
    {'label': 'Melas & Markets', 'value': 'markets'},
    {'label': 'Sports & Outdoors', 'value': 'sports'},
    {'label': 'Meetups & Networking', 'value': 'meetups'},
    {'label': 'Religious & Spiritual', 'value': 'religious'},
    {'label': 'Contests & Calls', 'value': 'contests'},
  ];

  final List<String> languageOptions = [
    'All',
    'Tamil',
    'Hindi',
    'Telugu',
    'Malayalam',
    'Kannada',
    'Marathi',
    'Bengali',
    'English',
    'German',
  ];

  @override
  void initState() {
    super.initState();
    _fetchCities();
    _loadFromCache();
    _fetchEvents();
  }

  Future<void> _fetchCities() async {
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/profile-options'));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final citiesList = (decoded['cities'] as List? ?? [])
            .map((c) => c?.toString() ?? '')
            .where((c) => c.isNotEmpty)
            .toList();
        if (mounted && citiesList.isNotEmpty) {
          setState(() {
            dynamicCities = ['All', 'Online', ...citiesList];
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _loadFromCache() async {
    try {
      final cached = await CacheService.get('events_page_cache_v2');
      if (cached == null || !mounted) return;
      final items = await ApiService.parseEventsJson(cached);
      if (!mounted) return;
      _distributeEvents(items);
      setState(() => isLoading = false);
    } catch (_) {}
  }

  Future<void> _fetchEvents() async {
    try {
      setState(() => errorMessage = null);

      final whenParam = selectedWhen == 'all' ? null : selectedWhen;
      final cityParam = selectedCity == 'All' ? null : selectedCity;

      final items = await ApiService.getEventListings(
        search: searchQuery.trim().isNotEmpty ? searchQuery.trim() : null,
        city: cityParam,
        when: whenParam,
        category: (selectedCategory != null && selectedCategory!.isNotEmpty) ? selectedCategory : null,
        language: (selectedLanguage != null && selectedLanguage != 'All') ? selectedLanguage : null,
        free: filterFreeOnly ? true : null,
        familyFriendly: filterFamilyFriendly ? true : null,
        englishSubtitles: filterEnglishSubtitles ? true : null,
      );

      await CacheService.set('events_page_cache_v2', ApiService.eventsToJson(items));

      if (!mounted) return;
      _distributeEvents(items);
      setState(() => isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'Unable to load events';
        isLoading = false;
      });
    }
  }

  void _distributeEvents(List<EventItem> items) {
    allEvents = items;
    final now = DateTime.now();

    List<EventItem> happening = [];
    List<EventItem> upcoming = [];
    List<EventItem> movies = [];
    List<EventItem> courses = [];

    for (final evt in items) {
      final fmt = evt.format.toLowerCase();
      final cat = evt.category.toLowerCase();
      final start = evt.startsAt;
      final end = evt.endsAt ?? evt.startsAt;

      // Movies
      if (cat == 'movies' || fmt == 'screening') {
        movies.push(evt);
      }

      // Classes & Courses
      if (cat == 'classes' || fmt == 'course' || fmt == 'workshop') {
        courses.push(evt);
      }

      // Happening now: start <= now <= end
      if (start != null && end != null && start.isBefore(now) && end.isAfter(now)) {
        happening.push(evt);
      } else if (fmt != 'course') {
        upcoming.push(evt);
      }
    }

    happeningNowEvents = happening;
    upcomingEvents = upcoming;
    movieEvents = movies;
    classEvents = courses;
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Events',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            selectedCategory = null;
                            selectedLanguage = 'All';
                            filterFreeOnly = false;
                            filterFamilyFriendly = false;
                            filterEnglishSubtitles = false;
                          });
                        },
                        child: const Text('Reset', style: TextStyle(color: primaryGreen)),
                      ),
                    ],
                  ),
                  const Divider(),

                  // Category
                  const Text('Category', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categoryOptions.map((cat) {
                      final isSel = selectedCategory == cat['value'];
                      return ChoiceChip(
                        label: Text(cat['label']!),
                        selected: isSel,
                        selectedColor: primaryGreen.withOpacity(0.15),
                        labelStyle: TextStyle(
                          color: isSel ? primaryGreen : Colors.black87,
                          fontWeight: isSel ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onSelected: (val) {
                          setModalState(() => selectedCategory = val ? cat['value'] : null);
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),
                  // Language
                  const Text('Language', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: languageOptions.map((lang) {
                      final isSel = selectedLanguage == lang || (selectedLanguage == null && lang == 'All');
                      return ChoiceChip(
                        label: Text(lang),
                        selected: isSel,
                        selectedColor: primaryGreen.withOpacity(0.15),
                        labelStyle: TextStyle(
                          color: isSel ? primaryGreen : Colors.black87,
                          fontWeight: isSel ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onSelected: (val) {
                          setModalState(() => selectedLanguage = val ? lang : 'All');
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),
                  const Divider(),

                  // Toggles
                  SwitchListTile(
                    title: const Text('Free Events Only', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Show free admission / community contests', style: TextStyle(fontSize: 12)),
                    value: filterFreeOnly,
                    activeColor: primaryGreen,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setModalState(() => filterFreeOnly = val),
                  ),
                  SwitchListTile(
                    title: const Text('Family Friendly', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Suitable for families and kids', style: TextStyle(fontSize: 12)),
                    value: filterFamilyFriendly,
                    activeColor: primaryGreen,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setModalState(() => filterFamilyFriendly = val),
                  ),
                  SwitchListTile(
                    title: const Text('English Subtitles', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Movies screened with English subtitles', style: TextStyle(fontSize: 12)),
                    value: filterEnglishSubtitles,
                    activeColor: primaryGreen,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setModalState(() => filterEnglishSubtitles = val),
                  ),

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() => isLoading = true);
                        _fetchEvents();
                      },
                      child: const Text('Apply Filters', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Image.asset('assets/images/left-arrow.png', height: 20, width: 20, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Events & Screenings',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 17),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: primaryGreen),
            tooltip: 'Filter options',
            onPressed: _openFilterSheet,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: primaryGreen,
        onRefresh: _fetchEvents,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Input
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: (val) {
                      setState(() {
                        searchQuery = val;
                        isLoading = true;
                      });
                      _fetchEvents();
                    },
                    decoration: InputDecoration(
                      hintText: 'Search festivals, movies, classes...',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  searchQuery = '';
                                  isLoading = true;
                                });
                                _fetchEvents();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),

              // Filter Bar: When Pills
              SizedBox(
                height: 38,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: whenOptions.length,
                  itemBuilder: (context, idx) {
                    final item = whenOptions[idx];
                    final isSel = selectedWhen == item['value'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(item['label']!),
                        selected: isSel,
                        selectedColor: primaryGreen,
                        labelStyle: TextStyle(
                          color: isSel ? Colors.white : const Color(0xFF334155),
                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 12,
                        ),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: isSel ? primaryGreen : Colors.grey.shade300),
                        ),
                        onSelected: (val) {
                          setState(() {
                            selectedWhen = item['value']!;
                            isLoading = true;
                          });
                          _fetchEvents();
                        },
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 8),

              // City Filter Pills
              SizedBox(
                height: 36,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: dynamicCities.length,
                  itemBuilder: (context, idx) {
                    final c = dynamicCities[idx];
                    final isSel = selectedCity == c;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        avatar: c == 'Online' ? const Icon(Icons.wifi, size: 14, color: primaryGreen) : null,
                        label: Text(c),
                        selected: isSel,
                        selectedColor: const Color(0xFFE6F4EA),
                        labelStyle: TextStyle(
                          color: isSel ? primaryGreen : Colors.grey.shade700,
                          fontWeight: isSel ? FontWeight.w700 : FontWeight.normal,
                          fontSize: 12,
                        ),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: isSel ? primaryGreen : Colors.grey.shade300),
                        ),
                        onSelected: (val) {
                          setState(() {
                            selectedCity = val ? c : 'All';
                            isLoading = true;
                          });
                          _fetchEvents();
                        },
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              if (isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator(color: primaryGreen)),
                )
              else if (errorMessage != null)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Text(errorMessage!, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _fetchEvents,
                          style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),
                          child: const Text('Try Again', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                )
              else if (allEvents.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.event_busy_rounded, size: 54, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'No Events Found',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Check back soon or try selecting a different date range or city.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                // SECTION 1: HAPPENING NOW (Horizontal Carousel)
                if (happeningNowEvents.isNotEmpty) ...[
                  _buildSectionHeader('🎉 Happening Now', 'Live and ongoing today'),
                  SizedBox(
                    height: 220,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: happeningNowEvents.length,
                      itemBuilder: (context, idx) => _buildHappeningCard(happeningNowEvents[idx]),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // SECTION 2: MOVIES & SCREENINGS
                if (movieEvents.isNotEmpty) ...[
                  _buildSectionHeader('🎬 In Cinemas / Screenings', 'Indian films across Germany'),
                  SizedBox(
                    height: 250,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: movieEvents.length,
                      itemBuilder: (context, idx) => _buildMovieCard(movieEvents[idx]),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // SECTION 3: CLASSES & COURSES
                if (classEvents.isNotEmpty) ...[
                  _buildSectionHeader('📚 Classes & Workshops', 'Music, dance, language & skills'),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: classEvents.length,
                    itemBuilder: (context, idx) => _buildCourseCard(classEvents[idx]),
                  ),
                  const SizedBox(height: 20),
                ],

                // SECTION 4: UPCOMING EVENTS
                if (upcomingEvents.isNotEmpty) ...[
                  _buildSectionHeader('📅 Upcoming Events', 'Festivals, meetups and community days'),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: upcomingEvents.length,
                    itemBuilder: (context, idx) => _buildUpcomingCard(upcomingEvents[idx]),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // Card for Happening Now (Horizontal)
  Widget _buildHappeningCard(EventItem event) {
    final image = event.posterUrl ?? (event.images.isNotEmpty ? event.images.first : '');
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailsPage(event: event))),
      child: Container(
        width: 260,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                height: 120,
                width: double.infinity,
                child: image.isNotEmpty
                    ? OptimizedImage(imageUrl: image, fit: BoxFit.cover)
                    : Container(color: const Color(0xFFE6F4EA), child: const Icon(Icons.event, color: primaryGreen, size: 36)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(6)),
                    child: const Text('Happening Now', style: TextStyle(color: Color(0xFFDC2626), fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 4),
                  Text(event.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(
                    event.city ?? (event.isOnline ? 'Online' : 'Germany'),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Card for Movies & Screenings
  Widget _buildMovieCard(EventItem event) {
    final image = event.posterUrl ?? (event.images.isNotEmpty ? event.images.first : '');
    final cinemas = event.sessions.map((s) => s.label).whereType<String>().toSet().length;
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailsPage(event: event))),
      child: Container(
        width: 170,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: SizedBox(
                height: 140,
                width: double.infinity,
                child: image.isNotEmpty
                    ? OptimizedImage(imageUrl: image, fit: BoxFit.cover)
                    : Container(color: const Color(0xFF0F172A), child: const Icon(Icons.movie, color: Colors.white, size: 36)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 4),
                  if (event.languages.isNotEmpty)
                    Text(
                      event.languages.join(', '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: primaryGreen, fontWeight: FontWeight.w600, fontSize: 11),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    cinemas > 0 ? '$cinemas cinema${cinemas > 1 ? 's' : ''}' : (event.city ?? 'Germany'),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Card for Classes & Courses
  Widget _buildCourseCard(EventItem event) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailsPage(event: event))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 70,
                height: 70,
                child: (event.posterUrl != null && event.posterUrl!.isNotEmpty)
                    ? OptimizedImage(imageUrl: event.posterUrl!, fit: BoxFit.cover)
                    : Container(color: const Color(0xFFE6F4EA), child: const Icon(Icons.school, color: primaryGreen, size: 32)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    event.cardDateLabel ?? (event.ongoing ? 'Ongoing class' : 'Course'),
                    style: const TextStyle(color: primaryGreen, fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (event.level != null && event.level!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
                          child: Text(event.level!.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                        ),
                      if (event.isOnline)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFFE6F4EA), borderRadius: BorderRadius.circular(4)),
                          child: const Text('ONLINE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: primaryGreen)),
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

  // Card for Upcoming Events (Standard)
  Widget _buildUpcomingCard(EventItem event) {
    final image = event.posterUrl ?? (event.images.isNotEmpty ? event.images.first : '');
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailsPage(event: event))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (image.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: OptimizedImage(imageUrl: image, fit: BoxFit.cover),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        event.cardDateLabel ?? 'Upcoming Event',
                        style: const TextStyle(color: primaryGreen, fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      if (event.priceType == 'free')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(6)),
                          child: const Text('FREE', style: TextStyle(color: Color(0xFF166534), fontWeight: FontWeight.w700, fontSize: 11)),
                        )
                      else if (event.priceText != null && event.priceText!.isNotEmpty)
                        Text(event.priceText!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    event.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                  ),
                  if (event.shortDescription != null && event.shortDescription!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      event.shortDescription!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        event.isOnline ? Icons.wifi : Icons.location_on_outlined,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.isOnline
                              ? 'Online Event'
                              : [event.venue, event.city].whereType<String>().where((s) => s.isNotEmpty).join(', '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ),
                      if (event.familyFriendly)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(4)),
                          child: const Text('Family', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFB45309))),
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
