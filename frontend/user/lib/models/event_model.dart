class EventSession {
  final String? date;
  final String? time;
  final String? label;
  final String? address;
  final String? language;
  final String? subtitles;
  final String? link;

  EventSession({
    this.date,
    this.time,
    this.label,
    this.address,
    this.language,
    this.subtitles,
    this.link,
  });

  factory EventSession.fromJson(Map<String, dynamic> json) {
    return EventSession(
      date: json['date']?.toString(),
      time: json['time']?.toString(),
      label: (json['label'] ?? json['cinema'] ?? json['slot'])?.toString(),
      address: json['address']?.toString(),
      language: json['language']?.toString(),
      subtitles: json['subtitles']?.toString(),
      link: (json['link'] ?? json['ticketUrl'] ?? json['url'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'date': date,
    'time': time,
    'label': label,
    'address': address,
    'language': language,
    'subtitles': subtitles,
    'link': link,
  };
}

class EventItem {
  final String id;
  final String title;
  final String? description;
  final String? shortDescription;
  final String category;
  final String format; // one_day, multi_day, course, workshop, screening, deadline
  final String? city;
  final String? venue;
  final String? address;
  final bool isOnline;
  final String? onlineLink;
  final String? organizer;
  final String? contact;
  final String? timeText;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final String? price;
  final String priceType; // free, paid, donation
  final String? priceText;
  final String? ticketUrl;
  final String? posterUrl;
  final List<String> images;
  final List<String> languages;
  final bool familyFriendly;
  final List<int> daysOfWeek;
  final bool ongoing;
  final String? level;
  final String? ageGroup;
  final List<EventSession> sessions;
  final String? subtitles;
  final String? cardDateLabel;
  final String status;
  final bool featured;
  final DateTime? createdAt;

  EventItem({
    required this.id,
    required this.title,
    this.description,
    this.shortDescription,
    this.category = 'festivals',
    this.format = 'one_day',
    this.city,
    this.venue,
    this.address,
    this.isOnline = false,
    this.onlineLink,
    this.organizer,
    this.contact,
    this.timeText,
    this.startsAt,
    this.endsAt,
    this.price,
    this.priceType = 'paid',
    this.priceText,
    this.ticketUrl,
    this.posterUrl,
    this.images = const [],
    this.languages = const [],
    this.familyFriendly = false,
    this.daysOfWeek = const [],
    this.ongoing = false,
    this.level,
    this.ageGroup,
    this.sessions = const [],
    this.subtitles,
    this.cardDateLabel,
    this.status = 'Active',
    this.featured = false,
    this.createdAt,
  });

  factory EventItem.fromJson(Map<String, dynamic> json) {
    List<String> parsedImages = [];
    if (json['images'] is List) {
      parsedImages = (json['images'] as List)
          .map((e) => e?.toString() ?? '')
          .where((s) => s.trim().isNotEmpty)
          .toList();
    } else if (json['media'] is Map && json['media']['images'] is List) {
      parsedImages = (json['media']['images'] as List)
          .map((e) => e?.toString() ?? '')
          .where((s) => s.trim().isNotEmpty)
          .toList();
    } else if (json['image'] != null && json['image'].toString().trim().isNotEmpty) {
      parsedImages = [json['image'].toString().trim()];
    }

    List<String> parsedLanguages = [];
    if (json['languages'] is List) {
      parsedLanguages = (json['languages'] as List)
          .map((e) => e?.toString() ?? '')
          .where((s) => s.trim().isNotEmpty)
          .toList();
    }

    List<int> parsedDays = [];
    if (json['daysOfWeek'] is List) {
      parsedDays = (json['daysOfWeek'] as List)
          .map((e) => int.tryParse(e?.toString() ?? ''))
          .whereType<int>()
          .toList();
    } else if (json['days_of_week'] is List) {
      parsedDays = (json['days_of_week'] as List)
          .map((e) => int.tryParse(e?.toString() ?? ''))
          .whereType<int>()
          .toList();
    }

    List<EventSession> parsedSessions = [];
    if (json['sessions'] is List) {
      parsedSessions = (json['sessions'] as List)
          .whereType<Map>()
          .map((m) => EventSession.fromJson(m.cast<String, dynamic>()))
          .toList();
    }

    DateTime? parseDate(dynamic d) {
      if (d == null) return null;
      try {
        return DateTime.parse(d.toString());
      } catch (_) {
        return null;
      }
    }

    final starts = parseDate(json['startsAt'] ?? json['start_date']);
    final ends = parseDate(json['endsAt'] ?? json['end_date']);

    return EventItem(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: (json['title'] ?? 'Untitled Event').toString(),
      description: json['description']?.toString(),
      shortDescription: (json['shortDescription'] ?? json['short_description'])?.toString(),
      category: (json['category'] ?? 'festivals').toString(),
      format: (json['format'] ?? 'one_day').toString(),
      city: json['city']?.toString(),
      venue: (json['venue'] ?? json['venue_name'])?.toString(),
      address: json['address']?.toString(),
      isOnline: json['isOnline'] == true || json['is_online'] == true || json['isOnline']?.toString() == 'true',
      onlineLink: (json['onlineLink'] ?? json['online_link'])?.toString(),
      organizer: (json['organizer'] ?? json['organizer_name'])?.toString(),
      contact: json['contact']?.toString(),
      timeText: (json['timeText'] ?? json['time_text'])?.toString(),
      startsAt: starts,
      endsAt: ends ?? starts,
      price: json['price']?.toString(),
      priceType: (json['priceType'] ?? json['price_type'] ?? 'paid').toString(),
      priceText: (json['priceText'] ?? json['price_text'])?.toString(),
      ticketUrl: (json['ticketUrl'] ?? json['externalUrl'] ?? json['link'])?.toString(),
      posterUrl: (json['posterUrl'] ?? json['poster_url'])?.toString(),
      images: parsedImages,
      languages: parsedLanguages,
      familyFriendly: json['familyFriendly'] == true || json['family_friendly'] == true,
      daysOfWeek: parsedDays,
      ongoing: json['ongoing'] == true || json['ongoing']?.toString() == 'true',
      level: json['level']?.toString(),
      ageGroup: (json['ageGroup'] ?? json['age_group'])?.toString(),
      sessions: parsedSessions,
      subtitles: json['subtitles']?.toString(),
      cardDateLabel: (json['cardDateLabel'] ?? json['card_date_label'])?.toString(),
      status: json['status']?.toString() ?? 'Active',
      featured: json['featured'] == true || json['featured']?.toString() == 'true',
      createdAt: parseDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'shortDescription': shortDescription,
      'category': category,
      'format': format,
      'city': city,
      'venue': venue,
      'address': address,
      'isOnline': isOnline,
      'onlineLink': onlineLink,
      'organizer': organizer,
      'contact': contact,
      'timeText': timeText,
      'startsAt': startsAt?.toIso8601String(),
      'endsAt': endsAt?.toIso8601String(),
      'price': price,
      'priceType': priceType,
      'priceText': priceText,
      'ticketUrl': ticketUrl,
      'posterUrl': posterUrl,
      'images': images,
      'languages': languages,
      'familyFriendly': familyFriendly,
      'daysOfWeek': daysOfWeek,
      'ongoing': ongoing,
      'level': level,
      'ageGroup': ageGroup,
      'sessions': sessions.map((s) => s.toJson()).toList(),
      'subtitles': subtitles,
      'status': status,
      'featured': featured,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
