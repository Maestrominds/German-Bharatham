import 'dart:convert';
import 'dart:typed_data';
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
import 'services/rating_service.dart';
import 'models/rating_model.dart';
import 'saved_manager.dart';

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
  RatingStats? _ratingStats;
  Rating? _userRating;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    try {
      _isSaved = SavedManager.instance.isSaved((widget.item.id ?? '').toString());
    } catch (_) {
      _isSaved = false;
    }
    _loadRatingData();
  }

  Future<void> _loadRatingData() async {
    final statsFuture = RatingService.getEntityRatingStats(
      entityId: widget.item.id.toString(),
      entityType: 'accommodation',
    );
    final userRatingFuture = RatingService.getUserRating(
      entityId: widget.item.id.toString(),
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
    showDialog(
      context: context,
      builder: (context) => RatingDialog(
        entityId: widget.item.id.toString(),
        entityType: 'accommodation',
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
                    icon: 'assets/images/left-arrow.png',
                    onTap: () => Navigator.pop(context),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: _circleIcon(
                    icon: 'assets/images/bookmark.png',
                    iconColor: _isSaved ? const Color(0xFF4E7F6D) : Colors.black,
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
                    /// TITLE
                    Text(
                      widget.item.title,
                      style: GoogleFonts.roboto(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        height: 1.18,
                        color: Colors.black,
                      ),
                    ),

                    const SizedBox(height: 10),

                    /// RATING SECTION
                    Row(
                      children: [
                        StarRatingWidget(
                          rating:
                              _ratingStats?.averageRating ??
                              (widget.item.averageRating ?? 0.0),
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _ratingStats != null
                              ? '${_ratingStats!.averageRating.toStringAsFixed(1)} (${_ratingStats!.totalRatings} ratings)'
                              : '${(widget.item.averageRating ?? 0.0).toStringAsFixed(1)} (${widget.item.totalRatings ?? 0} ratings)',
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
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

                    const SizedBox(height: 12),

                    /// LOCATION + PRICE
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Image.asset(
                                'assets/images/location.png',
                                width: 14,
                                height: 14,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  widget.item.location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.roboto(
                                    fontSize: 14,
                                    color: const Color(0xFF7A7A7A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "€${widget.item.price} / per month",
                          style: GoogleFonts.roboto(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF4E7F6D),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    /// DESCRIPTION
                    const Text(
                      "Description",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      "Modern 2-room apartment in the heart of Munich.\n"
                      "Close to public transport, shopping centers, and parks.\n"
                      "Perfect for students and young professionals.",
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6E6E6E),
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 18),

                    /// AMENITIES
                    const Text(
                      "Amenities",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _AmenityChip(text: "Furnished"),
                        _AmenityChip(text: "Kitchen"),
                        _AmenityChip(text: "Wifi"),
                      ],
                    ),

                    const SizedBox(height: 18),

                    /// LOCATION MAP
                    const Text(
                      "Location",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 8),

                    _buildMapSection(context),
                  ],
                ),
              ),
            ),

            /// BOTTOM BUTTONS
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _bottomButton(
                          icon: 'assets/images/call.png',
                          label: "Call",
                          color: const Color(0xFF4E7F6D),
                          onPressed: () =>
                              _makePhoneCall(context, widget.item.contactPhone),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _bottomButton(
                          icon: 'assets/images/whatsapp.png',
                          label: "Whatsapp",
                          color: const Color(0xFF4E7F6D),
                          onPressed: () =>
                              _openWhatsApp(context, widget.item.contactPhone),
                          iconOverride: const FaIcon(
                            FontAwesomeIcons.whatsapp,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
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
                          Image.asset(
                            'assets/images/star.png',
                            width: 18,
                            height: 18,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Rate This Accommodation',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildMapSection(BuildContext context) {
    final double? lat = widget.item.latitude;
    final double? lon = widget.item.longitude;

    Future<void> openGoogleMaps(double? latitude, double? longitude) async {
      final Uri url;
      if (latitude != null && longitude != null) {
        url = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude',
        );
      } else {
        final query = Uri.encodeComponent(widget.item.location ?? '');
        url = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$query',
        );
      }
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    }

    // If lat/lon already stored, show map immediately
    if (lat != null && lon != null) {
      return _AccommodationMapWidget(
        lat: lat,
        lon: lon,
        address: widget.item.location ?? '',
      );
    }

    // Otherwise geocode the address text via Nominatim (free, no API key)
    return FutureBuilder<Map<String, double>?>(
      future: _geocodeAddress(widget.item.location ?? ''),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 180,
              color: Colors.grey[200],
              child: const Center(child: CircularProgressIndicator()),
            ),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          return _AccommodationMapWidget(
            lat: snapshot.data!['lat']!,
            lon: snapshot.data!['lon']!,
            address: widget.item.location ?? '',
          );
        }
        // Geocoding failed — fallback tap button
        return GestureDetector(
          onTap: () => openGoogleMaps(null, null),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF4E7F6D)),
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/google.png',
                    width: 18,
                    height: 18,
                  ),
                  const SizedBox(width: 8),
                  const Text(
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

  Future<Map<String, double>?> _geocodeAddress(String address) async {
    if (address.isEmpty) return null;
    try {
      final encoded = Uri.encodeComponent(address);
      final response = await http.get(
        Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=$encoded&format=json&limit=1',
        ),
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

  Widget _circleIcon({required String icon, Color? iconColor, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Image.asset(icon, width: 18, height: 18, color: iconColor),
      ),
    );
  }

  Widget _buildImage(String? imageUrl, double height) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return _placeholderImage(height);
    }

    if (imageUrl.startsWith('data:image')) {
      try {
        final Uint8List bytes = base64Decode(imageUrl.split(',').last);
        return Image.memory(
          bytes,
          width: double.infinity,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholderImage(height),
        );
      } catch (_) {
        return _placeholderImage(height);
      }
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
    return Container(
      width: double.infinity,
      height: height,
      color: Colors.grey[200],
      child: Center(
        child: Image.asset(
          'assets/images/accommodation.png',
          width: 110,
          height: 110,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _bottomButton({
    required String icon,
    required String label,
    required Color color,
    VoidCallback? onPressed,
    Widget? iconOverride,
  }) {
    final Widget iconWidget =
        iconOverride ??
        Image.asset(icon, width: 18, height: 18, color: Colors.white);
    return ElevatedButton.icon(
      onPressed: onPressed ?? () {},
      icon: iconWidget,
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _toggleSave() {
    try {
      final nowSaved = SavedManager.instance.toggle(widget.item);
      if (!mounted) return;
      setState(() {
        _isSaved = nowSaved;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(nowSaved ? 'Saved to bookmarks' : 'Removed from bookmarks'),
          duration: const Duration(seconds: 1),
          backgroundColor: const Color(0xFF4E7F6D),
        ),
      );
      if (widget.onRefresh != null) {
        widget.onRefresh!();
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update bookmark'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _makePhoneCall(BuildContext context, String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
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

  Future<void> _openWhatsApp(BuildContext context, String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Remove any non-digit characters and ensure it has country code
    String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    if (!cleanPhone.startsWith('+')) {
      cleanPhone = '+49$cleanPhone'; // Default to Germany
    }

    final Uri whatsappUri = Uri.parse('https://wa.me/$cleanPhone');
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch WhatsApp'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

}

/// MAP WIDGET with user-location support
class _AccommodationMapWidget extends StatefulWidget {
  final double lat;
  final double lon;
  final String address;

  const _AccommodationMapWidget({
    required this.lat,
    required this.lon,
    required this.address,
  });

  @override
  State<_AccommodationMapWidget> createState() =>
      _AccommodationMapWidgetState();
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
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
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
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.germanbharatham.app',
                ),
                MarkerLayer(
                  markers: [
                    // Accommodation pin — red
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
                    // User location — blue dot (shown after locating)
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
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 4),
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
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 4),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/google.png',
                        width: 14,
                        height: 14,
                      ),
                      const SizedBox(width: 4),
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
                      BoxShadow(color: Colors.black26, blurRadius: 4),
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

/// AMENITY CHIP
class _AmenityChip extends StatelessWidget {
  final String text;

  const _AmenityChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.black,
        ),
      ),
    );
  }
}
