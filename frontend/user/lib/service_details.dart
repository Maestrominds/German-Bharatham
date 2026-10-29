import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter_map/flutter_map.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'models/service_model.dart';
import 'saved_service_manager.dart';
import 'services/rating_service.dart';
import 'models/rating_model.dart';
import 'widgets/rating_dialog.dart';
import 'services/api_config.dart';
import 'widgets/optimized_image.dart';
import 'widgets/listing_share_modal.dart';

Widget _buildServiceImage(
  String src, {
  required double width,
  required double height,
  Map<String, Uint8List>? cache,
}) {
  final fallback = Container(
    width: width,
    height: height,
    color: Colors.grey.shade100,
    child: Center(
      child: Icon(
        Icons.business_center_outlined,
        size: width * 0.4,
        color: Colors.grey.shade300,
      ),
    ),
  );

  if (src.trim().isEmpty) {
    return fallback;
  }

  // Prepend base API URL to relative image paths
  String absoluteSrc = src;
  if (!src.startsWith('data:image') &&
      !src.startsWith('http://') &&
      !src.startsWith('https://') &&
      !src.startsWith('assets/')) {
    absoluteSrc = ApiConfig.getImageUrl(src);
  }

  if (absoluteSrc.startsWith('data:image')) {
    try {
      Uint8List? bytes = cache?[absoluteSrc];
      if (bytes == null) {
        bytes = base64Decode(absoluteSrc.split(',').last);
        if (cache != null) {
          cache[absoluteSrc] = bytes;
        }
      }
      return Image.memory(
        bytes,
        width: width,
        height: height,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => fallback,
      );
    } catch (_) {
      return fallback;
    }
  }

  if (absoluteSrc.startsWith('http://') || absoluteSrc.startsWith('https://')) {
    return OptimizedImage(
      imageUrl: absoluteSrc,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorWidget: fallback,
      placeholder: fallback,
    );
  }

  return Image.asset(
    absoluteSrc,
    width: width,
    height: height,
    fit: BoxFit.cover,
    errorBuilder: (_, __, ___) => fallback,
  );
}

class ServiceDetailsPage extends StatefulWidget {
  final Service item;
  final VoidCallback? onRefresh;

  const ServiceDetailsPage({super.key, required this.item, this.onRefresh});

  @override
  State<ServiceDetailsPage> createState() => _ServiceDetailsPageState();
}

class _ServiceDetailsPageState extends State<ServiceDetailsPage> {
  RatingStats? _ratingStats;
  Rating? _userRating;
  late bool _isSaved;
  late final String _displayImage;
  int _currentImageIndex = 0;
  late PageController _pageController;
  Timer? _slideshowTimer;
  final Map<String, Uint8List> _base64Cache = {};

  @override
  void initState() {
    super.initState();
    _isSaved = SavedServiceManager.instance.isSaved(widget.item.id);
    _displayImage = widget.item.images.isNotEmpty
        ? widget.item.images.first
        : (widget.item.image ?? '');
    _pageController = PageController();
    _loadRatingData();
    _startSlideshow();
  }

  void _startSlideshow() {
    final imgs = widget.item.images;
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

  @override
  void dispose() {
    _slideshowTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadRatingData() async {
    final statsFuture = RatingService.getEntityRatingStats(
      entityId: widget.item.id,
      entityType: 'service',
    );
    final userRatingFuture = RatingService.getUserRating(
      entityId: widget.item.id,
      entityType: 'service',
    );

    final stats = await statsFuture;
    final userRating = await userRatingFuture;

    if (!mounted) return;
    setState(() {
      _ratingStats = stats;
      _userRating = userRating;
    });
  }

  // Note: Saving/bookmarking is handled from the listing cards.

  void _showRatingDialog() {
    showDialog(
      context: context,
      builder: (context) => RatingDialog(
        entityId: widget.item.id,
        entityType: 'service',
        entityName: widget.item.title,
        initialRating: _userRating?.rating ?? 0,
        onRatingSubmitted: () async {
          await _loadRatingData();
          widget.onRefresh?.call();
        },
      ),
    );
  }

  void _shareService() {
    final title = widget.item.title.isNotEmpty ? widget.item.title : 'Service';
    final subtitle = (widget.item.provider != null && widget.item.provider!.isNotEmpty)
        ? widget.item.provider!
        : widget.item.city;
    ListingShareModal.show(
      context: context,
      category: 'services',
      id: widget.item.id.toString(),
      title: title,
      subtitle: subtitle,
      imageUrl: widget.item.images.isNotEmpty ? widget.item.images.first : null,
      price: widget.item.priceRange,
    );
  }

  Future<void> _toggleSave() async {
    final nowSaved = await SavedServiceManager.instance.toggle(widget.item);
    if (!mounted) return;
    setState(() => _isSaved = nowSaved);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          nowSaved ? 'Saved to bookmarks' : 'Removed from bookmarks',
        ),
        duration: const Duration(seconds: 1),
        backgroundColor: const Color(0xFF4E7F6D),
      ),
    );
  }

  Future<void> _makePhoneCall() async {
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
    if (await canLaunchUrl(phoneUri)) await launchUrl(phoneUri);
  }

  Future<void> _openWhatsApp() async {
    final raw = (widget.item.whatsapp ?? widget.item.phone ?? '').trim();
    if (raw.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('WhatsApp number not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final cleanPhone = raw.replaceAll(RegExp(r'[^0-9+]'), '');
    final Uri whatsappUri = Uri.parse('https://wa.me/$cleanPhone');
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not launch WhatsApp'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openWebsite() async {
    final raw = (widget.item.website ?? '').trim();
    if (raw.isEmpty) return;

    final withScheme = (raw.startsWith('http://') || raw.startsWith('https://'))
        ? raw
        : 'https://$raw';
    final Uri websiteUri = Uri.parse(withScheme);

    if (await canLaunchUrl(websiteUri)) {
      await launchUrl(websiteUri, mode: LaunchMode.externalApplication);
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not open website'),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _infoIcon(String iconAsset) {
    if (iconAsset.contains('whatsapp')) {
      return const FaIcon(
        FontAwesomeIcons.whatsapp,
        size: 18,
        color: Color(0xFF4E7F6D),
      );
    }

    IconData fallbackIcon = Icons.info_outline;
    if (iconAsset.contains('call')) fallbackIcon = Icons.call;
    if (iconAsset.contains('msg')) fallbackIcon = Icons.mail_outline;
    if (iconAsset.contains('link')) fallbackIcon = Icons.link;
    if (iconAsset.contains('location')) fallbackIcon = Icons.location_on_outlined;
    if (iconAsset.contains('profile')) fallbackIcon = Icons.person_outline;
    if (iconAsset.contains('handshake')) fallbackIcon = Icons.handshake_outlined;

    const iconColor = Color(0xFF4E7F6D);

    return Image.asset(
      iconAsset,
      height: 18,
      width: 18,
      color: iconColor,
      errorBuilder: (_, __, ___) => Icon(
        fallbackIcon,
        size: 18,
        color: iconColor,
      ),
    );
  }

  Future<void> _sendEmail() async {
    final email = (widget.item.email ?? '').trim();
    if (email.isEmpty) return;
    final Uri uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not open email app'),
        backgroundColor: Colors.red,
      ),
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

  Widget _buildMapSection(double? latitude, double? longitude, String address) {
    if (latitude != null && longitude != null) {
      return _ServiceMapWidget(lat: latitude, lon: longitude, address: address);
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
          return _ServiceMapWidget(
            lat: snapshot.data!['lat']!,
            lon: snapshot.data!['lon']!,
            address: address,
          );
        }

        final isMapUrl = address.startsWith('http');
        
        return GestureDetector(
          onTap: () async {
            final url = isMapUrl 
                ? Uri.parse(address)
                : Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}');
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

  @override
  Widget build(BuildContext context) {
    final locationText = widget.item.city.trim().isNotEmpty
        ? widget.item.city
        : (widget.item.address ?? '');

    final displayRatingValue = _ratingStats != null
        ? _ratingStats!.averageRating
        : widget.item.averageRating;
    final displayRatingText = (displayRatingValue > 0)
        ? displayRatingValue.toStringAsFixed(1)
        : '0.0';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// IMAGE HEADER
                  Stack(
                    children: [
                      SizedBox(
                        height: 300,
                        child: widget.item.images.isNotEmpty
                            ? Stack(
                                children: [
                                  PageView.builder(
                                    controller: _pageController,
                                    itemCount: widget.item.images.length,
                                    onPageChanged: (i) => setState(() => _currentImageIndex = i),
                                    itemBuilder: (_, i) => _buildServiceImage(widget.item.images[i], width: double.infinity, height: 300, cache: _base64Cache),
                                  ),
                                  if (widget.item.images.length > 1)
                                    Positioned(
                                      bottom: 12,
                                      left: 0,
                                      right: 0,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: List.generate(
                                          widget.item.images.length,
                                          (i) => Container(
                                            margin: const EdgeInsets.symmetric(horizontal: 4),
                                            width: _currentImageIndex == i ? 12 : 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(4),
                                              color: _currentImageIndex == i
                                                  ? const Color(0xFF4E7F6D)
                                                  : Colors.white.withOpacity(0.6),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              )
                            : _buildServiceImage('', width: double.infinity, height: 300, cache: _base64Cache),
                      ),
                      Positioned(
                        top: 12,
                        left: 12,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6)],
                            ),
                            padding: const EdgeInsets.all(8),
                            child: Image.asset(
                              'assets/images/left-arrow.png',
                              height: 22,
                              width: 22,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: _shareService,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6)],
                                ),
                                padding: const EdgeInsets.all(8),
                                child: const Icon(
                                  Icons.share_outlined,
                                  size: 22,
                                  color: Color(0xFF4E7F6D),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _toggleSave,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6)],
                                ),
                                padding: const EdgeInsets.all(8),
                                child: Image.asset(
                                  'assets/images/bookmark.png',
                                  height: 22,
                                  width: 22,
                                  color: _isSaved ? const Color(0xFF4E7F6D) : Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  /// CONTENT
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.item.title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Image.asset(
                                      'assets/images/location.png',
                                      width: 14,
                                      height: 14,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        locationText,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Image.asset(
                                      'assets/images/star.png',
                                      width: 16,
                                      height: 16,
                                      color: Colors.orange,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      displayRatingText,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    if (_userRating != null) ...[
                                      const SizedBox(width: 6),
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
                          ],
                        ),
                      ),
                    ),

                const SizedBox(height: 16),

                // Info / contact section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (widget.item.serviceType.trim().isNotEmpty)
                        _infoRow(
                          iconAsset: 'assets/images/handshake.png',
                          title: 'Service Type',
                          value: widget.item.serviceType,
                        ),
                      if ((widget.item.provider ?? '').trim().isNotEmpty)
                        _infoRow(
                          iconAsset: 'assets/images/profile.png',
                          title: 'Provider',
                          value: widget.item.provider!.trim(),
                        ),
                      if ((widget.item.phone ?? '').trim().isNotEmpty)
                        _infoRow(
                          iconAsset: 'assets/images/call.png',
                          title: 'Phone',
                          value: widget.item.phone!.trim(),
                        ),
                      if ((widget.item.whatsapp ?? '').trim().isNotEmpty)
                        _infoRow(
                          iconAsset: 'assets/images/whatsapp.png',
                          title: 'WhatsApp',
                          value: widget.item.whatsapp!.trim(),
                        ),
                      if ((widget.item.email ?? '').trim().isNotEmpty)
                        InkWell(
                          onTap: _sendEmail,
                          child: _infoRow(
                            iconAsset: 'assets/images/msg.png',
                            title: 'Email',
                            value: widget.item.email!.trim(),
                            valueColor: const Color(0xFF1A56DB),
                          ),
                        ),
                      if ((widget.item.website ?? '').trim().isNotEmpty)
                        InkWell(
                          onTap: _openWebsite,
                          child: _infoRow(
                            iconAsset: 'assets/images/link.png',
                            title: 'Website',
                            value: widget.item.website!.trim(),
                            valueColor: const Color(0xFF1A56DB),
                          ),
                        ),
                      if ((widget.item.priceRange ?? '').trim().isNotEmpty)
                        _infoRow(
                          iconAsset: 'assets/images/info.png',
                          title: 'Price Range',
                          value: widget.item.priceRange!.trim(),
                        ),
                      if ((widget.item.area ?? '').trim().isNotEmpty)
                        _infoRow(
                          iconAsset: 'assets/images/location.png',
                          title: 'Area',
                          value: widget.item.area!.trim(),
                        ),
                      if ((widget.item.zipCode ?? '').trim().isNotEmpty)
                        _infoRow(
                          iconAsset: 'assets/images/location.png',
                          title: 'Postal Code',
                          value: widget.item.zipCode!.trim(),
                        ),
                      if ((widget.item.address ?? '').trim().isNotEmpty)
                        _infoRow(
                          iconAsset: 'assets/images/location.png',
                          title: 'Address',
                          value: widget.item.address!.trim(),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                if (widget.item.description != null &&
                    widget.item.description!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.item.description!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                if (widget.item.servicesOffered.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Services Offered',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: widget.item.servicesOffered
                              .map(
                                (s) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F3F5),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    s,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),
                if (widget.item.area != null || widget.item.zipCode != null || (widget.item.address != null && !widget.item.address!.startsWith('http'))) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Location Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (widget.item.area != null) Text('Area: ${widget.item.area}', style: const TextStyle(fontSize: 15)),
                        if (widget.item.zipCode != null) Text('Postal Code: ${widget.item.zipCode}', style: const TextStyle(fontSize: 15)),
                        if (widget.item.address != null && !widget.item.address!.startsWith('http'))
                          Text('Address: ${widget.item.address}', style: const TextStyle(fontSize: 15)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Map",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildMapSection(
                        widget.item.latitude,
                        widget.item.longitude,
                        (widget.item.address ?? widget.item.city),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 150),
              ],
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: _makePhoneCall,
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: const Color(0xFF4F7F67),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: Image.asset(
                            'assets/images/call.png',
                            height: 20,
                            width: 20,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Call',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: _openWhatsApp,
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: const Color(0xFF4F7F67),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const FaIcon(
                            FontAwesomeIcons.whatsapp,
                            color: Colors.white,
                            size: 20,
                          ),
                          label: const Text(
                            'Whatsapp',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _showRatingDialog,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0xFF4F7F67),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '★',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            height: 1.0,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Rate This Service',
                          style: TextStyle(
                            fontSize: 16,
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

  Widget _infoRow({
    required String iconAsset,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF4E7F6D).withOpacity(0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: _infoIcon(iconAsset),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: valueColor ?? Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceMapWidget extends StatefulWidget {
  final double lat;
  final double lon;
  final String address;

  const _ServiceMapWidget({
    required this.lat,
    required this.lon,
    required this.address,
  });

  @override
  State<_ServiceMapWidget> createState() => _ServiceMapWidgetState();
}

class _ServiceMapWidgetState extends State<_ServiceMapWidget> {
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
      if (!mounted) return;
      setState(() {
        _userLocation = userLatLng;
        _locating = false;
      });
      _mapController.move(userLatLng, 14);
    } catch (e) {
      if (!mounted) return;
      setState(() => _locating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not get location: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
                  userAgentPackageName: 'com.german.german_bharatham_admin',
                ),
                MarkerLayer(
                  markers: [
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
                      const Icon(
                        Icons.map,
                        size: 14,
                        color: Color(0xFF1A56DB),
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

class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }
}
