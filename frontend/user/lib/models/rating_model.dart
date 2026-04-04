class Rating {
  final String id;
  final String userId;
  final String userName;
  final String userType;
  final String entityId;
  final String entityType;
  final int rating;
  final String review;
  final DateTime createdAt;
  final DateTime updatedAt;

  Rating({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userType,
    required this.entityId,
    required this.entityType,
    required this.rating,
    required this.review,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? 'Anonymous',
      userType: json['userType'] ?? 'guest',
      entityId: json['entityId'] ?? '',
      entityType: json['entityType'] ?? '',
      rating: json['rating'] ?? 0,
      review: json['review'] ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
    );
  }
}

class RatingStats {
  final double averageRating;
  final int totalRatings;
  final Map<int, int> distribution;

  RatingStats({
    required this.averageRating,
    required this.totalRatings,
    required this.distribution,
  });

  factory RatingStats.fromJson(Map<String, dynamic> json) {
    Map<int, int> dist = {};
    if (json['distribution'] != null) {
      final distData = json['distribution'] as Map<String, dynamic>;
      distData.forEach((key, value) {
        dist[int.parse(key)] = value as int;
      });
    }

    return RatingStats(
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      totalRatings: json['totalRatings'] ?? 0,
      distribution: dist,
    );
  }

  // Get percentage for a specific star rating
  double getPercentage(int stars) {
    if (totalRatings == 0) return 0.0;
    return ((distribution[stars] ?? 0) / totalRatings) * 100;
  }
}
