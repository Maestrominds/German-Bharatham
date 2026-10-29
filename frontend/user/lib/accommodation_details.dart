import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'widgets/star_rating_widget.dart';
import 'widgets/rating_dialog.dart';
import 'widgets/optimized_image.dart';
import 'services/rating_service.dart';
import 'models/rating_model.dart';
import 'saved_manager.dart';
import 'services/api_config.dart';
import 'widgets/listing_share_modal.dart';

class AccommodationDetailPage extends StatefulWidget {
  final dynamic item;
  final VoidCallback? onRefresh;

  const AccommodationDetailPage({
    super.key,
    required this.item,
    this.onRefresh,
  });

  @override
  State<AccommodationDetailPage> createState() =>
      _AccommodationDetailPageState();
}

class _AccommodationDetailPageState extends State<AccommodationDetailPage> {
  static const Color primaryGreen = Color(0xFF4E7F6D);
  static const Color lightGreen = Color(0xFFE8F5F0);
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);

  late Map<String, dynamic> _data;
  RatingStats? _ratingStats;
  Rating? _userRating;
  bool _isSaved = false;
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();
  Timer? _slideshowTimer;
  final Map<String, Uint8List> _base64Cache = {};

  @override
  void initState() {
    super.initState();
    _normalizeData();
    try {
      _isSaved = SavedManager.instance.isSaved((_data['id'] ?? '').toString());
    } catch (_) {
      _isSaved = false;
    }
    _loadRatingData();
    _startSlideshow();
    _fetchFreshDetails();
  }

  Future<void> _fetchFreshDetails() async {
    final id = _data['id']?.toString() ?? _data['_id']?.toString();
    if (id == null || id.isEmpty) return;
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/accommodation/$id'));
      if (res.statusCode == 200) {
        final fresh = jsonDecode(res.body);
        if (fresh is Map<String, dynamic> && mounted) {
          setState(() {
            final linkVal = fresh['link'] ?? fresh['externalUrl'] ?? fresh['website'];
            if (linkVal != null && linkVal.toString().isNotEmpty) {
              _data['link'] = linkVal.toString();
              _data['externalUrl'] = fresh['externalUrl']?.toString() ?? linkVal.toString();
              _data['website'] = fresh['website']?.toString() ?? linkVal.toString();
            }
          });
        }
      }
    } catch (_) {}
  }

  void _startSlideshow() {
    final imgs = _allImages;
    if (imgs.length <= 1) return;
    _slideshowTimer?.cancel();
    _slideshowTimer = Timer.periodic(const Duration(milliseconds: 4000), (timer) {
      if (_pageController.hasClients) {
        int nextPage = _pageController.page!.toInt() + 1;
        if (nextPage >= imgs.length) {
          nextPage = 0;
        }
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  String _toAbsoluteUrl(String src) {
    if (src.isEmpty) return '';
    if (src.startsWith('data:image')) return src;
    if (src.startsWith('http://') || src.startsWith('https://')) return src;
    if (src.startsWith('assets/')) return src;
    return ApiConfig.getImageUrl(src);
  }

  void _normalizeData() {
    final item = widget.item;
    if (item == null) {
      _data = {};
      return;
    }

    if (item is Map) {
      _data = Map<String, dynamic>.from(item);
    } else {
      try {
        _data = Map<String, dynamic>.from(item.toSavedJson());
      } catch (_) {
        try {
          _data = {
            'id': item.id,
            'title': item.title,
            'description': item.description,
            'location': item.location,
            'image': item.image,
            'images': item.images,
            'rating': item.rating,
            'price': item.price,
            'amenities': item.amenities,
            'propertyType': item.propertyType,
            'latitude': item.latitude,
            'longitude': item.longitude,
            'bedrooms': item.bedrooms,
            'bathrooms': item.bathrooms,
            'sizeSqm': item.sizeSqm,
            'coldRent': item.coldRent,
            'warmRent': item.warmRent,
            'deposit': item.deposit,
            'contactPhone': item.contactPhone,
            'averageRating': item.averageRating,
            'totalRatings': item.totalRatings,
            'link': item.link,
            'website': item.website,
            'externalUrl': item.externalUrl,
          };
        } catch (_) {
          _data = {};
        }
      }
    }

    // Standardize rentDetails
    if (!_data.containsKey('rentDetails') || _data['rentDetails'] == null) {
      _data['rentDetails'] = {
        'coldRent': _data['coldRent'] ?? _data['price'] ?? 0,
        'warmRent': _data['warmRent'] ?? 0,
        'deposit': _data['deposit'] ?? 0,
      };
    }
    // Standardize propertyDetails
    if (!_data.containsKey('propertyDetails') || _data['propertyDetails'] == null) {
      _data['propertyDetails'] = {
        'sizeSqm': _data['sizeSqm'] ?? 0,
        'bedrooms': _data['bedrooms'] ?? 0,
        'bathrooms': _data['bathrooms'] ?? 0,
      };
    }
    // Standardize media
    if (!_data.containsKey('media') || _data['media'] == null) {
      final List<dynamic> imgs = [];
      if (_data['images'] is List && (_data['images'] as List).isNotEmpty) {
        imgs.addAll(_data['images']);
      } else if (_data['image'] != null && _data['image'].toString().isNotEmpty) {
        imgs.add(_data['image']);
      }
      _data['media'] = {'images': imgs};
    }
  }

  @override
  void dispose() {
    _slideshowTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadRatingData() async {
    final idStr = (_data['id'] ?? '').toString();
    if (idStr.isEmpty) return;

    final statsFuture = RatingService.getEntityRatingStats(
      entityId: idStr,
      entityType: 'accommodation',
    );
    final userRatingFuture = RatingService.getUserRating(
      entityId: idStr,
      entityType: 'accommodation',
    );
    final stats = await statsFuture;
    final userRating = await userRatingFuture;
    if (mounted) {
      setState(() {
        _ratingStats = stats;
        _userRating = userRating;
      });
    }
  }

  void _showRatingDialog() {
    final idStr = (_data['id'] ?? '').toString();
    final titleStr = (_data['title'] ?? '').toString();
    showDialog(
      context: context,
      builder: (context) => RatingDialog(
        entityId: idStr,
        entityType: 'accommodation',
        entityName: titleStr,
        initialRating: _userRating?.rating ?? 0,
        onRatingSubmitted: () {
          _loadRatingData();
          if (widget.onRefresh != null) {
            widget.onRefresh!();
          }
        },
      ),
    );
  }

  // ── Helper to safely extract nested dynamic JSON values ─────────────────────
  dynamic _safe(Map? m, String key) => m == null ? null : m[key];

  String _str(dynamic v, [String fallback = '']) {
    if (v == null) return fallback;
    final s = v.toString().trim();
    return s.isEmpty ? fallback : s;
  }

  double _dbl(dynamic v, [double fallback = 0.0]) {
    if (v == null) return fallback;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fallback;
    return fallback;
  }

  int _int(dynamic v, [int fallback = 0]) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  bool _bool(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is int) return v != 0;
    if (v is String) return v.toLowerCase() == 'true';
    return false;
  }

  // ── Extract all images from media JSON or single image field ─────────────────
  List<String> get _allImages {
    try {
      final media = _data['media'];
      if (media is Map && media['images'] is List) {
        final imgs = (media['images'] as List)
            .map((e) => e.toString())
            .where((s) => s.isNotEmpty)
            .toList();
        if (imgs.isNotEmpty) return imgs;
      }
    } catch (_) {}
    try {
      final imgs = _data['images'];
      if (imgs is List && imgs.isNotEmpty) {
        return imgs.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
      }
    } catch (_) {}
    try {
      final img = _data['image']?.toString() ?? '';
      if (img.isNotEmpty) return [img];
    } catch (_) {}
    return [];
  }

  // ── Extract rent details from JSON blob ──────────────────────────────────────
  Map? get _rentDetails {
    try {
      final rd = _data['rentDetails'];
      if (rd is Map) return rd;
    } catch (_) {}
    return null;
  }

  String? get _rentString {
    final rent = _rentDetails;
    final double warm = _dbl(_safe(rent, 'warmRent'));
    final double cold = _dbl(_safe(rent, 'coldRent'));
    if (warm > 0) return '€${warm.toStringAsFixed(0)}/mo';
    if (cold > 0) return '€${cold.toStringAsFixed(0)}/mo';
    if (widget.item.warmRent != null && widget.item.warmRent! > 0) {
      return '€${widget.item.warmRent}/mo';
    }
    if (widget.item.coldRent != null && widget.item.coldRent! > 0) {
      return '€${widget.item.coldRent}/mo';
    }
    if (widget.item.price > 0) return '€${widget.item.price}/mo';
    return null;
  }

  // ── Extract property details from JSON blob ──────────────────────────────────
  Map? get _propDetails {
    try {
      final pd = _data['propertyDetails'];
      if (pd is Map) return pd;
    } catch (_) {}
    return null;
  }

  // ── Extract amenities from JSON blob (bool map) ──────────────────────────────
  List<String> get _amenitiesList {
    try {
      final am = _data['amenities'];
      if (am is Map) {
        const labelMap = {
          'balcony': 'Balcony',
          'terrace': 'Terrace',
          'garden': 'Garden',
          'lift': 'Lift / Elevator',
          'parking': 'Parking',
          'garage': 'Garage',
          'cellar': 'Cellar',
          'washingMachine': 'Washing Machine',
          'dishwasher': 'Dishwasher',
          'kitchen': 'Kitchen',
          'petsAllowed': 'Pets Allowed',
          'smokingAllowed': 'Smoking Allowed',
          'anmeldungPossible': 'Anmeldung Possible',
          'studentFriendly': 'Student Friendly',
          'wheelchairAccessible': 'Wheelchair Accessible',
        };
        return am.entries
            .where((e) => _bool(e.value))
            .map((e) => labelMap[e.key] ?? e.key.toString())
            .toList();
      }
      if (am is List) {
        return am.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
      }
    } catch (_) {}
    return [];
  }

  Widget _buildImageWidget(String src, {double? height}) {
    final h = height ?? 280.0;
    if (src.isEmpty) return _placeholder(h);
    final absoluteSrc = _toAbsoluteUrl(src);
    if (absoluteSrc.startsWith('data:image')) {
      try {
        Uint8List? bytes = _base64Cache[absoluteSrc];
        if (bytes == null) {
          bytes = base64Decode(absoluteSrc.split(',').last);
          _base64Cache[absoluteSrc] = bytes;
        }
        return Image.memory(
          bytes,
          width: double.infinity,
          height: h,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => _placeholder(h),
        );
      } catch (_) {
        return _placeholder(h);
      }
    }
    if (absoluteSrc.startsWith('http')) {
      return OptimizedImage(
        imageUrl: absoluteSrc,
        width: double.infinity,
        height: h,
        fit: BoxFit.cover,
        errorWidget: _placeholder(h),
        placeholder: _placeholder(h),
      );
    }
    return _placeholder(h);
  }

  Widget _placeholder(double h) => Container(
        width: double.infinity,
        height: h,
        color: const Color(0xFFF3F4F6),
        child: Center(
          child: Icon(Icons.home_outlined, size: 60, color: Colors.grey.shade300),
        ),
      );

  // ── Property type badge ───────────────────────────────────────────────────────
  String get _propertyTypeBadge {
    try {
      final t = (_data['type'] ?? _data['propertyType'] ?? '').toString().toLowerCase();
      switch (t) {
        case 'apartment': return 'Apartment';
        case 'shared_rooms': return 'Shared Room';
        case 'temporary_stays': return 'Temporary Stay';
        case 'house': return 'House';
        case 'studio': return 'Studio';
        default: return t.isNotEmpty ? t : 'Accommodation';
      }
    } catch (_) {
      return 'Accommodation';
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = _allImages;
    final rent = _rentDetails;
    final prop = _propDetails;
    final amenities = _amenitiesList;

    final String title = _str(_data['title'], 'Accommodation');
    final String city = _str(_data['city'] ?? _data['location'], '');
    final String area = _str(_data['area'], '');
    final String address = _str(_data['address'], '');
    final String zipCode = _str(_data['zipCode'] ?? _data['postalCode'], '');
    final String contactPhone = _str(_data['contactPhone'] ?? _data['phone'], '');
    final String externalLink = _str(_data['link'] ?? _data['externalUrl'] ?? _data['website'], '');
    final String description = _str(_data['description'], '');
    final double? lat = _data['latitude'] is num ? (_data['latitude'] as num).toDouble() : null;
    final double? lon = _data['longitude'] is num ? (_data['longitude'] as num).toDouble() : null;

    final double coldRent = _dbl(_safe(rent, 'coldRent'));
    final double warmRent = _dbl(_safe(rent, 'warmRent'));
    final double deposit = _dbl(_safe(rent, 'deposit'));
    final double sizeSqm = _dbl(_safe(prop, 'sizeSqm'));
    final int bedrooms = _int(_safe(prop, 'bedrooms'));
    final int bathrooms = _int(_safe(prop, 'bathrooms'));

    final double avgRating = _ratingStats?.averageRating ?? _dbl(_data['averageRating']);
    final int totalRatings = _ratingStats?.totalRatings ?? _int(_data['totalRatings']);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: CustomScrollView(
        slivers: [
          // ─── IMAGE GALLERY HEADER ───────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: Colors.white,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6)],
                  ),
                  child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 8, left: 8, right: 4),
                child: GestureDetector(
                  onTap: _shareAccommodation,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6)],
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.share_outlined,
                      color: primaryGreen,
                      size: 22,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 8, left: 4, right: 8),
                child: GestureDetector(
                  onTap: _toggleSave,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6)],
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      _isSaved ? Icons.bookmark : Icons.bookmark_border,
                      color: _isSaved ? primaryGreen : Colors.black,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: images.isNotEmpty
                  ? Stack(
                      children: [
                        PageView.builder(
                          controller: _pageController,
                          itemCount: images.length,
                          onPageChanged: (i) => setState(() => _currentImageIndex = i),
                          itemBuilder: (_, i) => _buildImageWidget(images[i]),
                        ),
                        if (images.length > 1)
                          Positioned(
                            bottom: 12,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(images.length, (i) => Container(
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                width: _currentImageIndex == i ? 18 : 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: _currentImageIndex == i ? primaryGreen : Colors.white.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              )),
                            ),
                          ),
                        // Image counter badge
                        if (images.length > 1)
                          Positioned(
                            top: 12,
                            right: 60,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.55),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${_currentImageIndex + 1}/${images.length}',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                      ],
                    )
                  : _placeholder(280),
            ),
          ),

          // ─── CONTENT ────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── TITLE + BADGE ──────────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                            height: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: primaryGreen.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: primaryGreen.withOpacity(0.4)),
                        ),
                        child: Text(
                          _propertyTypeBadge,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: primaryGreen,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // ── RATING ─────────────────────────────────────────────────
                  Row(
                    children: [
                      StarRatingWidget(rating: avgRating, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '${avgRating.toStringAsFixed(1)} ($totalRatings ratings)',
                        style: GoogleFonts.roboto(fontSize: 13, fontWeight: FontWeight.w600, color: textSecondary),
                      ),
                      if (_userRating != null) ...[
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: _showRatingDialog,
                          child: const Icon(Icons.edit, size: 16, color: primaryGreen),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 14),

                  // ── LOCATION ROW ───────────────────────────────────────────
                  if (city.isNotEmpty || area.isNotEmpty || zipCode.isNotEmpty)
                    _InfoCard(
                      child: Column(
                        children: [
                          _InfoRow(icon: Icons.location_on_outlined, color: primaryGreen, label: 'Location',
                              value: [area, city, zipCode].where((s) => s.isNotEmpty).join(', ')),
                          if (address.isNotEmpty) ...[
                            const Divider(height: 16),
                            _InfoRow(icon: Icons.map_outlined, color: primaryGreen, label: 'Address', value: address),
                          ],
                        ],
                      ),
                    ),

                  const SizedBox(height: 14),

                  // ── RENT DETAILS CARD ──────────────────────────────────────
                  if (coldRent > 0 || warmRent > 0 || deposit > 0)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionTitle(text: '💶 Rent Details'),
                        const SizedBox(height: 8),
                        _InfoCard(
                          child: Row(
                            children: [
                              if (coldRent > 0) Expanded(child: _RentCell(label: 'Cold Rent', value: '€${coldRent.toStringAsFixed(0)}')),
                              if (warmRent > 0) Expanded(child: _RentCell(label: 'Warm Rent', value: '€${warmRent.toStringAsFixed(0)}')),
                              if (deposit > 0) Expanded(child: _RentCell(label: 'Deposit', value: '€${deposit.toStringAsFixed(0)}')),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                    ),

                  // ── PROPERTY DETAILS CARD ──────────────────────────────────
                  if (sizeSqm > 0 || bedrooms > 0 || bathrooms > 0)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionTitle(text: '🏠 Property Details'),
                        const SizedBox(height: 8),
                        _InfoCard(
                          child: Row(
                            children: [
                              if (sizeSqm > 0) Expanded(child: _PropCell(icon: Icons.square_foot, label: 'Size', value: '${sizeSqm.toStringAsFixed(0)} m²')),
                              if (bedrooms > 0) Expanded(child: _PropCell(icon: Icons.bed_outlined, label: 'Bedrooms', value: bedrooms.toString())),
                              if (bathrooms > 0) Expanded(child: _PropCell(icon: Icons.bathroom_outlined, label: 'Bathrooms', value: bathrooms.toString())),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                    ),

                  // ── DESCRIPTION ────────────────────────────────────────────
                  if (description.isNotEmpty) ...[
                    _SectionTitle(text: 'Description'),
                    const SizedBox(height: 8),
                    _InfoCard(
                      child: Text(
                        description,
                        style: GoogleFonts.roboto(fontSize: 14, color: textSecondary, height: 1.6),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // ── AMENITIES ──────────────────────────────────────────────
                  if (amenities.isNotEmpty) ...[
                    _SectionTitle(text: '✨ Amenities'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: amenities.map((a) => _AmenityChip(text: a)).toList(),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // ── EXTERNAL LISTING ───────────────────────────────────────
                  if (externalLink.isNotEmpty) ...[
                    _SectionTitle(text: '🔗 External Listing / Website'),
                    const SizedBox(height: 8),
                    _InfoCard(
                      child: InkWell(
                        onTap: () async {
                          String url = externalLink.trim();
                          if (!url.startsWith('http://') && !url.startsWith('https://')) {
                            url = 'https://' + url;
                          }
                          final uri = Uri.parse(url);
                          try {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          } catch (_) {}
                        },
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: lightGreen,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.link, color: primaryGreen, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'View on Original Portal / Website',
                                    style: TextStyle(
                                      color: textPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    externalLink,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: primaryGreen,
                                      fontSize: 12,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.open_in_new, color: primaryGreen, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // ── CONTACT INFO ───────────────────────────────────────────
                  if (contactPhone.isNotEmpty) ...[
                    _SectionTitle(text: 'Contact'),
                    const SizedBox(height: 8),
                    _InfoCard(
                      child: _InfoRow(icon: Icons.phone_outlined, color: primaryGreen, label: 'Phone', value: contactPhone),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // ── MAP ────────────────────────────────────────────────────
                  if (lat != null || lon != null || area.isNotEmpty || city.isNotEmpty) ...[
                    _SectionTitle(text: '📍 Location'),
                    const SizedBox(height: 8),
                    _buildMapSection(context, lat, lon, [area, city].where((s) => s.isNotEmpty).join(', ')),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),

      // ─── BOTTOM ACTION BUTTONS ───────────────────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (externalLink.isNotEmpty) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      String url = externalLink.trim();
                      if (!url.startsWith('http://') && !url.startsWith('https://')) {
                        url = 'https://' + url;
                      }
                      final uri = Uri.parse(url);
                      try {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      } catch (_) {}
                    },
                    icon: const Icon(Icons.open_in_new, color: Colors.white, size: 18),
                    label: const Text(
                      'View Original Listing / Website',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              if (contactPhone.isNotEmpty) ...[
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: const Icon(Icons.call, color: Colors.white, size: 18),
                        label: 'Call',
                        color: primaryGreen,
                        onPressed: () => _makePhoneCall(context, contactPhone),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ActionButton(
                        icon: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.white, size: 18),
                        label: 'WhatsApp',
                        color: const Color(0xFF25D366),
                        onPressed: () => _openWhatsApp(context, contactPhone),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showRatingDialog,
                  icon: const Icon(Icons.star_outline, color: Colors.white, size: 18),
                  label: const Text('Rate This Accommodation',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapSection(BuildContext context, double? lat, double? lon, String addressText) {
    Future<void> openGoogleMaps(double? latitude, double? longitude) async {
      final Uri url;
      if (latitude != null && longitude != null) {
        url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude');
      } else {
        final query = Uri.encodeComponent(addressText);
        url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
      }
      if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
    }

    if (lat != null && lon != null) {
      return _AccommodationMapWidget(lat: lat, lon: lon, address: addressText);
    }

    if (addressText.isEmpty) {
      return Container(
        height: 60,
        decoration: BoxDecoration(
          color: lightGreen,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primaryGreen.withOpacity(0.3)),
        ),
        child: const Center(child: Text('Location not available', style: TextStyle(color: primaryGreen))),
      );
    }

    return FutureBuilder<Map<String, double>?>(
      future: _geocodeAddress(addressText),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 180,
              color: Colors.grey[200],
              child: const Center(child: CircularProgressIndicator(color: primaryGreen)),
            ),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          return _AccommodationMapWidget(
            lat: snapshot.data!['lat']!,
            lon: snapshot.data!['lon']!,
            address: addressText,
          );
        }
        return GestureDetector(
          onTap: () => openGoogleMaps(null, null),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: lightGreen,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryGreen),
            ),
            child: const Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.map_outlined, color: primaryGreen),
                  SizedBox(width: 8),
                  Text('Open location in Google Maps',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: primaryGreen)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, double>?> _geocodeAddress(String address) async {
    if (address.isEmpty) return null;
    try {
      final encoded = Uri.encodeComponent(address);
      final response = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/search?q=$encoded&format=json&limit=1'),
        headers: {'User-Agent': 'GermanBharatham/1.0'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        if (data.isNotEmpty) {
          return {
            'lat': double.parse(data[0]['lat'] as String),
            'lon': double.parse(data[0]['lon'] as String),
          };
        }
      }
    } catch (_) {}
    return null;
  }

  void _shareAccommodation() {
    ListingShareModal.show(
      context: context,
      category: 'accommodation',
      id: (_data['id'] ?? '').toString(),
      title: (_data['title'] ?? 'Accommodation').toString(),
      subtitle: (_data['city'] ?? _data['address'] ?? 'Germany').toString(),
      imageUrl: _allImages.isNotEmpty ? _allImages.first : null,
      price: _rentString,
    );
  }

  void _toggleSave() {
    try {
      final nowSaved = SavedManager.instance.toggle(widget.item);
      if (!mounted) return;
      setState(() => _isSaved = nowSaved);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(nowSaved ? 'Saved to bookmarks' : 'Removed from bookmarks'),
        duration: const Duration(seconds: 1),
        backgroundColor: primaryGreen,
      ));
      if (widget.onRefresh != null) widget.onRefresh!();
    } catch (_) {}
  }

  Future<void> _makePhoneCall(BuildContext context, String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number not available'), backgroundColor: Colors.red),
      );
      return;
    }
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) await launchUrl(phoneUri);
  }

  Future<void> _openWhatsApp(BuildContext context, String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number not available'), backgroundColor: Colors.red),
      );
      return;
    }
    String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    if (!cleanPhone.startsWith('+')) cleanPhone = '+49$cleanPhone';
    final Uri whatsappUri = Uri.parse('https://wa.me/$cleanPhone');
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    }
  }
}

// ── Premium helper widgets ───────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle({required this.text});

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF1A1A2E),
        ),
      );
}

class _InfoCard extends StatelessWidget {
  final Widget child;
  const _InfoCard({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: child,
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.roboto(fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFF9CA3AF))),
                const SizedBox(height: 2),
                Text(value, style: GoogleFonts.roboto(fontSize: 14, color: const Color(0xFF374151), fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      );
}

class _RentCell extends StatelessWidget {
  final String label;
  final String value;
  const _RentCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(value, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF4E7F6D))),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.roboto(fontSize: 11, color: const Color(0xFF9CA3AF))),
        ],
      );
}

class _PropCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _PropCell({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Icon(icon, size: 22, color: const Color(0xFF4E7F6D)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A2E))),
          Text(label, style: GoogleFonts.roboto(fontSize: 11, color: const Color(0xFF9CA3AF))),
        ],
      );
}

class _ActionButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;
  const _ActionButton({required this.icon, required this.label, required this.color, required this.onPressed});

  @override
  Widget build(BuildContext context) => ElevatedButton.icon(
        onPressed: onPressed,
        icon: icon,
        label: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
}

class _AmenityChip extends StatelessWidget {
  final String text;
  const _AmenityChip({required this.text});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5F0),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF4E7F6D).withOpacity(0.3)),
        ),
        child: Text(
          text,
          style: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF4E7F6D)),
        ),
      );
}

// ── Map Widget with user-location support ────────────────────────────────────

class _AccommodationMapWidget extends StatefulWidget {
  final double lat;
  final double lon;
  final String address;

  const _AccommodationMapWidget({required this.lat, required this.lon, required this.address});

  @override
  State<_AccommodationMapWidget> createState() => _AccommodationMapWidgetState();
}

class _AccommodationMapWidgetState extends State<_AccommodationMapWidget> {
  final MapController _mapController = MapController();
  LatLng? _userLocation;
  bool _locating = false;

  Future<void> _locateUser() async {
    setState(() => _locating = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied'), backgroundColor: Colors.red),
        );
        setState(() => _locating = false);
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final userLatLng = LatLng(position.latitude, position.longitude);
      if (mounted) {
        setState(() {
          _userLocation = userLatLng;
          _locating = false;
        });
        _mapController.move(userLatLng, 14);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _locating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get location: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _openGoogleMaps() async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${widget.lat},${widget.lon}',
    );
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 200,
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(widget.lat, widget.lon),
                initialZoom: 15,
                interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.german.german_bharatham_admin',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(widget.lat, widget.lon),
                      width: 40,
                      height: 40,
                      child: Image.asset('assets/images/location.png', width: 40, height: 40),
                    ),
                    if (_userLocation != null)
                      Marker(
                        point: _userLocation!,
                        width: 22,
                        height: 22,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A73E8),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: GestureDetector(
                onTap: _openGoogleMaps,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.map_outlined, size: 14, color: Color(0xFF1A56DB)),
                      SizedBox(width: 4),
                      Text('Open in Google Maps',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1A56DB))),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: _locating ? null : _locateUser,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                  ),
                  child: _locating
                      ? const Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4E7F6D)),
                        )
                      : const Icon(Icons.my_location, size: 20, color: Color(0xFF4E7F6D)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
