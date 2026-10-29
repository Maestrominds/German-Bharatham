import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileCardPreviewPage extends StatefulWidget {
  final String? photoBase64;
  final String name;
  final String? domain;
  final String? city;
  final String? motherTongue;
  final String? linkedinUrl;
  final String? instagramUrl;
  final bool isNewPhoto;

  const ProfileCardPreviewPage({
    super.key,
    required this.photoBase64,
    required this.name,
    this.domain,
    this.city,
    this.motherTongue,
    this.linkedinUrl,
    this.instagramUrl,
    this.isNewPhoto = false,
  });

  @override
  State<ProfileCardPreviewPage> createState() => _ProfileCardPreviewPageState();
}

class _ProfileCardPreviewPageState extends State<ProfileCardPreviewPage> {
  static const Color primaryGreen = Color(0xFF4E7F6D);
  static const Color bgColor = Color(0xFFF7F8FA);

  late String? _currentPhotoBase64;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _currentPhotoBase64 = widget.photoBase64;
  }

  ImageProvider? _resolveImageProvider(String? photo) {
    if (photo == null || photo.trim().isEmpty) return null;
    try {
      if (photo.startsWith('http')) {
        return NetworkImage(photo);
      } else {
        final raw = photo.contains(',') ? photo.split(',').last : photo;
        return MemoryImage(base64Decode(raw));
      }
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickAnotherPhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _currentPhotoBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to select image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageProvider = _resolveImageProvider(_currentPhotoBase64);
    final displayName = widget.name.trim().isNotEmpty ? widget.name.trim() : 'Your Name';
    final displayDomain = (widget.domain != null && widget.domain!.trim().isNotEmpty)
        ? widget.domain!.trim()
        : null;
    final displayCity = (widget.city != null && widget.city!.trim().isNotEmpty)
        ? widget.city!.trim()
        : null;
    final displayLanguage = (widget.motherTongue != null && widget.motherTongue!.trim().isNotEmpty)
        ? widget.motherTongue!.trim()
        : null;
    final displayLinkedin = (widget.linkedinUrl != null && widget.linkedinUrl!.trim().isNotEmpty)
        ? widget.linkedinUrl!.trim()
        : null;
    final displayInstagram = (widget.instagramUrl != null && widget.instagramUrl!.trim().isNotEmpty)
        ? widget.instagramUrl!.trim()
        : null;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context, null),
        ),
        title: const Text(
          'Card Preview',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top guidance message banner
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: primaryGreen.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryGreen.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.remove_red_eye_rounded, color: primaryGreen, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.isNewPhoto
                          ? 'Check how your photo looks inside the card. If it looks cropped or blurred, choose a clearer portrait photo.'
                          : 'This is how your profile appears to other members on the Connect screen.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Card Mockup matching user_profiles_page.dart card styling
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 420,
                      maxHeight: 560,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.10),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 56% height for profile image matching user card
                          Expanded(
                            flex: 56,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                imageProvider != null
                                    ? Image(
                                        image: imageProvider,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        color: Colors.grey.shade200,
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.person, size: 72, color: Colors.grey.shade400),
                                            const SizedBox(height: 8),
                                            Text(
                                              displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                                              style: TextStyle(
                                                fontSize: 32,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.grey.shade400,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 0,
                                  height: 36,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [Colors.transparent, Colors.black.withOpacity(0.06)],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // 44% height for profile info
                          Expanded(
                            flex: 44,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 21,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                  if (displayDomain != null) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      displayDomain,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: primaryGreen,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      if (displayCity != null)
                                        _infoChip(icon: Icons.location_on_rounded, label: displayCity),
                                      if (displayLanguage != null)
                                        _infoChip(icon: Icons.record_voice_over_rounded, label: displayLanguage),
                                    ],
                                  ),

                                  // LinkedIn Button
                                  if (displayLinkedin != null) ...[
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 36,
                                      child: ElevatedButton.icon(
                                        onPressed: () {},
                                        icon: const Icon(Icons.work_rounded, size: 15, color: Colors.white),
                                        label: const Text(
                                          'View LinkedIn Profile',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF0A66C2),
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],

                                  // Instagram Button
                                  if (displayInstagram != null) ...[
                                    const SizedBox(height: 6),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 36,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFF833AB4), Color(0xFFFD1D1D), Color(0xFFFCAF45)],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          ),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: ElevatedButton.icon(
                                          onPressed: () {},
                                          icon: const Icon(Icons.camera_alt_rounded, size: 15, color: Colors.white),
                                          label: const Text(
                                            'View Instagram Profile',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            shadowColor: Colors.transparent,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],

                                  const Spacer(),

                                  // Mock Skip / Like buttons
                                  Row(
                                    children: [
                                      Expanded(
                                        child: SizedBox(
                                          height: 42,
                                          child: OutlinedButton.icon(
                                            onPressed: null,
                                            icon: Icon(Icons.close_rounded, size: 16, color: Colors.grey.shade400),
                                            label: Text(
                                              'Skip',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13,
                                                color: Colors.grey.shade500,
                                              ),
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              backgroundColor: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: SizedBox(
                                          height: 42,
                                          child: ElevatedButton.icon(
                                            onPressed: null,
                                            icon: const Icon(Icons.favorite_border_rounded, size: 16, color: Colors.white),
                                            label: const Text(
                                              'Like',
                                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: primaryGreen.withOpacity(0.85),
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Actions Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: _pickAnotherPhoto,
                        icon: const Icon(Icons.photo_library_outlined, size: 18),
                        label: Text(
                          widget.isNewPhoto ? 'Choose Another' : 'Change Photo',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryGreen,
                          side: const BorderSide(color: primaryGreen, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context, _currentPhotoBase64);
                        },
                        icon: const Icon(Icons.check_rounded, size: 20),
                        label: Text(
                          widget.isNewPhoto ? 'Use This Photo' : 'Looks Good',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
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

  Widget _infoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: primaryGreen.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: primaryGreen, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: primaryGreen, fontWeight: FontWeight.w600, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

