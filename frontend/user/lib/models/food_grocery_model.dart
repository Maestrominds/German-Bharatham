import '../services/api_config.dart';

class FoodGrocery {
  static DateTime _safeParseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    final s = value.toString().trim();
    if (s.isEmpty || s.toLowerCase() == 'null') return DateTime.now();
    try {
      return DateTime.parse(s);
    } catch (_) {
      return DateTime.now();
    }
  }

  static List<String> _toStringList(dynamic value) {
    if (value == null) return const [];
    if (value is List) {
      return value
          .where((e) => e != null)
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return const [];
      return trimmed
          .split(RegExp(r'[,;\n]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const [];
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    final s = value.toString().trim();
    if (s.isEmpty || s.toLowerCase() == 'null') return 0.0;
    return double.tryParse(s) ?? 0.0;
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    final s = value.toString().trim();
    if (s.isEmpty || s.toLowerCase() == 'null') return 0;
    return int.tryParse(s) ?? 0;
  }

  static bool _toBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final s = value.toString().trim().toLowerCase();
    if (s == 'true' || s == '1' || s == 'yes') return true;
    if (s == 'false' || s == '0' || s == 'no') return false;
    return false;
  }

  static String _normalizeStatus(dynamic value) {
    final raw = (value ?? '').toString().trim();
    if (raw.isEmpty) return 'Pending';
    final lower = raw.toLowerCase();
    if (lower == 'active') return 'Active';
    if (lower == 'disabled' || lower == 'inactive') return 'Inactive';
    if (lower == 'pending') return 'Pending';
    return raw;
  }

  static String _firstImageFromMedia(dynamic media) {
    try {
      if (media is Map) {
        final images = media['images'];
        if (images is List && images.isNotEmpty) {
          final first = images.first;
          if (first == null) return '';
          if (first is String) return first;
          if (first is Map) {
            return (first['url'] ?? first['uri'] ?? '').toString();
          }
          return first.toString();
        }
      }
    } catch (_) {}
    return '';
  }

  static String _toAbsoluteImageUrl(String? value) {
    if (value == null) return '';
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('data:image')) return trimmed;
    if (trimmed.startsWith('assets/')) return trimmed;
    return ApiConfig.getImageUrl(trimmed);
  }

  final String id;
  final String title;
  final String category; // "Food"
  final String subCategory; // "Restaurant", "Grocery Store", etc.
  final String? type;
  final String location;
  final String address;
  final String city;
  final String? state;
  final String? zipCode;
  final String? phone;
  final String? email;
  final String? website;
  final String? description;
  final String? openingHours;
  final String? priceRange;
  final double rating;
  final List<String> cuisine;
  final List<String> specialties;
  final bool deliveryAvailable;
  final bool takeoutAvailable;
  final bool dineInAvailable;
  final bool cateringAvailable;
  final String? image;
  final double? latitude;
  final double? longitude;
  final String status;
  final double averageRating;
  final int totalRatings;
  final DateTime createdAt;
  final DateTime updatedAt;

  FoodGrocery({
    required this.id,
    required this.title,
    required this.category,
    required this.subCategory,
    this.type,
    required this.location,
    required this.address,
    required this.city,
    this.state,
    this.zipCode,
    this.phone,
    this.email,
    this.website,
    this.description,
    this.openingHours,
    this.priceRange,
    this.rating = 0.0,
    this.cuisine = const [],
    this.specialties = const [],
    this.deliveryAvailable = false,
    this.takeoutAvailable = false,
    this.dineInAvailable = false,
    this.cateringAvailable = false,
    this.image,
    this.latitude,
    this.longitude,
    this.status = 'Active',
    this.averageRating = 0.0,
    this.totalRatings = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FoodGrocery.fromJson(Map<String, dynamic> json) {
    final title = (json['title'] ?? json['name'] ?? json['restaurantName'] ?? '').toString();
    final category = (json['category'] ?? 'Food').toString();
    final subCategory = (json['subCategory'] ?? '').toString();
    final city = (json['city'] ?? '').toString();
    final address = (json['address'] ?? '').toString();
    final location = (json['location'] ?? '').toString();
    final phone = (json['phone'] ?? json['contactPhone'])?.toString();

    final mediaImage = _firstImageFromMedia(json['media']);
    final explicitImage = json['image']?.toString();
    final chosenImage = (explicitImage != null && explicitImage.trim().isNotEmpty) ? explicitImage : mediaImage;

    return FoodGrocery(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: title,
      category: category,
      subCategory: subCategory,
      type: json['type']?.toString(),
      location: location.isNotEmpty ? location : (address.isNotEmpty ? address : city),
      address: address,
      city: city,
      state: json['state']?.toString(),
      zipCode: json['zipCode']?.toString(),
      phone: phone,
      email: json['email']?.toString(),
      website: json['website']?.toString(),
      description: json['description']?.toString(),
      openingHours: json['openingHours']?.toString(),
      priceRange: json['priceRange']?.toString(),
      rating: _toDouble(json['rating']),
      cuisine: _toStringList(json['cuisine']),
      specialties: _toStringList(json['specialties']),
      deliveryAvailable: _toBool(json['deliveryAvailable']),
      takeoutAvailable: _toBool(json['takeoutAvailable']),
      dineInAvailable: _toBool(json['dineInAvailable']),
      cateringAvailable: _toBool(json['cateringAvailable']),
      image: chosenImage.trim().isEmpty ? null : _toAbsoluteImageUrl(chosenImage),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      status: _normalizeStatus(json['status'] ?? 'Active'),
      averageRating: _toDouble(json['averageRating']),
      totalRatings: _toInt(json['totalRatings']),
      createdAt: _safeParseDateTime(json['createdAt']),
      updatedAt: _safeParseDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'category': category,
      'subCategory': subCategory,
      'type': type,
      'location': location,
      'address': address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'phone': phone,
      'email': email,
      'website': website,
      'description': description,
      'openingHours': openingHours,
      'priceRange': priceRange,
      'rating': rating,
      'cuisine': cuisine,
      'specialties': specialties,
      'deliveryAvailable': deliveryAvailable,
      'takeoutAvailable': takeoutAvailable,
      'dineInAvailable': dineInAvailable,
      'cateringAvailable': cateringAvailable,
      'image': image,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'averageRating': averageRating,
      'totalRatings': totalRatings,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Helper method to get services as list
  List<String> get services {
    List<String> serviceList = [];
    if (deliveryAvailable) serviceList.add('Home Delivery');
    if (takeoutAvailable) serviceList.add('Takeout');
    // Add more based on your needs
    if (subCategory == 'Restaurant') serviceList.add('Dine-in');
    return serviceList;
  }
}