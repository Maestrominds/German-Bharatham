class Job {
  // Safe helpers to avoid type errors during JSON parsing
  static String? _safeStr(dynamic val) {
    if (val == null) return null;
    final s = val.toString().trim();
    return s.isEmpty ? null : s;
  }

  static bool _safeBool(dynamic val, [bool def = false]) {
    if (val == null) return def;
    if (val is bool) return val;
    if (val is int) return val != 0;
    if (val is String) return val.toLowerCase() == 'true';
    return def;
  }

  static DateTime? _safeDate(dynamic val) {
    if (val == null) return null;
    if (val is String) {
      try { return DateTime.parse(val); } catch (_) { return null; }
    }
    if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
    return null;
  }

  static double _safeDouble(dynamic val, [double def = 0.0]) {
    if (val == null) return def;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? def;
    return def;
  }

  static int _safeInt(dynamic val, [int def = 0]) {
    if (val == null) return def;
    if (val is int) return val;
    if (val is double) return val.toInt();
    if (val is String) return int.tryParse(val) ?? def;
    return def;
  }

  static List<String> _toStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value
          .map((e) => e.toString())
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return [];
      return trimmed
          .split(RegExp(r'[,;\n]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return [];
  }

  final String id;
  final String title;
  final String category;
  final String company;
  final String? companyLogo;
  final String jobType; // Full-time, Part-time, Contract, Internship
  final String location;
  final String city;
  final String? state;
  final bool remote;
  final String? salary;
  final String? email;
  final String? website;
  final String? phone;
  final String? description;
  final List<String> requirements;
  final List<String> responsibilities;
  final List<String> benefits;
  final String? experience; // e.g., "2-5 years"
  final String? education;
  final String? applyUrl;
  final String status;
  final bool featured;
  final DateTime? expiresAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final double averageRating;
  final int totalRatings;

  Job({
    required this.id,
    required this.title,
    required this.category,
    required this.company,
    this.companyLogo,
    required this.jobType,
    required this.location,
    required this.city,
    this.state,
    required this.remote,
    this.salary,
    this.email,
    this.website,
    this.phone,
    this.description,
    this.requirements = const [],
    this.responsibilities = const [],
    this.benefits = const [],
    this.experience,
    this.education,
    this.applyUrl,
    this.status = 'Pending',
    this.featured = false,
    this.expiresAt,
    this.createdAt,
    this.updatedAt,
    this.averageRating = 0.0,
    this.totalRatings = 0,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: _safeStr(json['title']) ?? '',
      category: _safeStr(json['category']) ?? 'Job',
      company: _safeStr(json['company']) ?? _safeStr(json['companyName']) ?? '',
      companyLogo: _safeStr(json['companyLogo']),
      jobType: _safeStr(json['jobType']) ?? '',
      location: _safeStr(json['location']) ?? '',
      city: _safeStr(json['city']) ?? _safeStr(json['location']) ?? '',
      state: _safeStr(json['state']),
      remote: _safeBool(json['remote']),
      salary: _safeStr(json['salary']),
      email: _safeStr(json['email']),
      website: _safeStr(json['website']),
      phone: _safeStr(json['phone']) ?? _safeStr(json['contact']),
      description: _safeStr(json['description']),
      requirements: _toStringList(json['requirements']),
      responsibilities: _toStringList(json['responsibilities']),
      benefits: _toStringList(json['benefits']),
      experience: _safeStr(json['experience']),
      education: _safeStr(json['education']),
      applyUrl: _safeStr(json['applyUrl']),
      status: _safeStr(json['status']) ?? 'Active',
      featured: _safeBool(json['featured']),
      expiresAt: _safeDate(json['expiresAt']),
      createdAt: _safeDate(json['createdAt']),
      updatedAt: _safeDate(json['updatedAt']),
      averageRating: _safeDouble(json['averageRating']),
      totalRatings: _safeInt(json['totalRatings']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'category': category,
      'company': company,
      'companyLogo': companyLogo,
      'jobType': jobType,
      'location': location,
      'city': city,
      'state': state,
      'remote': remote,
      'salary': salary,
      'email': email,
      'website': website,
      'phone': phone,
      'description': description,
      'requirements': requirements,
      'responsibilities': responsibilities,
      'benefits': benefits,
      'experience': experience,
      'education': education,
      'applyUrl': applyUrl,
      'status': status,
      'featured': featured,
      'expiresAt': expiresAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
