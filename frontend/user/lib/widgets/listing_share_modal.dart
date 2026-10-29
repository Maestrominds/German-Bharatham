import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'optimized_image.dart';

class ListingShareModal {
  static void show({
    required BuildContext context,
    required String category, // 'jobs', 'accommodation', 'events', 'secondhand', 'services'
    required String id,
    required String title,
    String? subtitle,
    String? imageUrl,
    String? price,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ListingShareSheet(
        category: category,
        id: id,
        title: title,
        subtitle: subtitle,
        imageUrl: imageUrl,
        price: price,
      ),
    );
  }
}

class _ListingShareSheet extends StatefulWidget {
  final String category;
  final String id;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String? price;

  const _ListingShareSheet({
    required this.category,
    required this.id,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.price,
  });

  @override
  State<_ListingShareSheet> createState() => _ListingShareSheetState();
}

class _ListingShareSheetState extends State<_ListingShareSheet> {
  bool _copied = false;

  String get _shareUrl =>
      'https://germanbharatham.cloud/share/${widget.category.toLowerCase()}/${widget.id}';

  String get _shareText {
    final sub = (widget.subtitle ?? '').trim();
    final pr = (widget.price ?? '').trim();
    String details = widget.title;
    if (sub.isNotEmpty) details += '\n📍 $sub';
    if (pr.isNotEmpty) details += '\n💰 $pr';
    return 'Check out this on German Bharatham:\n$details\n\n🔗 $_shareUrl';
  }

  Future<void> _shareToWhatsApp() async {
    final encoded = Uri.encodeComponent(_shareText);
    final waUri = Uri.parse('whatsapp://send?text=$encoded');

    try {
      if (await canLaunchUrl(waUri)) {
        await launchUrl(waUri, mode: LaunchMode.externalApplication);
        if (mounted) Navigator.pop(context);
        return;
      }
    } catch (_) {}

    // Fallback: Web WhatsApp or system share
    final webWaUri = Uri.parse('https://api.whatsapp.com/send?text=$encoded');
    try {
      if (await canLaunchUrl(webWaUri)) {
        await launchUrl(webWaUri, mode: LaunchMode.externalApplication);
        if (mounted) Navigator.pop(context);
        return;
      }
    } catch (_) {}

    // Final fallback: Native system share
    if (mounted) Navigator.pop(context);
    Share.share(_shareText, subject: widget.title);
  }

  Future<void> _shareToInstagram() async {
    // Copy share link first
    await Clipboard.setData(ClipboardData(text: _shareUrl));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link copied! Paste it in your Instagram story or message.'),
          backgroundColor: Color(0xFFE1306C),
          duration: Duration(seconds: 3),
        ),
      );
    }

    // Attempt to open Instagram app
    final igUri = Uri.parse('instagram://app');
    try {
      if (await canLaunchUrl(igUri)) {
        await launchUrl(igUri, mode: LaunchMode.externalApplication);
      } else {
        final igWeb = Uri.parse('https://instagram.com');
        if (await canLaunchUrl(igWeb)) {
          await launchUrl(igWeb, mode: LaunchMode.externalApplication);
        }
      }
    } catch (_) {}

    if (mounted) Navigator.pop(context);
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: _shareUrl));
    setState(() => _copied = true);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Link copied to clipboard!'),
            ],
          ),
          backgroundColor: Color(0xFF4E7F6D),
          duration: Duration(seconds: 2),
        ),
      );
    }

    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) Navigator.pop(context);
  }

  void _shareMore() {
    Navigator.pop(context);
    Share.share(_shareText, subject: widget.title);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.only(top: 12, bottom: 28, left: 20, right: 20),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Drag Pill
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Modal Title
            const Text(
              'Share Listing',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),

            // Item Preview Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 54,
                      height: 54,
                      child: (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
                          ? OptimizedImage(
                              imageUrl: widget.imageUrl!,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: const Color(0xFFE6F4EA),
                              child: const Icon(
                                Icons.storefront_rounded,
                                color: Color(0xFF4E7F6D),
                                size: 28,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        if (widget.subtitle != null && widget.subtitle!.trim().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                        if (widget.price != null && widget.price!.trim().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.price!,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4E7F6D),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Social Action Buttons Row (WhatsApp, Instagram, Copy Link, More)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSocialAction(
                  icon: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.white, size: 26),
                  backgroundColor: const Color(0xFF25D366),
                  label: 'WhatsApp',
                  onTap: _shareToWhatsApp,
                ),
                _buildSocialAction(
                  icon: const FaIcon(FontAwesomeIcons.instagram, color: Colors.white, size: 26),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF833AB4), Color(0xFFFD1D1D), Color(0xFFFCAF45)],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  label: 'Instagram',
                  onTap: _shareToInstagram,
                ),
                _buildSocialAction(
                  icon: Icon(
                    _copied ? Icons.check_rounded : Icons.link_rounded,
                    color: _copied ? Colors.white : const Color(0xFF0F172A),
                    size: 26,
                  ),
                  backgroundColor: _copied ? const Color(0xFF4E7F6D) : const Color(0xFFF1F5F9),
                  label: _copied ? 'Copied!' : 'Copy Link',
                  onTap: _copyLink,
                ),
                _buildSocialAction(
                  icon: const Icon(Icons.more_horiz_rounded, color: Color(0xFF0F172A), size: 26),
                  backgroundColor: const Color(0xFFF1F5F9),
                  label: 'More',
                  onTap: _shareMore,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialAction({
    required Widget icon,
    Color? backgroundColor,
    Gradient? gradient,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: backgroundColor,
                gradient: gradient,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(child: icon),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

