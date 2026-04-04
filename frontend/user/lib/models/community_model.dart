class CommunityPost {
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
  final String description;
  final String category;
  final String author;
  final String date;

  final List<String> keyPoints;
  final String officialWebsites;
  final String communityDiscussions;

  CommunityPost({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.author,
    required this.date,
    required this.keyPoints,
    required this.officialWebsites,
    required this.communityDiscussions,
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      author: json['author'] ?? '',
      date: json['date'] ?? '',

      keyPoints: _toStringList(json['keyPoints']),

      officialWebsites: json['officialWebsites'] ?? '',
      communityDiscussions: json['communityDiscussions'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'category': category,
      'author': author,
      'date': date,
      'keyPoints': keyPoints,
      'officialWebsites': officialWebsites,
      'communityDiscussions': communityDiscussions,
    };
  }
}