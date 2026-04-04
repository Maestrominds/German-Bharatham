import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'saved_guides_manager.dart';
import 'models/community_model.dart';

class GuideDetailsPage extends StatefulWidget {
  final CommunityPost guide;


  const GuideDetailsPage({
    super.key,
    required this.guide,
  });

  @override
  State<GuideDetailsPage> createState() => _GuideDetailsPageState();
}

class _GuideDetailsPageState extends State<GuideDetailsPage> {
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _checkSaved();
  }

  Future<void> _checkSaved() async {
    final saved = await SavedGuidesManager.instance.isSaved(widget.guide.id);
    if (mounted) {
      setState(() {
        _isSaved = saved;
      });
    }
  }

  Future<void> _toggleSave() async {
    await SavedGuidesManager.instance.toggle(widget.guide);
    await _checkSaved();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isSaved ? 'Removed from Saved' : 'Saved!'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Image.asset(
            'assets/images/left-arrow.png',
            height: 22,
            width: 22,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        title: const Text(
          "Guide Details",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6F2EC),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Text(
                          widget.guide.category,
                          style: const TextStyle(
                            color: Color(0xFF3B8F6A),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _toggleSave,
                        icon: Image.asset(
                          _isSaved
                              ? 'assets/images/bookmark.png'
                              : 'assets/images/bookmark.png',
                          // Use a different icon for saved/unsaved if available
                          height: 22,
                          width: 22,
                          color: _isSaved ? Colors.green : Colors.black,
                        ),
                        tooltip: _isSaved ? 'Remove from Saved' : 'Save',
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Text(
                    widget.guide.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    "${widget.guide.author} • ${widget.guide.date} • 5 min read",
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    widget.guide.description,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    "Key Points",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 17.5,
                    ),
                  ),

                  const SizedBox(height: 12),

                  ..._buildKeyPoints(widget.guide.keyPoints),

                  const SizedBox(height: 18),

                  const Text(
                    "External Resources",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 17.5,
                    ),
                  ),

                  const SizedBox(height: 12),

                  _resourceButton(
                    context: context,
                    url: widget.guide.officialWebsites,
                    image: Image.asset(
                      'assets/images/link.png',
                      width: 20,
                      height: 20,
                      color: Colors.white,
                    ),
                    text: "Official Government Website",
                  ),

                  const SizedBox(height: 12),

                  _resourceButton(
                    context: context,
                    url: widget.guide.communityDiscussions,
                    image: Image.asset(
                      'assets/images/link.png',
                      width: 20,
                      height: 20,
                      color: Colors.white,
                    ),
                    text: "Community Forum Discussion",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildKeyPoints(dynamic keyPointsData) {
    if (keyPointsData == null) {
      return [];
    }

    List<String> points = [];

    if (keyPointsData is List) {
      points = keyPointsData
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } else if (keyPointsData is String) {
      points = keyPointsData
          .split(';')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    if (points.isEmpty) {
      return [];
    }

    return points.map((point) => _pointTile(point)).toList();
  }

  Widget _pointTile(String text) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          height: 1.5,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _resourceButton({
    required BuildContext context,
    Widget? image,
    required String text,
    required String url,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: () async {
          if (url.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Link not available')),
            );
            return;
          }

          try {
            String urlToLaunch = url;

            if (!urlToLaunch.startsWith('http')) {
              urlToLaunch = 'https://$urlToLaunch';
            }

            final Uri uri = Uri.parse(urlToLaunch);

            bool launched = await launchUrl(
              uri,
              mode: LaunchMode.externalApplication,
            );

            if (!launched) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Could not open: $text')),
              );
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e')),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4F8F75),
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (image != null)
              SizedBox(width: 20, height: 20, child: image),
            const SizedBox(width: 10),
            Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}