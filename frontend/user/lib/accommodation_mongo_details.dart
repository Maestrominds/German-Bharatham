import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

/// Extended detail page showing all MongoDB accommodation data
class AccommodationMongoDetailsPage extends StatelessWidget {
  final dynamic item;

  const AccommodationMongoDetailsPage({super.key, required this.item});

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
                Container(
                  width: double.infinity,
                  height: 300,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: item.image.toString().startsWith('http')
                          ? NetworkImage(item.image)
                          : AssetImage(item.image) as ImageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: _CircleIcon(
                    iconAsset: 'assets/images/left-arrow.png',
                    iconColor: Colors.black,
                    onTap: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),

            /// SCROLLABLE CONTENT
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// TITLE & PRICE
                    Text(
                      item.title ?? 'Untitled',
                      style: GoogleFonts.roboto(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '€${item.price} / month',
                      style: GoogleFonts.roboto(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4E7F6D),
                      ),
                    ),
                    const SizedBox(height: 16),

                    /// PROPERTY TYPE BADGE
                    Chip(
                      label: Text(
                        item.propertyType ?? 'Accommodation',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      backgroundColor: const Color(0xFF007BFF),
                    ),
                    const SizedBox(height: 18),

                    /// LOCATION
                    Row(
                      children: [
                        Image.asset(
                          'assets/images/location.png',
                          height: 20,
                          width: 20,
                          color: const Color(0xFF6E6E6E),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.location ?? 'Location not specified',
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF6E6E6E),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    /// PROPERTY DETAILS CARD
                    if (item.bedrooms != null || item.bathrooms != null || item.sizeSqm != null) ...[
                      Text(
                        'Property Details',
                        style: GoogleFonts.roboto(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            if (item.bedrooms != null)
                              _DetailBox(
                                value: '${item.bedrooms}',
                                label: 'Bedrooms',
                              ),
                            if (item.bathrooms != null)
                              _DetailBox(
                                value: '${item.bathrooms}',
                                label: 'Bathrooms',
                              ),
                            if (item.sizeSqm != null)
                              _DetailBox(
                                value: '${item.sizeSqm}',
                                label: 'Size (sqm)',
                              ),
                            if (item.totalFloors != null)
                              _DetailBox(
                                value: '${item.totalFloors}',
                                label: 'Floors',
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    /// RENTAL DETAILS CARD
                    if (item.coldRent != null || item.warmRent != null || item.deposit != null) ...[
                      Text(
                        'Rental Information',
                        style: GoogleFonts.roboto(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F7FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF007BFF),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            if (item.coldRent != null)
                              _RentalRow(
                                label: 'Cold Rent (Base)',
                                value: '€${item.coldRent}',
                              ),
                            if (item.warmRent != null) ...[
                              Divider(color: Colors.grey[300]),
                              _RentalRow(
                                label: 'Warm Rent (Total)',
                                value: '€${item.warmRent}',
                                highlight: true,
                              ),
                            ],
                            if (item.additionalCosts != null) ...[
                              Divider(color: Colors.grey[300]),
                              _RentalRow(
                                label: 'Additional Costs',
                                value: '€${item.additionalCosts}',
                              ),
                            ],
                            if (item.deposit != null) ...[
                              Divider(color: Colors.grey[300]),
                              _RentalRow(
                                label: 'Deposit',
                                value: '€${item.deposit}',
                                highlight: true,
                              ),
                            ],
                            if (item.electricityIncluded ||
                                item.heatingIncluded ||
                                item.internetIncluded) ...[
                              const SizedBox(height: 12),
                              Divider(color: Colors.grey[300]),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  if (item.electricityIncluded)
                                    _InclusionBadge(label: '⚡ Electricity Included'),
                                  if (item.heatingIncluded)
                                    _InclusionBadge(label: '🔥 Heating Included'),
                                  if (item.internetIncluded)
                                    _InclusionBadge(label: '📶 Internet Included'),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    /// LOCATION HIGHLIGHTS
                    if (item.nearUniversity ||
                        item.nearSupermarket ||
                        item.nearHospital ||
                        item.nearPublicTransport) ...[
                      Text(
                        'Nearby Amenities',
                        style: GoogleFonts.roboto(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          if (item.nearUniversity)
                            _HighlightChip(icon: '🎓', label: 'Near University'),
                          if (item.nearSupermarket)
                            _HighlightChip(icon: '🛒', label: 'Near Supermarket'),
                          if (item.nearHospital)
                            _HighlightChip(icon: '🏥', label: 'Near Hospital'),
                          if (item.nearPublicTransport)
                            _HighlightChip(icon: '🚌', label: 'Near Transport'),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],

                    /// AMENITIES
                    if (item.amenities != null && item.amenities.isNotEmpty) ...[
                      Text(
                        'Amenities',
                        style: GoogleFonts.roboto(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: item.amenities
                            .map<Widget>(
                              (amenity) => Chip(
                                label: Text(
                                  amenity,
                                  style: const TextStyle(fontSize: 13),
                                ),
                                backgroundColor: const Color(0xFFF2F4F6),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 20),
                    ],

                    /// HIGHLIGHTS
                    if (item.highlights != null && item.highlights.isNotEmpty) ...[
                      Text(
                        'Key Highlights',
                        style: GoogleFonts.roboto(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: item.highlights
                            .map<Widget>(
                              (highlight) => Chip(
                                label: Text(
                                  '⭐ $highlight',
                                  style: const TextStyle(fontSize: 13),
                                ),
                                backgroundColor:
                                    const Color(0xFFE8F5E9),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 20),
                    ],

                    /// DESCRIPTION
                    if (item.description != null && item.description.isNotEmpty) ...[
                      Text(
                        'Description',
                        style: GoogleFonts.roboto(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6E6E6E),
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    /// GOOGLE MAPS BUTTON
                    if (item.latitude != null && item.longitude != null) ...[
                      const SizedBox(height: 20),
                      const Text(
                        'Location',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () async {
                          final url = Uri.parse(
                            'https://www.google.com/maps/dir/?api=1'
                            '&destination=${item.latitude},${item.longitude}',
                          );
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          }
                        },
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                'https://maps.googleapis.com/maps/api/staticmap'
                                '?center=${item.latitude},${item.longitude}&zoom=14&size=600x200'
                                '&markers=color:red%7C${item.latitude},${item.longitude}'
                                '&maptype=roadmap',
                                height: 160,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _FallbackMapTile(
                                  lat: item.latitude!,
                                  lon: item.longitude!,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 8,
                              right: 8,
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
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'Open in Maps',
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
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============ HELPER WIDGETS ============

class _CircleIcon extends StatelessWidget {
  final String iconAsset;
  final Color? iconColor;
  final VoidCallback? onTap;

  const _CircleIcon({required this.iconAsset, this.iconColor, this.onTap});

  @override
  Widget build(BuildContext context) {
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
}

class _DetailBox extends StatelessWidget {
  final String value;
  final String label;

  const _DetailBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF007BFF),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6E6E6E),
          ),
        ),
      ],
    );
  }
}

class _RentalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _RentalRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
              color: const Color(0xFF333333),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: highlight ? const Color(0xFF007BFF) : const Color(0xFF555555),
            ),
          ),
        ],
      ),
    );
  }
}

class _InclusionBadge extends StatelessWidget {
  final String label;

  const _InclusionBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFD4EDDA),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF28A745), width: 1),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF28A745),
        ),
      ),
    );
  }
}

class _HighlightChip extends StatelessWidget {
  final String icon;
  final String label;

  const _HighlightChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFC107), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }
}

class _FallbackMapTile extends StatelessWidget {
  final double lat;
  final double lon;

  const _FallbackMapTile({required this.lat, required this.lon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final url = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=$lat,$lon',
        );
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF4E7F6D)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/location.png',
              width: 36,
              height: 36,
              color: const Color(0xFF4E7F6D),
            ),
            const SizedBox(height: 8),
            Text(
              '${lat.toStringAsFixed(5)}, ${lon.toStringAsFixed(5)}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF6E6E6E)),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tap to open in Google Maps',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4E7F6D),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
