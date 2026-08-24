import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'models/second_hand_store_model.dart';
import 'widgets/optimized_image.dart';

class SecondHandStoreDetailsPage extends StatelessWidget {
  final SecondHandStoreItem item;

  const SecondHandStoreDetailsPage({super.key, required this.item});

  Future<void> _launchUrl(String scheme, String path) async {
    final Uri url = Uri(scheme: scheme, path: path);
    try {
      if (!await launchUrl(url)) {
        debugPrint('Could not launch $url');
      }
    } catch (e) {
      debugPrint('Launch error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Item Details',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.images.isNotEmpty) _buildImageCarousel()
            else _buildImagePlaceholder(),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (item.price.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4E7F6D).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.price,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4E7F6D),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Description'),
                  const SizedBox(height: 12),
                  Text(
                    item.description.isNotEmpty ? item.description : 'No description provided.',
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Delivery Option'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.local_shipping_outlined, color: Colors.blue, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.deliveryOption.isNotEmpty ? item.deliveryOption : 'Not specified',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 250,
      width: double.infinity,
      color: Colors.grey.shade200,
      child: Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
    );
  }

  Widget _buildImageCarousel() {
    return SizedBox(
      height: 280,
      child: PageView.builder(
        itemCount: item.images.length,
        itemBuilder: (context, index) {
          return OptimizedImage(
            imageUrl: item.images[index],
            fit: BoxFit.cover,
            width: double.infinity,
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildBottomActions() {
    final hasPhone = item.contactPhone.isNotEmpty;
    final hasEmail = item.contactEmail.isNotEmpty;

    if (!hasPhone && !hasEmail) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -4),
            blurRadius: 10,
          )
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (hasEmail)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _launchUrl('mailto', item.contactEmail),
                  icon: const Icon(Icons.email_outlined, size: 20),
                  label: const Text('Email'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4E7F6D),
                    side: const BorderSide(color: Color(0xFF4E7F6D)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            if (hasEmail && hasPhone) const SizedBox(width: 12),
            if (hasPhone)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _launchUrl('tel', item.contactPhone),
                  icon: const Icon(Icons.phone_outlined, size: 20),
                  label: const Text('Call Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4E7F6D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
