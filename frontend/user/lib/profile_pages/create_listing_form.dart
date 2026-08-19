import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../user_session.dart';
import '../services/api_config.dart';
import 'ui_common.dart';
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

  @override
  void initState() {
    super.initState();
    _initFields();
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
  }

  // Total images count = existing URLs + newly picked files
  int get _totalImageCount => _existingImageUrls.length + _imageFiles.length;

  Future<void> _pickImage() async {
    final maxImages = widget.category == 'Jobs' ? 1 : 3;
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
            value: value,
            items: List.generate(items.length, (i) => DropdownMenuItem(
              value: values[i],
              child: Text(items[i]),
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
              if (_totalImageCount < (widget.category == 'Jobs' ? 1 : 3) ||
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
      _buildField(key: 'location', label: 'Location (City)', hint: 'Munich', maxLength: 100, minLength: 1),
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

  @override
  Widget build(BuildContext context) {
    List<Widget> formFields = [];
    if (widget.category == 'Accommodation') {
      formFields = _buildAccommodationForm();
    } else if (widget.category == 'Jobs') {
      formFields = _buildJobsForm();
    } else if (widget.category == 'Services' || widget.category == 'Expat Services') {
      formFields = _buildServicesForm();
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
