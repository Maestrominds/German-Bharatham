import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'models/job_model.dart';
import 'services/api_config.dart';
import 'saved_job_manager.dart';
import 'widgets/star_rating_widget.dart';
import 'widgets/rating_dialog.dart';
import 'widgets/optimized_image.dart';
import 'widgets/listing_share_modal.dart';
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

  Future<void> _applyNow() async {
    String url = (widget.item.applyUrl ?? '').trim();
    if (url.isNotEmpty) {
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'https://$url';
      }
      final Uri applyUri = Uri.parse(url);
      if (await canLaunchUrl(applyUri)) {
        await launchUrl(applyUri, mode: LaunchMode.externalApplication);
      } else {
        try {
          await launchUrl(applyUri, mode: LaunchMode.externalApplication);
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not open application URL'), backgroundColor: Colors.red),
            );
          }
        }
      }
      return;
    }

    final email = (widget.item.email ?? (widget.item.phone?.contains('@') == true ? widget.item.phone : '') ?? '').trim();
    if (email.isNotEmpty) {
      final Uri emailUri = Uri(scheme: 'mailto', path: email);
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
        return;
      }
    }

    final phone = (widget.item.phone ?? '').trim();
    if (phone.isNotEmpty && !phone.contains('@')) {
      final Uri phoneUri = Uri(scheme: 'tel', path: phone);
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
        return;
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No application link or contact method provided'), backgroundColor: Colors.orange),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Color(0xFF4E7F6D)),
            onPressed: () {
              ListingShareModal.show(
                context: context,
                category: 'jobs',
                id: widget.item.id,
                title: widget.item.title,
                subtitle: widget.item.company + (widget.item.location.isNotEmpty ? ' • ${widget.item.location}' : ''),
                imageUrl: widget.item.companyLogo,
                price: widget.item.salary,
              );
            },
            tooltip: 'Share Job',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Logo | (Title + Company) | (Save + Posted)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CompanyLogo(logoPathOrUrl: widget.item.companyLogo),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Fully expandable title without truncation or "..."
                        Text(
                          widget.item.title,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black),
                        ),
                        if (widget.item.company.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.item.company.trim(),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                          ),
                        ],
                        if (widget.item.jobType.trim().isNotEmpty || (widget.item.domain != null && widget.item.domain!.trim().isNotEmpty)) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              if (widget.item.jobType.trim().isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5F0),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: const Color(0xFF4E7F6D).withOpacity(0.4)),
                                  ),
                                  child: Text(
                                    widget.item.jobType.trim(),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF4E7F6D),
                                    ),
                                  ),
                                ),
                              if (widget.item.domain != null && widget.item.domain!.trim().isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Text(
                                    widget.item.domain!.trim(),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF374151),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
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
                      if (widget.item.createdAt != null)
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

              // Location and Salary Row (Hidden completely if neither is provided)
              (() {
                final loc = _locationLine(widget.item).trim();
                final hasLoc = loc.isNotEmpty;
                final hasSalary = widget.item.salary != null && widget.item.salary!.trim().isNotEmpty;

                if (!hasLoc && !hasSalary) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hasLoc) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Image.asset(
                            'assets/images/location.png',
                            width: 16,
                            height: 16,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            loc,
                            style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.3),
                          ),
                        ),
                      ] else ...[
                        const Spacer(),
                      ],
                      if (hasSalary) ...[
                        const SizedBox(width: 8),
                        Text(
                          widget.item.salary!.trim(),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF4E7F6D),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              })(),

              if (widget.item.description != null && widget.item.description!.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(
                  widget.item.description!,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF444444), height: 1.5),
                ),
                const SizedBox(height: 16),
              ],

              if (widget.item.phone != null && widget.item.phone!.trim().isNotEmpty) ...[
                (() {
                  final isEmail = widget.item.phone!.contains('@');
                  final label = isEmail ? 'Contact Email' : 'Contact Phone';
                  final icon = isEmail ? Icons.mail_outline : Icons.phone_outlined;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          final value = widget.item.phone!.trim();
                          if (isEmail) {
                            final Uri emailUri = Uri(scheme: 'mailto', path: value);
                            if (await canLaunchUrl(emailUri)) {
                              await launchUrl(emailUri);
                            }
                          } else {
                            final Uri phoneUri = Uri(scheme: 'tel', path: value);
                            if (await canLaunchUrl(phoneUri)) {
                              await launchUrl(phoneUri);
                            }
                          }
                        },
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(icon, color: const Color(0xFF4E7F6D), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.item.phone!.trim(),
                                style: const TextStyle(
                                  fontSize: 14, 
                                  color: Color(0xFF4E7F6D), 
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                })(),
                const SizedBox(height: 16),
              ],

              if (widget.item.requirements.any((r) => r.trim().isNotEmpty)) ...[
                const Text('Requirements', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                _PillWrap(items: widget.item.requirements),
                const SizedBox(height: 16),
              ],

              if (widget.item.benefits.any((b) => b.trim().isNotEmpty)) ...[
                const Text('Benefits', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                _PillWrap(items: widget.item.benefits),
                const SizedBox(height: 20),
              ],

              // Apply / Contact Button (Hidden if no apply URL, email, or phone is provided)
              (() {
                final hasApplyUrl = (widget.item.applyUrl ?? '').trim().isNotEmpty;
                final hasEmail = (widget.item.email ?? (widget.item.phone?.contains('@') == true ? widget.item.phone : '') ?? '').trim().isNotEmpty;
                final hasPhone = (widget.item.phone ?? '').trim().isNotEmpty && !widget.item.phone!.contains('@');

                if (!hasApplyUrl && !hasEmail && !hasPhone) {
                  return const SizedBox.shrink();
                }

                String buttonLabel = 'Apply Now';
                IconData buttonIcon = Icons.arrow_forward;
                if (!hasApplyUrl) {
                  if (hasEmail) {
                    buttonLabel = 'Email Employer';
                    buttonIcon = Icons.email_outlined;
                  } else if (hasPhone) {
                    buttonLabel = 'Call Employer';
                    buttonIcon = Icons.phone_outlined;
                  }
                }

                return SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _applyNow,
                    icon: Icon(buttonIcon, color: Colors.white, size: 20),
                    label: Text(
                      buttonLabel,
                      style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0xFF4F7F67),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                );
              })(),
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
  if (job.country.trim().isNotEmpty && !parts.contains(job.country.trim())) parts.add(job.country.trim());
  if (parts.isNotEmpty) return parts.join(', ');
  return job.location.trim();
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
          Widget buildFallback() {
            return Container(
              color: Colors.grey.shade200,
              child: const Center(
                child: Icon(Icons.work, color: Colors.grey),
              ),
            );
          }

          final logo = logoPathOrUrl;
          if (logo != null && logo.isNotEmpty) {
            if (logo.startsWith('data:')) {
              try {
                final bytes = base64Decode(logo.split(',').last);
                return Image.memory(
                  bytes,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => buildFallback(),
                );
              } catch (_) {
                return buildFallback();
              }
            }
            final url = ApiConfig.getImageUrl(logo);
            return OptimizedImage(
              imageUrl: url,
              fit: BoxFit.cover,
              errorWidget: buildFallback(),
              placeholder: buildFallback(),
            );
          }
          return buildFallback();
        }(),
      ),
    );
  }
}
