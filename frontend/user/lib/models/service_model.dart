import '../services/api_config.dart';

class Service {
  static DateTime? _tryParseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    final s = value.toString().trim();
    if (s.isEmpty || s.toLowerCase() == 'null') return null;
    try {
      return DateTime.parse(s);
    } catch (_) {
      return null;
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

  static String _normalizeStatus(dynamic value) {
    final raw = (value ?? '').toString().trim();
    if (raw.isEmpty) return 'Pending';
    final lower = raw.toLowerCase();
    if (lower == 'active') return 'Active';
    if (lower == 'disabled' || lower == 'inactive') return 'Inactive';
    if (lower == 'pending') return 'Pending';
    // If it's already like 'Active'/'Pending' keep as-is.
    return raw;
  }

  static String _toAbsoluteImageUrl(String? value) {
    if (value == null) return '';
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('data:image')) return trimmed;
    if (trimmed.startsWith('assets/')) return trimmed;
    return ApiConfig.getImageUrl(trimmed);
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    final s = value.toString().trim();
    if (s.isEmpty || s.toLowerCase() == 'null') return null;
    return double.tryParse(s);
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    final s = value.toString().trim();
    return int.tryParse(s) ?? 0;
  }

  static List<String> _imagesFromJson(Map<String, dynamic> json) {
    final direct = json['images'];
    if (direct is List && direct.isNotEmpty) {
      return direct
          .where((e) => e != null)
          .map((e) => _toAbsoluteImageUrl(e.toString()))
          .where((e) => e.isNotEmpty)
          .toList();
    }
    final media = json['media'];
    if (media is Map) {
      final images = media['images'];
      if (images is List && images.isNotEmpty) {
        return images
            .where((e) => e != null)
            .map((e) => _toAbsoluteImageUrl(e.toString()))
            .where((e) => e.isNotEmpty)
            .toList();
      }
    }
    final single = (json['image'] ?? _firstImageFromMedia(json['media']))?.toString();
    final abs = _toAbsoluteImageUrl(single);
    return abs.isEmpty ? const [] : [abs];
  }

  final String id;
  final String title;
  final String category;
  final String serviceType; // e.g., "Immigration", "Legal", "Financial", "Plumbing", "Cleaning"
  final String? provider; // Company or individual name
  final String? address;
  final String city;
  final String? state;
  final String? zipCode;
  final String? phone;
  final String? email;
  final String? website;
  final String? description;
  final String? pricing; // e.g., "Hourly", "Fixed Rate"
  final String? priceRange; // e.g., "$50-$100/hour"
  final String? availability;
  final List<String> servicesOffered;
  final List<String> certifications;
  final List<String> languages;
  final String? image;
  final List<String> images;
  final double? latitude;
  final double? longitude;
  final String? whatsapp;
  final double averageRating;
  final int totalRatings;
  final String status;
  final bool featured;
  final bool verified;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Service({
    required this.id,
    required this.title,
    required this.category,
    required this.serviceType,
    this.provider,
    this.address,
    required this.city,
    this.state,
    this.zipCode,
    this.phone,
    this.email,
    this.website,
    this.description,
    this.pricing,
    this.priceRange,
    this.availability,
    this.servicesOffered = const [],
    this.certifications = const [],
    this.languages = const [],
    this.image,
    this.images = const [],
    this.latitude,
    this.longitude,
    this.whatsapp,
    this.averageRating = 0.0,
    this.totalRatings = 0,
    this.status = 'Pending',
    this.featured = false,
    this.verified = false,
    this.createdAt,
    this.updatedAt,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    final mediaImage = _firstImageFromMedia(json['media']);
    final explicitImage = json['image']?.toString();
    final chosenImage = (explicitImage != null && explicitImage.trim().isNotEmpty) ? explicitImage : mediaImage;

    final title = (json['title'] ?? json['serviceName'] ?? json['name'] ?? '').toString();
    final provider = (json['provider'] ?? json['providerName'])?.toString();
    final phone = (json['phone'] ?? json['contactPhone'])?.toString();
    final images = _imagesFromJson(json);
    final servicesOffered = _toStringList(
      json['amenities'] ?? json['servicesOffered'] ?? json['services'] ?? json['offers'],
    );

    return Service(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: title,
      category: (json['category'] ?? 'Services').toString(),
      serviceType: (json['serviceType'] ?? json['type'] ?? '').toString(),
      provider: provider,
      address: (json['address'] ?? json['area'])?.toString(),
      city: (json['city'] ?? '').toString(),
      state: json['state']?.toString(),
      zipCode: (json['zipCode'] ?? json['postalCode'])?.toString(),
      phone: phone,
      whatsapp: json['whatsapp']?.toString(),
      email: json['email']?.toString(),
      website: json['website']?.toString(),
      description: json['description']?.toString(),
      pricing: json['pricing']?.toString(),
      priceRange: json['priceRange']?.toString(),
      availability: json['availability']?.toString(),
      servicesOffered: servicesOffered,
      certifications: _toStringList(json['certifications'] ?? json['certification']),
      languages: _toStringList(json['languages'] ?? json['language']),
      image: _toAbsoluteImageUrl(chosenImage),
      images: images,
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      averageRating: (_toDouble(json['averageRating']) ?? _toDouble(json['rating']) ?? 0.0),
      totalRatings: _toInt(json['totalRatings'] ?? json['ratingCount']),
      status: _normalizeStatus(json['status']),
      featured: json['featured'] ?? false,
      verified: json['verified'] ?? false,
      createdAt: _tryParseDateTime(json['createdAt']),
      updatedAt: _tryParseDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'category': category,
      'serviceType': serviceType,
      'provider': provider,
      'address': address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'phone': phone,
      'email': email,
      'website': website,
      'description': description,
      'pricing': pricing,
      'priceRange': priceRange,
      'availability': availability,
      'certifications': certifications,
      'languages': languages,
      'image': image,
      'images': images,
      'latitude': latitude,
      'longitude': longitude,
      'whatsapp': whatsapp,
      'averageRating': averageRating,
      'totalRatings': totalRatings,
      'status': status,
      'featured': featured,
      'verified': verified,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
