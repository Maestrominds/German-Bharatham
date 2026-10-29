class SecondHandStoreItem {
  final String id;
  final String title;
  final String description;
  final String price;
  final String contactPhone;
  final String contactEmail;
  final String deliveryOption;
  final String? link;
  final List<String> images;
  final String status;
  final String creatorType;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SecondHandStoreItem({
    required this.id,
    required this.title,
    this.description = '',
    this.price = '',
    this.contactPhone = '',
    this.contactEmail = '',
    this.deliveryOption = '',
    this.link,
    this.images = const [],
    this.status = 'Pending',
    this.creatorType = 'admin',
    this.createdAt,
    this.updatedAt,
  });

  factory SecondHandStoreItem.fromJson(Map<String, dynamic> json) {
    List<String> parseImages(dynamic imgData) {
      if (imgData == null) return [];
      if (imgData is List) {
        return imgData.map((e) => e.toString()).toList();
      }
      if (imgData is String) {
        if (imgData.trim().isEmpty) return [];
        if (imgData.contains(',')) {
          return imgData.split(',').map((e) => e.trim()).toList();
        }
        return [imgData];
      }
      return [];
    }

    return SecondHandStoreItem(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: json['title']?.toString() ?? 'No Title',
      description: json['description']?.toString() ?? '',
      price: json['price']?.toString() ?? '',
      contactPhone: json['contactPhone']?.toString() ?? '',
      contactEmail: json['contactEmail']?.toString() ?? '',
      deliveryOption: json['deliveryOption']?.toString() ?? '',
      link: (json['link'] ?? json['externalUrl'] ?? json['website'])?.toString(),
      images: parseImages(json['images']),
      status: json['status']?.toString() ?? 'Pending',
      creatorType: json['creatorType']?.toString() ?? 'admin',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    );
  }
}
