import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'models/job_model.dart';
import 'services/api_config.dart';
import 'saved_job_manager.dart';
import 'widgets/star_rating_widget.dart';
import 'widgets/rating_dialog.dart';
import 'services/rating_service.dart';
import 'models/rating_model.dart';

class JobDetailsPage extends StatefulWidget {
  final Job item;
  final VoidCallback? onRefresh;

  const JobDetailsPage({
    super.key,
    required this.item,
    this.onRefresh,
  });

  @override
  State<JobDetailsPage> createState() => _JobDetailsPageState();
}

class _JobDetailsPageState extends State<JobDetailsPage> {
  RatingStats? _ratingStats;
  late bool isSaved;

  @override
  void initState() {
    super.initState();
    isSaved = SavedJobManager.instance.isSaved(widget.item.id);
    _loadRatingStats();
  }

  Future<void> _loadRatingStats() async {
    final stats = await RatingService.getEntityRatingStats(
      entityId: widget.item.id,
      entityType: 'job',
    );
    setState(() {
      _ratingStats = stats;
    });
  }

  void _showRatingDialog() {
    showDialog(
      context: context,
      builder: (context) => RatingDialog(
        entityId: widget.item.id,
        entityType: 'job',
        entityName: widget.item.title,
        onRatingSubmitted: () {
          _loadRatingStats();
          if (widget.onRefresh != null) {
            widget.onRefresh!();
          }
        },
      ),
    );
  }
  Future<void> _toggleSave() async {
    final nowSaved = await SavedJobManager.instance.toggle(widget.item);
    if (!mounted) return;

    setState(() {
      isSaved = nowSaved;
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
  }

  Future<void> _makePhoneCall() async {
    if (widget.item.phone == null || widget.item.phone!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number not available'), backgroundColor: Colors.red),
      );
      return;
    }

    final Uri phoneUri = Uri(scheme: 'tel', path: widget.item.phone);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  Future<void> _applyNow() async {
    if (widget.item.applyUrl != null && widget.item.applyUrl!.isNotEmpty) {
      final Uri applyUri = Uri.parse(widget.item.applyUrl!);
      if (await canLaunchUrl(applyUri)) {
        await launchUrl(applyUri, mode: LaunchMode.externalApplication);
      }
    } else if (widget.item.email != null) {
      final Uri emailUri = Uri(scheme: 'mailto', path: widget.item.email);
      if (await canLaunchUrl(emailUri)) await launchUrl(emailUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application link not available'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Image.asset('assets/images/left-arrow.png', height: 22, width: 22, color: Colors.black),
        ),
        title: const Text("Job Details", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: const [],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Logo | (Title + Company) | (Share + Posted)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CompanyLogo(logoPathOrUrl: widget.item.companyLogo),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item.title,
                          maxLines: 2,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.item.company,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: _toggleSave,
                        icon: Image.asset(
                          'assets/images/bookmark.png',
                          height: 22,
                          width: 22,
                          color: isSaved ? const Color(0xFF4E7F6D) : Colors.black,
                        ),
                        iconSize: 22,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                        tooltip: 'Save',
                      ),
                      Text(
                        _postedAgo(widget.item.createdAt),
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Rating display
              if (_ratingStats != null && _ratingStats!.totalRatings > 0)
                Padding(
                  padding: const EdgeInsets.only(left: 58, bottom: 10),
                  child: Row(
                    children: [
                      StarRatingWidget(
                        rating: _ratingStats!.averageRating,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${_ratingStats!.averageRating.toStringAsFixed(1)} (${_ratingStats!.totalRatings} ratings)',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                ),

              // Row 3: Location (left), Salary (right)
              Row(
                children: [
                  Image.asset(
                    'assets/images/location.png',
                    width: 18,
                    height: 18,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _locationLine(widget.item),
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.item.salary != null && widget.item.salary!.trim().isNotEmpty)
                    Text(
                      widget.item.salary!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF4E7F6D),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (widget.item.description != null && widget.item.description!.trim().isNotEmpty) ...[
                const Text('Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(
                  widget.item.description!,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF444444), height: 1.5),
                ),
                const SizedBox(height: 16),
              ],
              if (widget.item.requirements.isNotEmpty) ...[
                const Text('Requirements', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                _PillWrap(items: widget.item.requirements),
                const SizedBox(height: 16),
              ],
              if (widget.item.benefits.isNotEmpty) ...[
                const Text('Benefits', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                _PillWrap(items: widget.item.benefits),
                const SizedBox(height: 20),
              ],
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _applyNow,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: const Color(0xFF4F7F67),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    'Apply Now',
                    style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}

String _postedAgo(DateTime? createdAt) {
  if (createdAt == null) return '';
  final diff = DateTime.now().difference(createdAt);
  if (diff.inMinutes < 60) return 'Posted ${diff.inMinutes} min ago';
  if (diff.inHours < 24) return 'Posted ${diff.inHours} hours ago';
  return 'Posted ${diff.inDays} days ago';
}

String _locationLine(Job job) {
  final parts = <String>[];
  if (job.city.trim().isNotEmpty) parts.add(job.city.trim());
  if ((job.state ?? '').trim().isNotEmpty) parts.add(job.state!.trim());
  if (parts.isNotEmpty) return parts.join(', ');
  return job.location;
}

class _PillWrap extends StatelessWidget {
  final List<String> items;

  const _PillWrap({required this.items});

  @override
  Widget build(BuildContext context) {
    final expandedItems = items
        .expand((value) => value.split(RegExp(r'[,;\n]')))
        .map((raw) => raw.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: expandedItems
          .map(
            (text) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                text,
                style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _CompanyLogo extends StatelessWidget {
  final String? logoPathOrUrl;

  const _CompanyLogo({required this.logoPathOrUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 60,
        width: 60,
        color: Colors.grey.shade200,
        child: () {
          final logo = logoPathOrUrl;
          if (logo != null && logo.isNotEmpty) {
            if (logo.startsWith('data:')) {
              try {
                final bytes = base64Decode(logo.split(',').last);
                return Image.memory(bytes, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Image.asset('assets/images/google.png', fit: BoxFit.cover));
              } catch (_) {
                return Image.asset('assets/images/google.png', fit: BoxFit.cover);
              }
            }
            final url = ApiConfig.getImageUrl(logo);
            return Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Image.asset('assets/images/google.png', fit: BoxFit.cover),
            );
          }
          return Image.asset('assets/images/google.png', fit: BoxFit.cover);
        }(),
      ),
    );
  }
}
