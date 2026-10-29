import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'models/event_model.dart';
import 'widgets/optimized_image.dart';
import 'widgets/listing_share_modal.dart';

class EventDetailsPage extends StatelessWidget {
  final EventItem event;

  const EventDetailsPage({super.key, required this.event});

  static const Color primaryGreen = Color(0xFF4E7F6D);
  static const Color bgColor = Color(0xFFF7F8FA);

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return 'TBA';
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final day = dt.day.toString().padLeft(2, '0');
    final month = months[dt.month - 1];
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day $month $year • $hour:$minute';
  }

  void _openUrl(BuildContext context, String url) async {
    String cleaned = url.trim();
    if (!cleaned.startsWith('http://') && !cleaned.startsWith('https://')) {
      cleaned = 'https://$cleaned';
    }
    final uri = Uri.tryParse(cleaned);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link')),
        );
      }
    }
  }

  void _openDirections(BuildContext context, String query) async {
    final mapUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}');
    try {
      if (await canLaunchUrl(mapUri)) {
        await launchUrl(mapUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  void _addToCalendar(BuildContext context, {DateTime? start, DateTime? end, String? title, String? location}) async {
    final s = start ?? event.startsAt ?? DateTime.now();
    final e = end ?? event.endsAt ?? s.add(const Duration(hours: 2));
    final t = title ?? event.title;
    final loc = location ?? event.address ?? event.venue ?? event.city ?? 'Germany';

    final startTime = s.toUtc().toIso8601String().replaceAll('-', '').replaceAll(':', '').split('.').first + 'Z';
    final endTime = e.toUtc().toIso8601String().replaceAll('-', '').replaceAll(':', '').split('.').first + 'Z';

    final gcalUrl =
        'https://calendar.google.com/calendar/render?action=TEMPLATE&text=${Uri.encodeComponent(t)}&dates=$startTime/$endTime&details=${Uri.encodeComponent(event.shortDescription ?? event.description ?? '')}&location=${Uri.encodeComponent(loc)}';
    final uri = Uri.parse(gcalUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  void _shareEvent(BuildContext context) {
    ListingShareModal.show(
      context: context,
      category: 'events',
      id: event.id,
      title: event.title,
      subtitle: event.city ?? (event.isOnline ? 'Online' : 'Germany'),
      imageUrl: event.posterUrl ?? (event.images.isNotEmpty ? event.images.first : null),
      price: event.priceText ?? event.price,
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = event.images.isNotEmpty
        ? event.images
        : (event.posterUrl != null ? [event.posterUrl!] : <String>[]);
    final hasImages = images.isNotEmpty;

    final isScreening = event.format == 'screening' || event.category.toLowerCase() == 'movies';
    final isCourse = event.format == 'course' || event.category.toLowerCase() == 'classes';
    final hasSessions = event.sessions.isNotEmpty;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          event.title,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: primaryGreen),
            onPressed: () => _shareEvent(context),
            tooltip: 'Share Event',
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Header
            if (hasImages)
              SizedBox(
                height: 240,
                width: double.infinity,
                child: PageView.builder(
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    return OptimizedImage(
                      imageUrl: images[index],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 240,
                    );
                  },
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges: Category, Online, Family Friendly
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5F0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          event.category.toUpperCase(),
                          style: const TextStyle(color: primaryGreen, fontWeight: FontWeight.w700, fontSize: 11),
                        ),
                      ),
                      if (event.isOnline)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDBEAFE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('ONLINE EVENT', style: TextStyle(color: Color(0xFF1D4ED8), fontWeight: FontWeight.w700, fontSize: 11)),
                        ),
                      if (event.familyFriendly)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('FAMILY FRIENDLY', style: TextStyle(color: Color(0xFFB45309), fontWeight: FontWeight.w700, fontSize: 11)),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Title
                  Text(
                    event.title,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),

                  if (event.shortDescription != null && event.shortDescription!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      event.shortDescription!,
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.4),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Info Card (Date, Venue, Price, Organizer)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Date & Time',
                          value: event.cardDateLabel ?? _formatDateTime(event.startsAt),
                          subValue: (event.timeText != null && event.timeText!.isNotEmpty) ? event.timeText : null,
                        ),
                        const Divider(height: 24),
                        _buildInfoRow(
                          icon: event.isOnline ? Icons.wifi : Icons.place_outlined,
                          label: 'Location',
                          value: event.isOnline
                              ? 'Online (Virtual)'
                              : (event.venue ?? event.city ?? 'Germany'),
                          subValue: event.address,
                        ),
                        if (event.languages.isNotEmpty) ...[
                          const Divider(height: 24),
                          _buildInfoRow(
                            icon: Icons.language_outlined,
                            label: 'Languages',
                            value: event.languages.join(', '),
                          ),
                        ],
                        const Divider(height: 24),
                        _buildInfoRow(
                          icon: Icons.payments_outlined,
                          label: 'Admission',
                          value: event.priceType == 'free'
                              ? 'Free Admission'
                              : (event.priceText ?? event.price ?? 'Paid'),
                        ),
                        if (event.organizer != null && event.organizer!.isNotEmpty) ...[
                          const Divider(height: 24),
                          _buildInfoRow(
                            icon: Icons.person_outline,
                            label: 'Organizer',
                            value: event.organizer!,
                            subValue: event.contact,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Course Info Section
                  if (isCourse) ...[
                    const SizedBox(height: 20),
                    const Text('Course Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                      child: Column(
                        children: [
                          if (event.level != null)
                            _buildSimpleDetail('Level', event.level!.toUpperCase()),
                          if (event.ageGroup != null)
                            _buildSimpleDetail('Age Group', event.ageGroup!.toUpperCase()),
                          if (event.ongoing)
                            _buildSimpleDetail('Format', 'Ongoing (Join anytime)'),
                        ],
                      ),
                    ),
                  ],

                  // Sessions / Showtimes Table
                  if (hasSessions) ...[
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isScreening ? '🎬 Showtimes & Cinemas' : '🕒 Available Time Slots',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '${event.sessions.length} session${event.sessions.length > 1 ? 's' : ''}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...event.sessions.map((session) => _buildSessionCard(context, session)),
                  ],

                  // Full Description
                  if (event.description != null && event.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'About This Event',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                      child: Text(
                        event.description!,
                        style: const TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF334155)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    String? subValue,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: primaryGreen),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
              if (subValue != null && subValue.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(subValue, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: primaryGreen)),
        ],
      ),
    );
  }

  Widget _buildSessionCard(BuildContext context, EventSession session) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.label ?? 'Session',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                if (session.date != null || session.time != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    [session.date, session.time].whereType<String>().join(' · '),
                    style: const TextStyle(color: primaryGreen, fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ],
                if (session.address != null && session.address!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(session.address!, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                ],
                if (session.language != null || session.subtitles != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (session.language != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
                          child: Text(session.language!, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                        ),
                      if (session.subtitles != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(4)),
                          child: Text('Sub: ${session.subtitles}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFFB45309))),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (session.address != null && session.address!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.directions, color: primaryGreen),
              tooltip: 'Directions',
              onPressed: () => _openDirections(context, session.address!),
            ),
          if (session.link != null && session.link!.isNotEmpty)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => _openUrl(context, session.link!),
              child: const Text('Book', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final hasAddress = (event.address != null && event.address!.isNotEmpty) ||
        (event.venue != null && event.venue!.isNotEmpty);
    final link = event.ticketUrl ?? event.onlineLink;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Row(
        children: [
          // Add to Calendar
          IconButton(
            icon: const Icon(Icons.event_available, color: primaryGreen),
            tooltip: 'Add to Calendar',
            onPressed: () => _addToCalendar(context),
          ),

          // Directions (if in-person)
          if (hasAddress && !event.isOnline)
            IconButton(
              icon: const Icon(Icons.directions, color: primaryGreen),
              tooltip: 'Get Directions',
              onPressed: () => _openDirections(context, event.address ?? event.venue ?? event.city!),
            ),

          const SizedBox(width: 8),

          // Primary Action Button (Tickets / Register)
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  if (link != null && link.isNotEmpty) {
                    _openUrl(context, link);
                  } else {
                    _shareEvent(context);
                  }
                },
                child: Text(
                  link != null && link.isNotEmpty
                      ? (event.priceType == 'free' ? 'Register / RSVP' : 'Book Tickets')
                      : 'Share Event',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
