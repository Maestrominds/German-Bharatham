import 'package:flutter/material.dart';
import 'accommodation_details.dart';
import 'filter_page.dart';
import 'saved_manager.dart';
import 'services/api_config.dart';
import 'services/cache_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'widgets/star_rating_widget.dart';

/// =======================
/// DATA MODEL
/// =======================
class Accommodation {
  final String id;
  final String title;
  final String description;
  final String location;
  final String image;
  final double rating;
  final int price;
  final List<String> amenities;
  final String propertyType;
  final double? latitude;
  final double? longitude;
  bool isSaved;

  // MongoDB nested fields
  final int? bedrooms;
  final int? bathrooms;
  final int? sizeSqm;
  final int? totalFloors;
  final int? coldRent;
  final int? warmRent;
  final int? additionalCosts;
  final int? deposit;
  final bool? electricityIncluded;
  final bool? heatingIncluded;
  final bool? internetIncluded;
  final bool? nearUniversity;
  final bool? nearSupermarket;
  final bool? nearHospital;
  final bool? nearPublicTransport;
  final String? contactPhone;
  final double? averageRating;
  final int? totalRatings;

  Accommodation({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.image,
    required this.rating,
    required this.price,
    required this.amenities,
    required this.propertyType,
    this.latitude,
    this.longitude,
    this.isSaved = false,
    this.bedrooms,
    this.bathrooms,
    this.sizeSqm,
    this.totalFloors,
    this.coldRent,
    this.warmRent,
    this.additionalCosts,
    this.deposit,
    this.electricityIncluded,
    this.heatingIncluded,
    this.internetIncluded,
    this.nearUniversity,
    this.nearSupermarket,
    this.nearHospital,
    this.nearPublicTransport,
    this.contactPhone,
    this.averageRating,
    this.totalRatings,
  });

  factory Accommodation.fromJson(Map<String, dynamic> json) {
    // Extract amenities from the amenities object
    List<String> extractedAmenities = [];
    if (json['amenities'] != null) {
      Map<String, dynamic> amenities = json['amenities'];
      amenities.forEach((key, value) {
        if (value == true) {
          // Convert camelCase to readable format
          String formatted = key
              .replaceAllMapped(RegExp(r'([A-Z])'), (Match m) => ' ${m[0]}')
              .trim();
          formatted = formatted[0].toUpperCase() + formatted.substring(1);
          extractedAmenities.add(formatted);
        }
      });
    }

    // Calculate price from rentDetails
    int displayPrice = 0;
    if (json['rentDetails'] != null) {
      displayPrice =
          (json['rentDetails']['warmRent'] ??
                  json['rentDetails']['coldRent'] ??
                  0)
              .toInt();
    }

    // Build location string
    String location = '';
    if (json['city'] != null) {
      location = json['city'].toString();
    }

    // Get property type
    String propertyType = json['propertyType'] ?? 'shared_rooms';
    String formattedPropertyType = propertyType
        .replaceAll('_', ' ')
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');

    final String rawImage =
        (json['media']?['images'] != null &&
            (json['media']['images'] as List).isNotEmpty)
        ? (() {
            final img = json['media']['images'][0];
            if (img is String) return img;
            if (img is Map) {
              return (img['url'] ?? img['uri'] ?? 'assets/images/room.jpg')
                  .toString();
            }
            return 'assets/images/room.jpg';
          })()
        : 'assets/images/room.jpg';

    final String resolvedImageUrl = ApiConfig.getImageUrl(rawImage);
    final String normalizedImage =
        (rawImage.startsWith('http') ||
            rawImage.startsWith('data:image') ||
            rawImage.startsWith('assets/'))
        ? rawImage
        : (resolvedImageUrl.isNotEmpty
              ? resolvedImageUrl
              : 'assets/images/room.jpg');

    return Accommodation(
      id: (json['_id'] ?? '').toString(),
      title: (json['title'] ?? 'Untitled').toString(),
      description: (json['description'] ?? '').toString(),
      location: location.isNotEmpty ? location : 'Location not specified',
      image: normalizedImage,
      rating: 4.5, // Default rating since it's not in schema
      price: displayPrice,
      amenities: extractedAmenities.take(3).toList(),
      propertyType: formattedPropertyType,
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      isSaved: false,
      // Extract MongoDB nested fields
      bedrooms: json['propertyDetails']?['bedrooms'],
      bathrooms: json['propertyDetails']?['bathrooms'],
      sizeSqm: json['propertyDetails']?['sizeSqm'],
      totalFloors: json['propertyDetails']?['totalFloors'],
      coldRent: json['rentDetails']?['coldRent'],
      warmRent: json['rentDetails']?['warmRent'],
      additionalCosts: json['rentDetails']?['additionalCosts'],
      deposit: json['rentDetails']?['deposit'],
      electricityIncluded: json['rentDetails']?['electricityIncluded'],
      heatingIncluded: json['rentDetails']?['heatingIncluded'],
      internetIncluded: json['rentDetails']?['internetIncluded'],
      nearUniversity: json['locationHighlights']?['nearUniversity'],
      nearSupermarket: json['locationHighlights']?['nearSupermarket'],
      nearHospital: json['locationHighlights']?['nearHospital'],
      nearPublicTransport: json['locationHighlights']?['nearPublicTransport'],
      contactPhone: json['contactPhone']?.toString(),
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalRatings: json['totalRatings'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toSavedJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      'image': image,
      'rating': rating,
      'price': price,
      'amenities': amenities,
      'propertyType': propertyType,
      'latitude': latitude,
      'longitude': longitude,
      'isSaved': isSaved,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'sizeSqm': sizeSqm,
      'totalFloors': totalFloors,
      'coldRent': coldRent,
      'warmRent': warmRent,
      'additionalCosts': additionalCosts,
      'deposit': deposit,
      'electricityIncluded': electricityIncluded,
      'heatingIncluded': heatingIncluded,
      'internetIncluded': internetIncluded,
      'nearUniversity': nearUniversity,
      'nearSupermarket': nearSupermarket,
      'nearHospital': nearHospital,
      'nearPublicTransport': nearPublicTransport,
      'contactPhone': contactPhone,
      'averageRating': averageRating,
      'totalRatings': totalRatings,
    };
  }

  factory Accommodation.fromSavedJson(Map<String, dynamic> json) {
    return Accommodation(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      location: (json['location'] ?? '').toString(),
      image: (json['image'] ?? 'assets/images/room.jpg').toString(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      price: (json['price'] as num?)?.toInt() ?? 0,
      amenities: (json['amenities'] is List)
          ? (json['amenities'] as List).map((e) => e.toString()).toList()
          : <String>[],
      propertyType: (json['propertyType'] ?? '').toString(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isSaved: (json['isSaved'] as bool?) ?? true,
      bedrooms: json['bedrooms'] as int?,
      bathrooms: json['bathrooms'] as int?,
      sizeSqm: json['sizeSqm'] as int?,
      totalFloors: json['totalFloors'] as int?,
      coldRent: json['coldRent'] as int?,
      warmRent: json['warmRent'] as int?,
      additionalCosts: json['additionalCosts'] as int?,
      deposit: json['deposit'] as int?,
      electricityIncluded: json['electricityIncluded'] as bool?,
      heatingIncluded: json['heatingIncluded'] as bool?,
      internetIncluded: json['internetIncluded'] as bool?,
      nearUniversity: json['nearUniversity'] as bool?,
      nearSupermarket: json['nearSupermarket'] as bool?,
      nearHospital: json['nearHospital'] as bool?,
      nearPublicTransport: json['nearPublicTransport'] as bool?,
      contactPhone: json['contactPhone']?.toString(),
      averageRating: (json['averageRating'] as num?)?.toDouble(),
      totalRatings: json['totalRatings'] as int?,
    );
  }
}

/// =======================
/// ACCOMMODATION PAGE
/// =======================
class AccommodationPage extends StatefulWidget {
  const AccommodationPage({super.key});

  @override
  State<AccommodationPage> createState() => _AccommodationPageState();
}

class _AccommodationPageState extends State<AccommodationPage> {
  final TextEditingController _searchController = TextEditingController();

  List<Accommodation> accommodations = [];
  // Base set after applying the filter sheet (or full list by default)
  List<Accommodation> _filterBase = [];
  // Final list after search is applied on top of _filterBase
  List<Accommodation> filteredAccommodations = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    SavedManager.instance.initialize().then((_) {
      if (mounted) {
        // Cache-first: Load from cache immediately if available
        _loadFromCache();
        // Then fetch fresh data in background
        fetchAccommodations();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Load accommodations from cache (instant, ~0ms)
  Future<void> _loadFromCache() async {
    try {
      final cached = await CacheService.get('accommodations_page_1');
      if (cached == null || !mounted) return;

      final decoded = json.decode(cached);
      final List<dynamic> data = decoded is Map
          ? (decoded['data'] ?? []) as List
          : (decoded is List ? decoded : []);

      final loaded = data
          .map((j) {
            try {
              return Accommodation.fromJson(j as Map<String, dynamic>);
            } catch (_) {
              return null;
            }
          })
          .where((item) => item != null)
          .cast<Accommodation>()
          .toList();

      if (!mounted) return;
      for (final acc in loaded) {
        acc.isSaved = SavedManager.instance.isSaved(acc.id);
      }

      setState(() {
        accommodations = loaded;
        _filterBase = accommodations;
        filteredAccommodations = _applySearchOnBase(_filterBase, searchQuery);
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Cache load error: $e');
    }
  }

  Future<void> fetchAccommodations() async {
    // Only show loading spinner if data wasn't cached
    if (accommodations.isEmpty) {
      setState(() => isLoading = true);
    }

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.accommodationEndpoint),
        headers: {'x-user-id': 'user123', 'x-user-role': 'user'},
      );

      if (response.statusCode == 200) {
        // Cache the response for next time
        await CacheService.set('accommodations_page_1', response.body);

        final decoded = json.decode(response.body);
        // Support both plain array and wrapped { data: [...] } responses
        final List<dynamic> data = decoded is List
            ? decoded
            : (decoded['data'] ?? []) as List;
        final loaded = data
            .map((j) {
              try {
                return Accommodation.fromJson(j as Map<String, dynamic>);
              } catch (parseErr) {
                debugPrint('Skipping record due to parse error: $parseErr');
                return null;
              }
            })
            .where((item) => item != null)
            .cast<Accommodation>()
            .toList();
        // restore saved state from SavedManager
        for (final acc in loaded) {
          acc.isSaved = SavedManager.instance.isSaved(acc.id);
        }
        setState(() {
          accommodations = loaded;
          _filterBase = accommodations;
          filteredAccommodations = _applySearchOnBase(_filterBase, searchQuery);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Server error ${response.statusCode}: ${response.body}',
              ),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection error: $e'),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  List<Accommodation> _applySearchOnBase(
    List<Accommodation> base,
    String query,
  ) {
    if (query.trim().isEmpty) return base;

    final q = query.toLowerCase();
    // Return only exact matches based on title, location, or description
    return base
        .where(
          (acc) =>
              acc.title.toLowerCase().contains(q) ||
              acc.location.toLowerCase().contains(q) ||
              acc.description.toLowerCase().contains(q),
        )
        .toList();
  }

  void searchAccommodations(String query) {
    setState(() {
      searchQuery = query;
      filteredAccommodations = _applySearchOnBase(_filterBase, searchQuery);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        title: const Text("Accommodation"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Image.asset(
            'assets/images/left-arrow.png',
            height: 20,
            width: 20,
          ),
        ),
      ),
      body: Column(
        children: [
          /// SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: searchAccommodations,
                    decoration: InputDecoration(
                      hintText: "Search Accommodations",
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
                  onTap: () async {
                    final result = await Navigator.push<List<Accommodation>>(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            FilterPage(allAccommodations: accommodations),
                      ),
                    );
                    if (result != null) {
                      setState(() {
                        _filterBase = result;
                        filteredAccommodations = _applySearchOnBase(
                          _filterBase,
                          searchQuery,
                        );
                      });
                    }
                  },
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
                    ),
                  ),
                ),
              ],
            ),
          ),

          /// LIST
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredAccommodations.isEmpty
                ? const Center(
                    child: Text(
                      'No accommodations found',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredAccommodations.length,
                    itemBuilder: (context, index) {
                      final item = filteredAccommodations[index];

                      return AccommodationCard(
                        accommodation: item,
                        onBookmarkTap: () {
                          setState(() {
                            SavedManager.instance.toggle(item);
                          });
                        },
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AccommodationDetailPage(
                                item: item,
                                onRefresh: fetchAccommodations,
                              ),
                            ),
                          );
                          // Refresh after returning from details
                          fetchAccommodations();
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// =======================
/// ACCOMMODATION CARD
/// =======================
class AccommodationCard extends StatelessWidget {
  final Accommodation accommodation;
  final VoidCallback onBookmarkTap;
  final VoidCallback onTap;

  const AccommodationCard({
    super.key,
    required this.accommodation,
    required this.onBookmarkTap,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
              child: _buildListingImage(accommodation.image, 90, 90),
            ),

            const SizedBox(width: 12),

            /// DETAILS
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// TITLE + BOOKMARK
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          accommodation.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: onBookmarkTap,
                        child: Image.asset(
                          'assets/images/bookmark.png',
                          width: 18,
                          height: 18,
                          color: accommodation.isSaved
                              ? Colors.black
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  /// LOCATION
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/location.png',
                        width: 16,
                        height: 16,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          accommodation.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  /// AMENITIES
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: accommodation.amenities.map((amenity) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F3F5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          amenity,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 6),

                  /// RATING + PRICE
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/star.png',
                        width: 14,
                        height: 14,
                        color: const Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        (accommodation.averageRating ?? 0.0).toStringAsFixed(1),
                        style: const TextStyle(fontSize: 12),
                      ),
                      const Spacer(),
                      Text(
                        "€${accommodation.price} / month",
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

  static Widget _placeholderImage() => Container(
    width: 90,
    height: 90,
    color: const Color(0xFFE8F5E9),
    child: const Icon(Icons.home, color: Color(0xFF4F7F67), size: 36),
  );

  /// Handles URL, base64 data-URI and asset images
  static Widget _buildListingImage(String src, double w, double h) {
    if (src.startsWith('data:image')) {
      try {
        final Uint8List bytes = base64Decode(src.split(',').last);
        return Image.memory(
          bytes,
          width: w,
          height: h,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholderImage(),
        );
      } catch (_) {}
    }
    if (src.startsWith('http')) {
      return Image.network(
        src,
        width: w,
        height: h,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholderImage(),
      );
    }
    return Image.asset(
      src,
      width: w,
      height: h,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _placeholderImage(),
    );
  }
}
