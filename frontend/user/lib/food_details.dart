import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/food_grocery_model.dart';
import 'saved_food_manager.dart';
import 'widgets/star_rating_widget.dart';
import 'widgets/rating_dialog.dart';
import 'services/rating_service.dart';
import 'models/rating_model.dart';

class FoodDetailPage extends StatefulWidget {
  final FoodGrocery item;
  final VoidCallback? onRefresh;

  const FoodDetailPage({
    super.key,
    required this.item,
    this.onRefresh,
  });

  @override
  State<FoodDetailPage> createState() => _FoodDetailPageState();
}

class _FoodDetailPageState extends State<FoodDetailPage> {
  late bool isSaved;
  RatingStats? _ratingStats;
  Rating? _userRating;

  @override
  void initState() {
    super.initState();
    isSaved = SavedFoodManager.instance.isSaved(widget.item.id);
    _loadRatingData();
  }

  Future<void> _loadRatingData() async {
    final statsFuture = RatingService.getEntityRatingStats(
      entityId: widget.item.id,
      entityType: 'foodgrocery',
    );
    final userRatingFuture = RatingService.getUserRating(
      entityId: widget.item.id,
      entityType: 'foodgrocery',
    );

    final stats = await statsFuture;
    final userRating = await userRatingFuture;

    if (!mounted) return;
    setState(() {
      _ratingStats = stats;
      _userRating = userRating;
    });
  }

  void _showRatingDialog() {
    showDialog(
      context: context,
      builder: (context) => RatingDialog(
        entityId: widget.item.id,
        entityType: 'foodgrocery',
        entityName: widget.item.title,
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

  Future<void> _toggleSave() async {
    final nowSaved = await SavedFoodManager.instance.toggle(widget.item);
    setState(() {
      isSaved = nowSaved;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(nowSaved ? 'Saved to bookmarks' : 'Removed from bookmarks'),
          duration: const Duration(seconds: 1),
          backgroundColor: const Color(0xFF4E7F6D),
        ),
      );
    }
    
    if (widget.onRefresh != null) {
      widget.onRefresh!();
    }
  }

  Future<void> _makePhoneCall(BuildContext context) async {
    if (widget.item.phone == null || widget.item.phone!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final Uri phoneUri = Uri(scheme: 'tel', path: widget.item.phone);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch phone dialer'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            /// IMAGE HEADER
            Stack(
              children: [
                _buildImage(widget.item.image, 300),
                Positioned(
                  top: 12,
                  left: 12,
                  child: _circleIcon(
                    iconAsset: 'assets/images/left-arrow.png',
                    iconColor: Colors.black,
                    onTap: () => Navigator.pop(context),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: _circleIcon(
                    iconAsset: 'assets/images/bookmark.png',
                    iconColor:
                        isSaved ? const Color(0xFF4E7F6D) : Colors.black,
                    onTap: _toggleSave,
                  ),
                ),
              ],
            ),

            /// CONTENT
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// TITLE + RATING
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            widget.item.title,
                            style: GoogleFonts.roboto(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              height: 1.18,
                              color: Colors.black,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              StarRatingWidget(
                                rating: _ratingStats?.averageRating ?? widget.item.averageRating,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  _ratingStats != null
                                      ? '${_ratingStats!.averageRating.toStringAsFixed(1)} (${_ratingStats!.totalRatings})'
                                      : widget.item.averageRating > 0
                                          ? widget.item.averageRating.toStringAsFixed(1)
                                          : '4.5',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                ),
                              ),
                              if (_userRating != null) ...[
                                const SizedBox(width: 4),
                                IconButton(
                                  onPressed: _showRatingDialog,
                                  icon: const Icon(
                                    Icons.edit,
                                    size: 18,
                                    color: Color(0xFF4E7F6D),
                                  ),
                                  tooltip: 'Edit rating',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    /// ADDRESS
                    _infoRow(
                      iconAsset: 'assets/images/location.png',
                      label: 'Address',
                      value: widget.item.address,
                    ),

                    if (widget.item.openingHours != null && widget.item.openingHours!.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _infoRow(
                        iconAsset: 'assets/images/time.png',
                        label: 'Time',
                        value: widget.item.openingHours!,
                      ),
                    ],

                    if (widget.item.priceRange != null && 
                        widget.item.priceRange!.isNotEmpty && 
                        widget.item.priceRange!.trim().isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _infoRow(
                        iconAsset: 'assets/images/info.png',
                        label: 'Price Range',
                        value: widget.item.priceRange!.replaceAll('\$', '').trim(),
                      ),
                    ],

                    const SizedBox(height: 20),

                    /// SERVICES
                    const Text(
                      "Services",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        if (widget.item.dineInAvailable) const _ServiceChip(text: "Dine-in"),
                        if (widget.item.deliveryAvailable) const _ServiceChip(text: "Home Delivery"),
                        if (widget.item.takeoutAvailable) const _ServiceChip(text: "Takeout"),
                        if (widget.item.cateringAvailable) const _ServiceChip(text: "Catering"),
                      ],
                    ),

                    const SizedBox(height: 20),

                    /// LOCATION MAP
                    const Text(
                      "Location",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 10),

                    _buildMapSection(widget.item.latitude, widget.item.longitude, widget.item.address),
                  ],
                ),
              ),
            ),

            /// CALL BUTTON
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _makePhoneCall(context),
                  icon: Image.asset(
                    'assets/images/call.png',
                    height: 20,
                    width: 20,
                    color: Colors.white,
                  ),
                  label: const Text(
                    "Call",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4E7F6D),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),

            /// RATE BUTTON
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _showRatingDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4E7F6D),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '★',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Rate This Restaurant",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleIcon({
    required String iconAsset,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Image.asset(
          iconAsset,
          height: 20,
          width: 20,
          color: iconColor,
        ),
      ),
    );
  }

  Widget _buildImage(String? imageUrl, double height) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return _placeholderImage(height);
    }

    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        width: double.infinity,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _placeholderImage(height),
      );
    } else {
      return Image.asset(
        imageUrl,
        width: double.infinity,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _placeholderImage(height),
      );
    }
  }

  Widget _placeholderImage(double height) {
    return Image.asset(
      'assets/images/restaurant.jpg',
      width: double.infinity,
      height: height,
      fit: BoxFit.cover,
    );
  }

  Widget _infoRow({
    required String iconAsset,
    required String label,
    required String value,
  }) {
    final bool isLocationIcon = iconAsset.contains('location.png');
    IconData fallbackIcon = Icons.info_outline;
    if (iconAsset.contains('location')) {
      fallbackIcon = Icons.place;
    } else if (iconAsset.contains('time') || iconAsset.contains('clock')) {
      fallbackIcon = Icons.access_time;
    } else if (iconAsset.contains('phone') || iconAsset.contains('call')) {
      fallbackIcon = Icons.phone;
    }
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          iconAsset,
          height: 20,
          width: 20,
          color: isLocationIcon ? null : const Color(0xFF4E7F6D),
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              fallbackIcon,
              size: 20,
              color: isLocationIcon ? Colors.green : const Color(0xFF4E7F6D),
            );
          },
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF9CA3AF),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF374151),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<Map<String, double>?> _geocodeAddress(String address) async {
    if (address.isEmpty) return null;
    try {
      final encoded = Uri.encodeComponent(address);
      final response = await http.get(
        Uri.parse(
            'https://nominatim.openstreetmap.org/search?q=$encoded&format=json&limit=1'),
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

  Widget _buildMapSection(double? latitude, double? longitude, String address) {
    if (latitude != null && longitude != null) {
      return _FoodMapWidget(lat: latitude, lon: longitude, address: address);
    }

    return FutureBuilder<Map<String, double>?>(
      future: _geocodeAddress(address),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 200,
              color: Colors.grey[200],
              child: const Center(child: CircularProgressIndicator()),
            ),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          return _FoodMapWidget(
            lat: snapshot.data!['lat']!,
            lon: snapshot.data!['lon']!,
            address: address,
          );
        }
        // Geocoding failed — fallback button
        return GestureDetector(
          onTap: () async {
            final query = Uri.encodeComponent(address);
            final url = Uri.parse(
                'https://www.google.com/maps/search/?api=1&query=$query');
            if (await canLaunchUrl(url)) {
              await launchUrl(url, mode: LaunchMode.externalApplication);
            }
          },
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF4E7F6D)),
            ),
            child: const Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.map_outlined, color: Color(0xFF4E7F6D)),
                  SizedBox(width: 8),
                  Text(
                    'Open location in Google Maps',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4E7F6D),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// MAP WIDGET with user-location support
class _FoodMapWidget extends StatefulWidget {
  final double lat;
  final double lon;
  final String address;

  const _FoodMapWidget({
    required this.lat,
    required this.lon,
    required this.address,
  });

  @override
  State<_FoodMapWidget> createState() => _FoodMapWidgetState();
}

class _FoodMapWidgetState extends State<_FoodMapWidget> {
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
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission denied'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _locating = false);
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
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
          SnackBar(
            content: Text('Could not get location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openGoogleMaps() async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${widget.lat},${widget.lon}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
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
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.none,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.germanbharatham.app',
                ),
                MarkerLayer(
                  markers: [
                    // Restaurant/shop pin — red
                    Marker(
                      point: LatLng(widget.lat, widget.lon),
                      width: 40,
                      height: 40,
                      child: Image.asset(
                        'assets/images/location.png',
                        width: 40,
                        height: 40,
                      ),
                    ),
                    // User location — blue dot
                    if (_userLocation != null)
                      Marker(
                        point: _userLocation!,
                        width: 22,
                        height: 22,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A73E8),
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: Colors.white, width: 2.5),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 4)
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),

            /// "Open in Google Maps" — bottom right
            Positioned(
              bottom: 8,
              right: 8,
              child: GestureDetector(
                onTap: _openGoogleMaps,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 4)
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/google.png',
                        width: 14,
                        height: 14,
                        errorBuilder: (_, __, ___) => const SizedBox(
                          width: 14,
                          height: 14,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Open in Google Maps',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A56DB),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            /// "My Location" button — top right
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
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 4)
                    ],
                  ),
                  child: _locating
                      ? const Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Image.asset(
                          'assets/images/location.png',
                          width: 20,
                          height: 20,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// SERVICE CHIP
class _ServiceChip extends StatelessWidget {
  final String text;

  const _ServiceChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );
  }
}
