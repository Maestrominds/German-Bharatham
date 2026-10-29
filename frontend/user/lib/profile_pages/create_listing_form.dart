import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../user_session.dart';
import '../services/api_config.dart';
import 'ui_common.dart';
import 'personal_info.dart' show SearchableDropdownInput;
import 'package:flutter/services.dart';

class CreateListingFormPage extends StatefulWidget {
  final String category;
  final Map<String, dynamic>? initialData; // If editing

  const CreateListingFormPage({
    super.key,
    required this.category,
    this.initialData,
  });

  @override
  State<CreateListingFormPage> createState() => _CreateListingFormPageState();
}

class _CreateListingFormPageState extends State<CreateListingFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  bool _submitting = false;

  // NEW: track picked image files directly - no base64 conversion
  List<XFile> _imageFiles = [];
  // Keep existing image URLs when editing (already uploaded to Cloudinary)
  List<String> _existingImageUrls = [];

  // Controllers
  final Map<String, TextEditingController> _controllers = {};

  // Form selections (dropdowns / checkboxes / lists)
  String _propertyType = 'apartment';
  String _subCategory = 'Restaurant';
  String _priceRange = '€€';
  String _jobType = 'Full Time';
  String _serviceType = 'Immigration';
  String _servicePriceRange = '€€';
  String _deliveryOption = 'Shipping Possible';

  // Event category selections
  String _eventFormat = 'one_day';
  String _eventCategory = 'festivals';
  String _eventPriceType = 'paid';
  bool _eventIsOnline = false;
  bool _eventFamilyFriendly = false;
  bool _eventOngoing = false;
  String _eventLevel = 'all';
  String _eventAgeGroup = 'all';
  final List<int> _eventDaysOfWeek = [];

  static const List<Map<String, String>> _eventFormats = [
    {'value': 'one_day', 'label': 'One-day Event (Festival, Concert, Meetup)'},
    {'value': 'multi_day', 'label': 'Multi-day (3-day mela or festival)'},
    {'value': 'course', 'label': 'Course / Class (Weekly classes, ongoing)'},
    {'value': 'workshop', 'label': 'Workshop (1–3 sessions, required)'},
    {'value': 'screening', 'label': 'Movie Screening (Cinema showtimes)'},
    {'value': 'deadline', 'label': 'Deadline (Contest, Call for entries)'},
  ];

  static const List<Map<String, String>> _eventCategories = [
    {'value': 'festivals', 'label': 'Festivals & Celebrations'},
    {'value': 'movies', 'label': 'Movies & Screenings'},
    {'value': 'performing_arts', 'label': 'Music, Dance & Theatre'},
    {'value': 'classes', 'label': 'Classes & Workshops'},
    {'value': 'food', 'label': 'Food Events'},
    {'value': 'markets', 'label': 'Melas & Markets'},
    {'value': 'sports', 'label': 'Sports & Outdoors'},
    {'value': 'meetups', 'label': 'Meetups & Networking'},
    {'value': 'religious', 'label': 'Religious & Spiritual'},
    {'value': 'contests', 'label': 'Contests & Calls'},
    {'value': 'other', 'label': 'Other'},
  ];

  static const List<Map<String, String>> _eventPriceTypes = [
    {'value': 'paid', 'label': 'Paid'},
    {'value': 'free', 'label': 'Free Admission'},
    {'value': 'donation', 'label': 'Donation / Pay What You Want'},
  ];

  // Checkboxes for Food category
  bool _dineInAvailable = false;
  bool _deliveryAvailable = false;
  bool _takeoutAvailable = false;
  bool _cateringAvailable = false;

  // Multi-select for Accommodation amenities
  final List<String> _accommodationAmenities = [];
  final List<String> _amenityOpts = [
    'Balcony', 'Terrace', 'Garden', 'Lift', 'Parking', 'Garage', 'Cellar', 
    'Washing Machine', 'Dishwasher', 'Kitchen', 'Pets Allowed', 
    'Smoking Allowed', 'Anmeldung Possible', 'Student Friendly', 'Wheelchair Accessible'
  ];


  final TextEditingController _cuisineInputCtrl = TextEditingController();
  final TextEditingController _specialtyInputCtrl = TextEditingController();

  List<String> _domainOptions = [
    'IT / Technology',
    'Computer Science / Software',
    'Biotechnology / Life Sciences',
    'Healthcare / Medicine',
    'Finance / Banking',
    'Mechanical / Automotive',
    'Electrical / Electronics',
    'Engineering / Manufacturing',
    'Marketing / Sales',
    'Business / Management',
    'Legal / Law',
    'Education / Academia',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _initFields();
    _fetchDropdownOptions();
  }

  Future<void> _fetchDropdownOptions() async {
    try {
      final res = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/api/profile-options'))
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (!mounted) return;
        if (data['domains'] is List) {
          final list = (data['domains'] as List)
              .map((e) => e is Map ? e['name']?.toString().trim() ?? '' : e.toString().trim())
              .where((name) => name.isNotEmpty)
              .toList();
          if (list.isNotEmpty) {
            setState(() {
              _domainOptions = list;
            });
          }
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _controllers.values.forEach((c) => c.dispose());
    _cuisineInputCtrl.dispose();
    _specialtyInputCtrl.dispose();
    super.dispose();
  }

  void _initFields() {
    // Determine fields based on category
    final data = widget.initialData;

    if (widget.category == 'Accommodation') {
      _controllers['title'] = TextEditingController(text: data?['title']?.toString() ?? '');
      _controllers['city'] = TextEditingController(text: data?['city']?.toString() ?? '');
      _controllers['postalCode'] = TextEditingController(text: (data?['postalCode'] ?? data?['zipCode'])?.toString() ?? '');
      _controllers['area'] = TextEditingController(text: data?['state']?.toString() ?? '');
      _controllers['address'] = TextEditingController(text: data?['address']?.toString() ?? '');
      _controllers['contactPhone'] = TextEditingController(text: (data?['contactPhone'] ?? data?['phone'])?.toString() ?? '');
      _controllers['link'] = TextEditingController(text: (data?['website'] ?? data?['externalUrl'] ?? data?['link'])?.toString() ?? '');
      _controllers['description'] = TextEditingController(text: data?['description']?.toString() ?? '');
      _controllers['coldRent'] = TextEditingController(text: data?['rentDetails']?['coldRent']?.toString() ?? '');
      _controllers['warmRent'] = TextEditingController(text: data?['rentDetails']?['warmRent']?.toString() ?? '');
      _controllers['deposit'] = TextEditingController(text: data?['rentDetails']?['deposit']?.toString() ?? '');
      _controllers['sizeSqm'] = TextEditingController(text: data?['propertyDetails']?['sizeSqm']?.toString() ?? '');
      _controllers['bedrooms'] = TextEditingController(text: data?['propertyDetails']?['bedrooms']?.toString() ?? '');
      _controllers['bathrooms'] = TextEditingController(text: data?['propertyDetails']?['bathrooms']?.toString() ?? '');
      
      _propertyType = data?['propertyType'] ?? 'apartment';

      // Load existing image URLs when editing
      final List<dynamic> initImgs = data?['media']?['images'] ?? [];
      _existingImageUrls = List<String>.from(initImgs.whereType<String>().where((s) => s.startsWith('http')));

      // Load amenities
      final Map<String, dynamic> initAmenities = data?['amenities'] ?? {};
      initAmenities.forEach((k, v) {
        if (v == true) {
          // Capitalize first letter and split CamelCase
          final displayName = k.replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(0)}');
          final capitalized = displayName[0].toUpperCase() + displayName.substring(1);
          _accommodationAmenities.add(capitalized);
        }
      });
    } else if (widget.category == 'Jobs') {
      _controllers['title'] = TextEditingController(text: data?['title']?.toString() ?? '');
      _controllers['location'] = TextEditingController(text: data?['location']?.toString() ?? '');
      _controllers['country'] = TextEditingController(text: data?['country']?.toString() ?? 'Germany');
      _controllers['domain'] = TextEditingController(text: (data?['domain'] ?? data?['industry'])?.toString() ?? '');
      _controllers['contact'] = TextEditingController(text: (data?['contact'] ?? data?['phone'])?.toString() ?? '');
      _controllers['description'] = TextEditingController(text: data?['description']?.toString() ?? '');
      _controllers['salary'] = TextEditingController(text: data?['salary']?.toString() ?? '');
      _controllers['companyName'] = TextEditingController(text: (data?['company'] ?? data?['companyName'])?.toString() ?? '');
      
      final reqs = data?['requirements'];
      _controllers['requirements'] = TextEditingController(
        text: (reqs is List) ? reqs.join(', ') : (reqs?.toString() ?? ''),
      );
      
      final bens = data?['benefits'];
      _controllers['benefits'] = TextEditingController(
        text: (bens is List) ? bens.join(', ') : (bens?.toString() ?? ''),
      );
      
      _controllers['applyUrl'] = TextEditingController(text: data?['applyUrl'] ?? '');

      _jobType = data?['jobType'] ?? data?['type'] ?? 'Full Time';
      if (data?['companyLogo'] != null && (data!['companyLogo'] as String).startsWith('http')) {
        _existingImageUrls = [data!['companyLogo']];
      }
    } 
    else if (widget.category == 'Services' || widget.category == 'Expat Services') {
      _controllers['serviceName'] = TextEditingController(text: (data?['serviceName'] ?? data?['title'])?.toString() ?? '');
      _controllers['providerName'] = TextEditingController(text: data?['providerName']?.toString() ?? '');
      _controllers['city'] = TextEditingController(text: data?['city']?.toString() ?? '');
      _controllers['postalCode'] = TextEditingController(text: data?['postalCode']?.toString() ?? '');
      _controllers['area'] = TextEditingController(text: data?['area']?.toString() ?? '');
      _controllers['address'] = TextEditingController(text: data?['address']?.toString() ?? '');
      _controllers['contactPhone'] = TextEditingController(text: (data?['contactPhone'] ?? data?['phone'])?.toString() ?? '');
      _controllers['whatsapp'] = TextEditingController(text: data?['whatsapp']?.toString() ?? '');
      _controllers['email'] = TextEditingController(text: data?['email']?.toString() ?? '');
      _controllers['website'] = TextEditingController(text: data?['website']?.toString() ?? '');
      _controllers['latitude'] = TextEditingController(text: data?['latitude']?.toString() ?? '');
      _controllers['longitude'] = TextEditingController(text: data?['longitude']?.toString() ?? '');
      _controllers['description'] = TextEditingController(text: data?['description']?.toString() ?? '');
      
      final amenitiesRaw = data?['amenities'];
      final amenitiesStr = (amenitiesRaw is List) 
          ? amenitiesRaw.join(', ') 
          : (amenitiesRaw?.toString() ?? '');
      _controllers['amenitiesText'] = TextEditingController(text: amenitiesStr);

      _serviceType = data?['serviceType'] ?? 'Immigration';
      // Normalize legacy $ symbols to €
      final rawSvcPr = data?['priceRange'] ?? '€€';
      _servicePriceRange = rawSvcPr.replaceAll(r'$', '€');

      final List<dynamic> initImgs = data?['images'] ?? data?['media']?['images'] ?? [];
      _existingImageUrls = List<String>.from(initImgs.whereType<String>().where((s) => s.startsWith('http')));
    }
    else if (widget.category == 'Second Hand Store') {
      _controllers['title'] = TextEditingController(text: data?['title']?.toString() ?? '');
      _controllers['price'] = TextEditingController(text: data?['price']?.toString() ?? '');
      _controllers['contactPhone'] = TextEditingController(text: data?['contactPhone']?.toString() ?? '');
      _controllers['contactEmail'] = TextEditingController(text: data?['contactEmail']?.toString() ?? '');
      _controllers['link'] = TextEditingController(text: (data?['externalUrl'] ?? data?['website'] ?? data?['link'])?.toString() ?? '');
      _controllers['description'] = TextEditingController(text: data?['description']?.toString() ?? '');
      _deliveryOption = data?['deliveryOption'] ?? 'Shipping Possible';
      
      final List<dynamic> initImgs = data?['images'] ?? data?['media']?['images'] ?? [];
      _existingImageUrls = List<String>.from(initImgs.whereType<String>().where((s) => s.startsWith('http')));
    }
    else if (widget.category == 'Events' || widget.category == 'Event') {
      _controllers['title'] = TextEditingController(text: data?['title']?.toString() ?? '');
      _controllers['shortDescription'] = TextEditingController(text: data?['shortDescription']?.toString() ?? '');

      final langs = data?['languages'];
      final langsStr = (langs is List) ? langs.join(', ') : (langs?.toString() ?? '');
      _controllers['languages'] = TextEditingController(text: langsStr);

      _controllers['city'] = TextEditingController(text: data?['city']?.toString() ?? '');
      _controllers['venue'] = TextEditingController(text: (data?['venue'] ?? data?['location'])?.toString() ?? '');
      _controllers['address'] = TextEditingController(text: data?['address']?.toString() ?? '');
      _controllers['onlineLink'] = TextEditingController(text: data?['onlineLink']?.toString() ?? '');
      _controllers['organizer'] = TextEditingController(text: (data?['organizer'] ?? data?['organizerName'])?.toString() ?? '');
      _controllers['contact'] = TextEditingController(text: data?['contact']?.toString() ?? '');

      String startsAtStr = '';
      if (data?['startsAt'] != null) {
        startsAtStr = data!['startsAt'].toString().split('T')[0];
      }
      String endsAtStr = '';
      if (data?['endsAt'] != null) {
        endsAtStr = data!['endsAt'].toString().split('T')[0];
      }
      _controllers['startsAt'] = TextEditingController(text: startsAtStr);
      _controllers['endsAt'] = TextEditingController(text: endsAtStr);
      _controllers['timeText'] = TextEditingController(text: (data?['timeText'] ?? data?['time_text'])?.toString() ?? '');

      _controllers['priceText'] = TextEditingController(text: (data?['priceText'] ?? data?['price'])?.toString() ?? '');
      _controllers['ticketUrl'] = TextEditingController(text: (data?['ticketUrl'] ?? data?['externalUrl'])?.toString() ?? '');
      _controllers['description'] = TextEditingController(text: data?['description']?.toString() ?? '');

      _eventFormat = data?['format']?.toString() ?? 'one_day';
      _eventCategory = data?['category']?.toString() ?? 'festivals';
      _eventPriceType = data?['priceType']?.toString() ?? (data?['price']?.toString().toLowerCase() == 'free' ? 'free' : 'paid');
      _eventIsOnline = data?['isOnline'] == true || data?['isOnline'] == 'true';
      _eventFamilyFriendly = data?['familyFriendly'] == true || data?['familyFriendly'] == 'true';
      _eventOngoing = data?['ongoing'] == true || data?['ongoing'] == 'true';
      _eventLevel = data?['level']?.toString() ?? 'all';
      _eventAgeGroup = data?['ageGroup']?.toString() ?? 'all';

      if (data?['daysOfWeek'] is List) {
        _eventDaysOfWeek.clear();
        for (final d in (data!['daysOfWeek'] as List)) {
          final id = int.tryParse(d.toString());
          if (id != null) _eventDaysOfWeek.add(id);
        }
      }

      final List<dynamic> initImgs = data?['images'] ?? data?['media']?['images'] ?? [];
      _existingImageUrls = List<String>.from(initImgs.whereType<String>().where((s) => s.startsWith('http')));
    }
  }

  // Total images count = existing URLs + newly picked files
  int get _totalImageCount => _existingImageUrls.length + _imageFiles.length;

  Future<void> _pickImage() async {
    final maxImages = widget.category == 'Jobs' ? 1 : (widget.category == 'Second Hand Store' ? 5 : 3);
    if (_totalImageCount >= maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You can upload a maximum of $maxImages image${maxImages > 1 ? 's' : ''}.')),
      );
      return;
    }
    try {
      // Heavy compression to save Cloudinary bandwidth & avoid Nginx limits!
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery, 
        imageQuality: 60,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (file == null) return;

      setState(() {
        if (widget.category == 'Jobs') {
          // Jobs only supports one companyLogo
          _imageFiles = [file];
          _existingImageUrls = [];
        } else {
          _imageFiles.add(file);
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting image: $e')),
      );
    }
  }

  Map<String, dynamic> _buildPayload() {
    if (widget.category == 'Accommodation') {
      return {
        'title': _controllers['title']?.text.trim(),
        'propertyType': _propertyType,
        'city': _controllers['city']?.text.trim(),
        'area': _controllers['area']?.text.trim().isEmpty == true ? null : _controllers['area']?.text.trim(),
        'postalCode': _controllers['postalCode']?.text.trim(),
        'address': _controllers['address']?.text.trim().isEmpty == true ? null : _controllers['address']?.text.trim(),
        'contactPhone': _controllers['contactPhone']?.text.trim(),
        'description': _controllers['description']?.text.trim().isEmpty == true ? null : _controllers['description']?.text.trim(),
        'website': _controllers['link']?.text.trim().isEmpty == true ? null : _controllers['link']?.text.trim(),
        'externalUrl': _controllers['link']?.text.trim().isEmpty == true ? null : _controllers['link']?.text.trim(),
        'rentDetails': {
          'coldRent': double.tryParse(_controllers['coldRent']?.text ?? '0') ?? 0,
          'warmRent': double.tryParse(_controllers['warmRent']?.text ?? '0') ?? 0,
          'deposit': double.tryParse(_controllers['deposit']?.text ?? '0') ?? 0,
        },
        'propertyDetails': {
          'sizeSqm': double.tryParse(_controllers['sizeSqm']?.text ?? '0') ?? 0,
          'bedrooms': int.tryParse(_controllers['bedrooms']?.text ?? '0') ?? 0,
          'bathrooms': int.tryParse(_controllers['bathrooms']?.text ?? '0') ?? 0,
        },
        'amenities': _accommodationAmenities.fold<Map<String, bool>>({}, (map, key) {
          final dbKey = key[0].toLowerCase() + key.substring(1).replaceAll(' ', '');
          map[dbKey] = true;
          return map;
        }),
        // Images are sent as multipart files - no base64 here
        'media': {'images': _existingImageUrls},
      };
    } 
    else if (widget.category == 'Jobs') {
      return {
        'title': _controllers['title']?.text.trim(),
        'location': _controllers['location']?.text.trim(),
        'city': _controllers['location']?.text.trim(),
        'country': _controllers['country']?.text.trim().isEmpty == true ? 'Germany' : _controllers['country']?.text.trim(),
        'domain': _controllers['domain']?.text.trim().isEmpty == true ? null : _controllers['domain']?.text.trim(),
        'contact': _controllers['contact']?.text.trim(),
        'phone': _controllers['contact']?.text.trim(),
        'description': _controllers['description']?.text.trim().isEmpty == true ? null : _controllers['description']?.text.trim(),
        'salary': _controllers['salary']?.text.trim().isEmpty == true ? null : _controllers['salary']?.text.trim(),
        'company': _controllers['companyName']?.text.trim(),
        'companyName': _controllers['companyName']?.text.trim(),
        // companyLogo is sent as multipart file - existing URL passed here only
        'companyLogo': _existingImageUrls.isNotEmpty ? _existingImageUrls[0] : null,
        'jobType': _jobType,
        'type': _jobType,
        'requirements': _controllers['requirements']?.text.trim().isEmpty == true ? null : _controllers['requirements']?.text.trim(),
        'benefits': _controllers['benefits']?.text.trim().isEmpty == true ? null : _controllers['benefits']?.text.trim(),
        'applyUrl': _controllers['applyUrl']?.text.trim(),
      };
    } 
    else if (widget.category == 'Services' || widget.category == 'Expat Services') {
      // Services
      final lat = double.tryParse(_controllers['latitude']?.text ?? '');
      final lon = double.tryParse(_controllers['longitude']?.text ?? '');
      final amenitiesList = _controllers['amenitiesText']?.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList() ?? [];

      return {
        'title': _controllers['serviceName']?.text.trim(),
        'serviceName': _controllers['serviceName']?.text.trim(),
        'providerName': _controllers['providerName']?.text.trim(),
        'phone': _controllers['contactPhone']?.text.trim(),
        'contactPhone': _controllers['contactPhone']?.text.trim(),
        'whatsapp': _controllers['whatsapp']?.text.trim().isEmpty == true ? null : _controllers['whatsapp']?.text.trim(),
        'email': _controllers['email']?.text.trim(),
        'website': _controllers['website']?.text.trim().isEmpty == true ? null : _controllers['website']?.text.trim(),
        'latitude': lat,
        'longitude': lon,
        'images': _existingImageUrls,
        'media': {'images': _existingImageUrls},
        'amenities': amenitiesList,
        'serviceType': _serviceType,
        'city': _controllers['city']?.text.trim(),
        'area': _controllers['area']?.text.trim().isEmpty == true ? null : _controllers['area']?.text.trim(),
        'postalCode': _controllers['postalCode']?.text.trim(),
        'address': _controllers['address']?.text.trim().isEmpty == true ? null : _controllers['address']?.text.trim(),
        'description': _controllers['description']?.text.trim().isEmpty == true ? null : _controllers['description']?.text.trim(),
        'priceRange': _servicePriceRange,
      };
    }
    else if (widget.category == 'Second Hand Store') {
      return {
        'title': _controllers['title']?.text.trim(),
        'price': _controllers['price']?.text.trim(),
        'description': _controllers['description']?.text.trim().isEmpty == true ? null : _controllers['description']?.text.trim(),
        'contactPhone': _controllers['contactPhone']?.text.trim(),
        'contactEmail': _controllers['contactEmail']?.text.trim(),
        'deliveryOption': _deliveryOption,
        'externalUrl': _controllers['link']?.text.trim().isEmpty == true ? null : _controllers['link']?.text.trim(),
        'website': _controllers['link']?.text.trim().isEmpty == true ? null : _controllers['link']?.text.trim(),
        'images': _existingImageUrls,
        'media': {'images': _existingImageUrls},
      };
    }
    else if (widget.category == 'Events' || widget.category == 'Event') {
      final langs = (_controllers['languages']?.text.trim() ?? '')
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      String? startsAtIso;
      final startText = _controllers['startsAt']?.text.trim() ?? '';
      if (startText.isNotEmpty) {
        startsAtIso = startText.contains('T') ? startText : '${startText}T10:00:00';
      }

      String? endsAtIso;
      final endText = _controllers['endsAt']?.text.trim() ?? '';
      if (endText.isNotEmpty) {
        endsAtIso = endText.contains('T') ? endText : '${endText}T23:59:59';
      } else if (_eventFormat == 'one_day' && startsAtIso != null) {
        endsAtIso = startsAtIso.replaceAll('T10:00:00', 'T23:59:59');
      }

      final priceText = _eventPriceType == 'free'
          ? 'Free'
          : (_controllers['priceText']?.text.trim().isNotEmpty == true
              ? _controllers['priceText']!.text.trim()
              : 'Paid');

      return {
        'title': _controllers['title']?.text.trim(),
        'format': _eventFormat,
        'category': _eventCategory,
        'shortDescription': _controllers['shortDescription']?.text.trim().isNotEmpty == true
            ? _controllers['shortDescription']!.text.trim()
            : null,
        'languages': langs,
        'startsAt': startsAtIso,
        'endsAt': endsAtIso,
        'timeText': _controllers['timeText']?.text.trim().isNotEmpty == true
            ? _controllers['timeText']!.text.trim()
            : null,
        'isOnline': _eventIsOnline,
        'onlineLink': _eventIsOnline ? _controllers['onlineLink']?.text.trim() : null,
        'city': _eventIsOnline ? null : _controllers['city']?.text.trim(),
        'venue': _eventIsOnline ? null : _controllers['venue']?.text.trim(),
        'address': _eventIsOnline ? null : _controllers['address']?.text.trim(),
        'organizer': _controllers['organizer']?.text.trim(),
        'contact': _controllers['contact']?.text.trim(),
        'familyFriendly': _eventFamilyFriendly,
        'ongoing': _eventOngoing,
        'daysOfWeek': _eventDaysOfWeek,
        'level': _eventLevel,
        'ageGroup': _eventAgeGroup,
        'priceType': _eventPriceType,
        'price': priceText,
        'priceText': priceText,
        'ticketUrl': _controllers['ticketUrl']?.text.trim().isNotEmpty == true
            ? _controllers['ticketUrl']!.text.trim()
            : null,
        'externalUrl': _controllers['ticketUrl']?.text.trim().isNotEmpty == true
            ? _controllers['ticketUrl']!.text.trim()
            : null,
        'description': _controllers['description']?.text.trim(),
        'images': _existingImageUrls,
        'media': {'images': _existingImageUrls},
      };
    }
    return {};
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() => _submitting = true);

    try {
      final token = UserSession.instance.token;
      if (token == null) {
        throw Exception("Authentication token missing. Please log in again.");
      }

      final payload = {
        'category': widget.category,
        'data': _buildPayload(),
      };

      final bool isEditing = widget.initialData != null;
      final String url = isEditing
          ? '${ApiConfig.baseUrl}/api/user/listings/${widget.category}/${widget.initialData!['_id']}'
          : '${ApiConfig.baseUrl}/api/user/listings';

      http.Response response;

      if (_imageFiles.isNotEmpty) {
        // Use MultipartRequest to send files + JSON payload together
        final uri = Uri.parse(url);
        final request = isEditing
            ? (http.MultipartRequest('PUT', uri))
            : (http.MultipartRequest('POST', uri));

        request.headers['Authorization'] = 'Bearer $token';

        // Attach the JSON payload as a field
        request.fields['category'] = widget.category;
        request.fields['data'] = jsonEncode(_buildPayload());

        // Attach files (images) directly as binary streams
        final fieldName = 'images';
        for (final file in _imageFiles) {
          final bytes = await file.readAsBytes();
          request.files.add(http.MultipartFile.fromBytes(
            fieldName,
            bytes,
            filename: file.name,
          ));
        }

        final streamedResponse = await request.send();
        response = await http.Response.fromStream(streamedResponse);
      } else {
        // No new images - just send JSON as before
        response = await (isEditing
            ? http.put(
                Uri.parse(url),
                headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
                body: jsonEncode(payload),
              )
            : http.post(
                Uri.parse(url),
                headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
                body: jsonEncode(payload),
              ));
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Listing saved successfully!')),
          );
          Navigator.pop(context, true); // true indicates success
        }
      } else {
        String errorMsg = 'Failed to save listing';
        try {
          final resData = jsonDecode(response.body);
          if (resData['message'] != null) {
            errorMsg = resData['message'];
          }
        } catch (e) {
          // If the server returns HTML (like Nginx 413 Payload Too Large or 502 Bad Gateway)
          if (response.body.contains('<html') || response.body.contains('<!DOC')) {
            if (response.statusCode == 413) {
              errorMsg = "Images are too large. Please upload smaller images or increase server limit.";
            } else {
              errorMsg = "Server Error ${response.statusCode}. Please check server logs.";
            }
          } else {
            errorMsg = response.body.isNotEmpty ? response.body : errorMsg;
          }
        }
        throw Exception(errorMsg);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Widget _buildField({
    required String key,
    required String label,
    required String hint,
    bool required = true,
    int maxLines = 1,
    int? maxLength,
    int minLength = 3,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label ${required ? "*" : ""}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _controllers[key],
            maxLines: maxLines,
            maxLength: maxLength,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              filled: true,
              fillColor: Colors.white,
              counterText: '',
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: primaryGreen, width: 1.5),
              ),
            ),
            validator: (val) {
              if (required && (val == null || val.trim().isEmpty)) {
                return '$label is required';
              }
              if (required && val != null && val.trim().length < minLength) {
                return '$label must be at least $minLength characters';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    List<String>? itemValues, // optional separate values; if null, items are used as values
    required ValueChanged<String?> onChanged,
  }) {
    final values = itemValues ?? items;
    final effectiveValue = values.contains(value) ? value : (values.isNotEmpty ? values.first : null);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: effectiveValue,
            isExpanded: true,
            items: List.generate(items.length, (i) => DropdownMenuItem(
              value: values[i],
              child: Text(
                items[i],
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            )),
            onChanged: onChanged,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickerField({
    required String label,
    required TextEditingController controller,
    required String hint,
    bool required = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label ${required ? "*" : ""}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () async {
              DateTime initial = DateTime.now();
              if (controller.text.trim().isNotEmpty) {
                final parsed = DateTime.tryParse(controller.text.trim());
                if (parsed != null) initial = parsed;
              }
              final picked = await showDatePicker(
                context: context,
                initialDate: initial,
                firstDate: DateTime(2020),
                lastDate: DateTime(2035),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: primaryGreen,
                        onPrimary: Colors.white,
                        onSurface: Colors.black87,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                final y = picked.year.toString().padLeft(4, '0');
                final m = picked.month.toString().padLeft(2, '0');
                final d = picked.day.toString().padLeft(2, '0');
                controller.text = '$y-$m-$d';
                setState(() {});
              }
            },
            child: IgnorePointer(
              child: TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: hint,
                  suffixIcon: const Icon(Icons.calendar_today_rounded, color: primaryGreen, size: 20),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                validator: (val) {
                  if (required && (val == null || val.trim().isEmpty)) {
                    return '$label is required';
                  }
                  return null;
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSelector() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.category == 'Jobs' ? "Company Logo" : "Photos",
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Show existing Cloudinary image URLs
              ..._existingImageUrls.asMap().entries.map((entry) {
                final idx = entry.key;
                final url = entry.value;
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        url,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.broken_image),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: GestureDetector(
                        onTap: () => setState(() => _existingImageUrls.removeAt(idx)),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          child: const Icon(Icons.close, size: 12, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              }),
              // Show newly picked local image files
              ..._imageFiles.asMap().entries.map((entry) {
                final idx = entry.key;
                final file = entry.value;
                return FutureBuilder<Uint8List>(
                  future: file.readAsBytes(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    }
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            snapshot.data!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 2,
                          right: 2,
                          child: GestureDetector(
                            onTap: () => setState(() => _imageFiles.removeAt(idx)),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                              child: const Icon(Icons.close, size: 12, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              }),
              if (_totalImageCount < (widget.category == 'Jobs' ? 1 : (widget.category == 'Second Hand Store' ? 5 : 3)) ||
                  (widget.category == 'Jobs' && _totalImageCount == 0))
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add_a_photo, color: primaryGreen),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAccommodationForm() {
    return [
      _buildField(key: 'title', label: 'Title', hint: 'Cozy 2-Bedroom Apartment', maxLength: 100, minLength: 2),
      _buildDropdown(
        label: 'Property Type',
        value: _propertyType,
        items: ['apartment', 'temporary_stays', 'shared_rooms'],
        onChanged: (val) => setState(() => _propertyType = val ?? 'apartment'),
      ),
      _buildField(key: 'city', label: 'City', hint: 'Munich', maxLength: 50, minLength: 2),
      _buildField(
        key: 'postalCode',
        label: 'Postal Code',
        hint: '80331',
        maxLength: 20,
        minLength: 2,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      ),
      _buildField(key: 'area', label: 'Area', hint: 'Schwabing', maxLength: 100, minLength: 2),
      _buildField(key: 'address', label: 'Address', hint: 'Leopoldstraße 1', maxLength: 200, minLength: 2),
      _buildField(
        key: 'contactPhone',
        label: 'Contact Phone',
        hint: '491701234567',
        maxLength: 20,
        minLength: 2,
        keyboardType: TextInputType.phone,
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+]'))],
      ),
      _buildField(key: 'description', label: 'Description', hint: 'Detailed description…', maxLines: 4, maxLength: 5000, minLength: 2),
      _buildField(key: 'link', label: 'Link / Website (Optional)', hint: 'https://...', required: false, maxLength: 500),
      
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Text("💶 Pricing", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryGreen)),
      ),
      _buildField(key: 'coldRent', label: 'Cold Rent (€)', hint: '800', keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], minLength: 1),
      _buildField(key: 'warmRent', label: 'Warm Rent (€)', hint: '1000', keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], minLength: 1),
      _buildField(key: 'deposit', label: 'Deposit (€)', hint: '2400', keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], minLength: 1),
      
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Text("🏠 Property Details", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryGreen)),
      ),
      _buildField(key: 'sizeSqm', label: 'Size (sqm)', hint: '50', keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))], minLength: 1),
      _buildField(key: 'bedrooms', label: 'Bedrooms', hint: '2', keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], minLength: 1),
      _buildField(key: 'bathrooms', label: 'Bathrooms', hint: '1', keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], minLength: 1),

      const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Text("Amenities", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryGreen)),
      ),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: _amenityOpts.map((o) {
          final isSelected = _accommodationAmenities.contains(o);
          return FilterChip(
            label: Text(o, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black87)),
            selected: isSelected,
            selectedColor: primaryGreen,
            checkmarkColor: Colors.white,
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: isSelected ? primaryGreen : Colors.grey.shade300),
            ),
            onSelected: (val) {
              setState(() {
                if (val) {
                  _accommodationAmenities.add(o);
                } else {
                  _accommodationAmenities.remove(o);
                }
              });
            },
          );
        }).toList(),
      ),
      const SizedBox(height: 20),
      _buildImageSelector(),
    ];
  }



  List<Widget> _buildJobsForm() {
    return [
      _buildField(key: 'title', label: 'Job Title', hint: 'Software Engineer', maxLength: 100, minLength: 2),
      _buildField(key: 'companyName', label: 'Company Name', hint: 'Tech Solutions GmbH', maxLength: 100, minLength: 1),
      SearchableDropdownInput(
        label: "Country",
        controller: _controllers['country']!,
        options: const [
          'Germany',
          'India',
          'Europe',
          'United Kingdom',
          'United States',
          'Other / Remote',
        ],
        hintText: "Select or type country",
        isRequired: false,
      ),
      _buildField(key: 'location', label: 'Location (City)', hint: 'Munich', maxLength: 100, minLength: 1),
      SearchableDropdownInput(
        label: "Field / Domain",
        controller: _controllers['domain']!,
        options: _domainOptions,
        hintText: "Type or select domain (e.g. IT, Healthcare)",
        isRequired: false,
      ),
      _buildField(
        key: 'contact',
        label: 'Contact Details',
        hint: 'Email or Phone number',
        required: false,
        maxLength: 100,
        minLength: 1,
        keyboardType: TextInputType.text,
      ),
      _buildField(key: 'salary', label: 'Salary', hint: '€3,000/month', required: false, maxLength: 50, minLength: 1),
      _buildField(key: 'applyUrl', label: 'Apply URL', hint: 'https://company.com/apply', maxLength: 500, minLength: 2, keyboardType: TextInputType.url),
      _buildDropdown(
        label: 'Job Type',
        value: _jobType,
        items: ['Full Time', 'Part Time', 'Contract', 'Internship', 'Freelance'],
        onChanged: (val) => setState(() => _jobType = val ?? 'Full Time'),
      ),
      _buildField(key: 'description', label: 'Description', hint: 'Job description…', maxLines: 4, maxLength: 5000, minLength: 2),
      _buildField(key: 'requirements', label: 'Requirements (comma-separated)', hint: 'Flutter, Dart, 2+ years experience', maxLines: 2, maxLength: 2000, minLength: 2),
      _buildField(key: 'benefits', label: 'Benefits (comma-separated)', hint: 'Health insurance, flexible hours', maxLines: 2, maxLength: 2000, minLength: 2),

      const SizedBox(height: 20),
      _buildImageSelector(),
    ];
  }

  List<Widget> _buildServicesForm() {
    return [
      _buildField(key: 'serviceName', label: 'Service Name', hint: 'Visa Consultation', maxLength: 100, minLength: 2),
      _buildField(key: 'providerName', label: 'Provider Name', hint: 'Max Mustermann', maxLength: 100, minLength: 2),
      _buildDropdown(
        label: 'Service Type',
        value: _serviceType,
        items: ['Immigration', 'Legal', 'Financial', 'Tax', 'Consultation', 'Home Services', 'Tuition & Coaching', 'IT Services', 'Education', 'Relocation', 'Translation', 'Other'],
        onChanged: (val) => setState(() => _serviceType = val ?? 'Immigration'),
      ),
      _buildDropdown(
        label: 'Price Range',
        value: _servicePriceRange,
        items: ['€ (Low)', '€€ (Medium)', '€€€ (Premium)', '€€€€ (Luxury)'],
        itemValues: ['€', '€€', '€€€', '€€€€'],
        onChanged: (val) => setState(() => _servicePriceRange = val ?? '€€'),
      ),
      _buildField(key: 'city', label: 'City', hint: 'Munich', maxLength: 50, minLength: 2),
      _buildField(
        key: 'postalCode',
        label: 'Postal Code',
        hint: '80331',
        maxLength: 20,
        minLength: 2,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      ),
      _buildField(key: 'area', label: 'Area', hint: 'Maxvorstadt', maxLength: 100, minLength: 2),
      _buildField(key: 'address', label: 'Address', hint: 'Street, No.', maxLength: 200, minLength: 2),
      _buildField(
        key: 'contactPhone',
        label: 'Contact Phone',
        hint: '491701234567',
        maxLength: 20,
        minLength: 2,
        keyboardType: TextInputType.phone,
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+]'))],
      ),
      _buildField(
        key: 'whatsapp',
        label: 'WhatsApp',
        hint: '491701234567',
        required: false,
        maxLength: 20,
        minLength: 2,
        keyboardType: TextInputType.phone,
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+]'))],
      ),
      _buildField(key: 'email', label: 'Email', hint: 'name@example.com', maxLength: 100, minLength: 2, keyboardType: TextInputType.emailAddress),
      _buildField(key: 'website', label: 'Website', hint: 'https://example.com', required: false, maxLength: 200, minLength: 2, keyboardType: TextInputType.url),
      _buildField(
        key: 'latitude',
        label: 'Latitude',
        hint: '48.137154',
        required: false,
        maxLength: 20,
        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.-]'))],
      ),
      _buildField(
        key: 'longitude',
        label: 'Longitude',
        hint: '11.576124',
        required: false,
        maxLength: 20,
        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.-]'))],
      ),
      _buildField(key: 'description', label: 'Description', hint: 'What you offer...', maxLines: 4, maxLength: 5000),
      _buildField(key: 'amenitiesText', label: 'Services Offered (comma-separated)', hint: 'Visa assistance, translation, relocation support', maxLines: 3, maxLength: 2000),

      const SizedBox(height: 20),
      _buildImageSelector(),
    ];
  }

  List<Widget> _buildSecondHandStoreForm() {
    return [
      _buildField(key: 'title', label: 'Item Title', hint: 'IKEA Sofa, iPhone 12, etc.', maxLength: 100, minLength: 2),
      _buildField(
        key: 'price', 
        label: 'Price', 
        hint: '€150 (Enter amount or text)', 
        maxLength: 20, 
        minLength: 1
      ),
      _buildDropdown(
        label: 'Delivery Option',
        value: _deliveryOption,
        items: ['Shipping Possible', 'Pickup only'],
        onChanged: (val) => setState(() => _deliveryOption = val ?? 'Shipping Possible'),
      ),
      _buildField(
        key: 'contactPhone',
        label: 'Contact Phone',
        hint: '491701234567',
        required: false,
        maxLength: 20,
        minLength: 2,
        keyboardType: TextInputType.phone,
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+]'))],
      ),
      _buildField(
        key: 'contactEmail',
        label: 'Contact Email',
        hint: 'name@example.com',
        required: false,
        maxLength: 100,
        minLength: 2,
        keyboardType: TextInputType.emailAddress
      ),
      _buildField(key: 'description', label: 'Description', hint: 'Item condition, details, reasons for selling...', maxLines: 4, maxLength: 5000),
      _buildField(key: 'link', label: 'Link / Website (Optional)', hint: 'https://...', required: false, maxLength: 500),

      const SizedBox(height: 20),
      _buildImageSelector(),
    ];
  }

  List<Widget> _buildEventsForm() {
    return [
      // 1. Event Format
      _buildDropdown(
        label: 'Event Format',
        value: _eventFormat,
        items: _eventFormats.map((f) => f['label']!).toList(),
        itemValues: _eventFormats.map((f) => f['value']!).toList(),
        onChanged: (val) {
          if (val != null) {
            setState(() {
              _eventFormat = val;
              if (val == 'screening') {
                _eventCategory = 'movies';
              } else if (val == 'course') {
                _eventCategory = 'classes';
              } else if (val == 'deadline') {
                _eventCategory = 'contests';
              }
            });
          }
        },
      ),

      // 2. Category
      _buildDropdown(
        label: 'Category',
        value: _eventCategory,
        items: _eventCategories.map((c) => c['label']!).toList(),
        itemValues: _eventCategories.map((c) => c['value']!).toList(),
        onChanged: (val) {
          if (val != null) {
            setState(() => _eventCategory = val);
          }
        },
      ),

      // 3. Basic Information
      _buildField(
        key: 'title',
        label: 'Event Title',
        hint: 'e.g. Diwali Mela 2026 or Indian Film Screening',
        required: true,
        minLength: 3,
        maxLength: 150,
      ),

      _buildField(
        key: 'shortDescription',
        label: 'Short Description (Card text, ≤160 chars)',
        hint: 'Quick summary displayed on event cards',
        required: false,
        maxLength: 160,
      ),

      _buildField(
        key: 'languages',
        label: 'Languages (comma separated)',
        hint: 'e.g. Tamil, English, Hindi, German',
        required: false,
        maxLength: 120,
      ),

      // 4. Date & Schedule (dynamic based on format)
      if (_eventFormat == 'one_day') ...[
        _buildDatePickerField(
          label: 'Event Date',
          controller: _controllers['startsAt']!,
          hint: 'Select event date',
          required: true,
        ),
        _buildField(
          key: 'timeText',
          label: 'Time Text (Card label)',
          hint: 'e.g. from 11:30 or 10:00–14:00',
          required: false,
          maxLength: 60,
        ),
      ] else if (_eventFormat == 'multi_day' || _eventFormat == 'workshop') ...[
        Row(
          children: [
            Expanded(
              child: _buildDatePickerField(
                label: 'Start Date',
                controller: _controllers['startsAt']!,
                hint: 'Start date',
                required: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDatePickerField(
                label: 'End Date',
                controller: _controllers['endsAt']!,
                hint: 'End date',
                required: true,
              ),
            ),
          ],
        ),
      ] else if (_eventFormat == 'deadline') ...[
        Row(
          children: [
            Expanded(
              child: _buildDatePickerField(
                label: 'Opens Date (Optional)',
                controller: _controllers['startsAt']!,
                hint: 'Opens date',
                required: false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDatePickerField(
                label: 'Submission Deadline',
                controller: _controllers['endsAt']!,
                hint: 'Deadline date',
                required: true,
              ),
            ),
          ],
        ),
      ] else if (_eventFormat == 'course') ...[
        _buildDatePickerField(
          label: 'Course Start Date',
          controller: _controllers['startsAt']!,
          hint: 'Start date',
          required: true,
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          activeColor: primaryGreen,
          title: const Text('Ongoing Course (Join anytime, +90 days)', style: TextStyle(fontSize: 14)),
          value: _eventOngoing,
          onChanged: (val) => setState(() => _eventOngoing = val ?? false),
        ),
        const SizedBox(height: 6),
        const Text('Days of Week Class Meets', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (int i = 1; i <= 7; i++)
              FilterChip(
                label: Text(['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][i - 1]),
                selected: _eventDaysOfWeek.contains(i),
                selectedColor: primaryGreen.withOpacity(0.2),
                checkmarkColor: primaryGreen,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _eventDaysOfWeek.add(i);
                    } else {
                      _eventDaysOfWeek.remove(i);
                    }
                  });
                },
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDropdown(
                label: 'Level',
                value: _eventLevel,
                items: const ['All Levels', 'Beginner', 'Intermediate', 'Advanced'],
                itemValues: const ['all', 'beginner', 'intermediate', 'advanced'],
                onChanged: (val) => setState(() => _eventLevel = val ?? 'all'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDropdown(
                label: 'Age Group',
                value: _eventAgeGroup,
                items: const ['All Ages', 'Kids', 'Teens', 'Adults'],
                itemValues: const ['all', 'kids', 'teens', 'adults'],
                onChanged: (val) => setState(() => _eventAgeGroup = val ?? 'all'),
              ),
            ),
          ],
        ),
      ] else if (_eventFormat == 'screening') ...[
        Row(
          children: [
            Expanded(
              child: _buildDatePickerField(
                label: 'Run Start Date',
                controller: _controllers['startsAt']!,
                hint: 'Start date',
                required: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDatePickerField(
                label: 'Run End Date',
                controller: _controllers['endsAt']!,
                hint: 'End date',
                required: true,
              ),
            ),
          ],
        ),
      ],

      // 5. Location
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        activeColor: primaryGreen,
        title: const Text('This is an Online Event / Contest (Zoom, YouTube, etc.)', style: TextStyle(fontSize: 14)),
        value: _eventIsOnline,
        onChanged: (val) => setState(() => _eventIsOnline = val ?? false),
      ),
      if (_eventIsOnline) ...[
        _buildField(
          key: 'onlineLink',
          label: 'Online Link (Zoom / YouTube / Instagram)',
          hint: 'https://zoom.us/j/... or https://...',
          required: true,
          keyboardType: TextInputType.url,
        ),
      ] else ...[
        _buildField(
          key: 'city',
          label: 'City',
          hint: 'e.g. Munich, Berlin, Frankfurt',
          required: true,
          minLength: 2,
        ),
        _buildField(
          key: 'venue',
          label: 'Venue / Hall Name',
          hint: 'e.g. Stadt. Willi-Graf-Gymnasium',
          required: false,
        ),
        _buildField(
          key: 'address',
          label: 'Full Address',
          hint: 'e.g. Borschtallee 26, 80804 München',
          required: false,
        ),
      ],

      // 6. Organizer & Contact
      _buildField(
        key: 'organizer',
        label: 'Organizer Name',
        hint: 'e.g. Munich Tamil Kudumbam e.V.',
        required: true,
        minLength: 2,
      ),
      _buildField(
        key: 'contact',
        label: 'Contact (Phone / WhatsApp / Email)',
        hint: 'e.g. +49 176... or info@...',
        required: false,
      ),
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        activeColor: primaryGreen,
        title: const Text('Family Friendly Event (Suitable for children and families)', style: TextStyle(fontSize: 14)),
        value: _eventFamilyFriendly,
        onChanged: (val) => setState(() => _eventFamilyFriendly = val ?? false),
      ),

      // 7. Pricing & Registration
      _buildDropdown(
        label: 'Price Type',
        value: _eventPriceType,
        items: _eventPriceTypes.map((p) => p['label']!).toList(),
        itemValues: _eventPriceTypes.map((p) => p['value']!).toList(),
        onChanged: (val) => setState(() => _eventPriceType = val ?? 'paid'),
      ),
      if (_eventPriceType != 'free') ...[
        _buildField(
          key: 'priceText',
          label: 'Price / Fee Details',
          hint: 'e.g. €15, kids free',
          required: false,
        ),
      ],
      _buildField(
        key: 'ticketUrl',
        label: 'Ticket / Registration Link (Optional)',
        hint: 'https://eventbrite.com/... or https://...',
        required: false,
        keyboardType: TextInputType.url,
      ),

      // 8. Full Description
      _buildField(
        key: 'description',
        label: 'Full Description',
        hint: 'Full schedule, performer line-ups, dress code, instructions...',
        maxLines: 5,
        maxLength: 5000,
      ),

      const SizedBox(height: 20),
      _buildImageSelector(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> formFields = [];
    if (widget.category == 'Accommodation') {
      formFields = _buildAccommodationForm();
    } else if (widget.category == 'Jobs') {
      formFields = _buildJobsForm();
    } else if (widget.category == 'Services' || widget.category == 'Expat Services') {
      formFields = _buildServicesForm();
    } else if (widget.category == 'Second Hand Store') {
      formFields = _buildSecondHandStoreForm();
    } else if (widget.category == 'Events' || widget.category == 'Event') {
      formFields = _buildEventsForm();
    }

    final isEditing = widget.initialData != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: appBar(context, isEditing ? "Edit ${widget.category}" : "New ${widget.category}"),
      body: WillPopScope(
        onWillPop: () async {
          // If submitting, prevent popping
          if (_submitting) return false;
          // Simple confirm back button navigation
          return true;
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                ...formFields,
                const SizedBox(height: 30),
                if (_submitting)
                  const Center(child: CircularProgressIndicator())
                else
                  ElevatedButton(
                    onPressed: _submit,
                    style: buttonStyle(),
                    child: Text(
                      isEditing ? "Save Changes" : "Submit Listing",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
