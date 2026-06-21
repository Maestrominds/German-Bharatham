import 'package:flutter/material.dart';
import 'ui_common.dart';
import 'create_listing_form.dart';

class CreateListingCategoryPage extends StatelessWidget {
  const CreateListingCategoryPage({super.key});

  Widget _categoryCard(BuildContext context, String title, String iconPath, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: primaryGreen.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Image.asset(
            iconPath,
            width: 28,
            height: 28,
            color: primaryGreen,
            errorBuilder: (_, __, ___) => const Icon(Icons.list, color: primaryGreen, size: 28),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
        trailing: Image.asset(
          'assets/images/right-arrow.png',
          width: 18,
          height: 18,
          color: Colors.grey,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateListingFormPage(category: title),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: appBar(context, "Select Category"),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "What type of listing would you like to create?",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Select a category below to fill out the listing details. All submissions will be reviewed by the admin team.",
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          _categoryCard(
            context,
            "Accommodation",
            "assets/images/accommodation.png",
            "Find roommates or list apartments/shared spaces",
          ),
          _categoryCard(
            context,
            "Food",
            "assets/images/grocery-store.png",
            "Restaurants, grocery stores, cafes, and bakeries",
          ),
          _categoryCard(
            context,
            "Jobs",
            "assets/images/job-search.png",
            "Full-time, part-time, internship or contract job openings",
          ),
          _categoryCard(
            context,
            "Services",
            "assets/images/handshake.png",
            "Immigration, tax, coaching, IT or relocation services",
          ),
        ],
      ),
    );
  }
}
