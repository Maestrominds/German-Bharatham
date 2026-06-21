import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../user_session.dart';
import '../services/api_config.dart';
import 'ui_common.dart';

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

  // List of base64 images (either loaded initially or picked by user)
  List<String> _imagesBase64 = [];

  // Controllers
  final Map<String, TextEditingController> _controllers = {};

  // Form selections (dropdowns / checkboxes / lists)
  String _propertyType = 'apartment';
  String _subCategory = 'Restaurant';
  String _priceRange = '$$';
  String _jobType = 'Full Time';
  String _serviceType = 'Immigration';

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

  // Lists for Food cuisine / specialties
  final List<String> _foodCuisines = [];
  final List<String> _foodSpecialties = [];
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
      _controllers['title'] = TextEditingController(text: data?['title'] ?? '');
      _controllers['city'] = TextEditingController(text: data?['city'] ?? '');
      _controllers['postalCode'] = TextEditingController(text: data?['postalCode'] ?? '');
      _controllers['area'] = TextEditingController(text: data?['area'] ?? '');
      _controllers['address'] = TextEditingController(text: data?['address'] ?? '');
      _controllers['contactPhone'] = TextEditingController(text: data?['contactPhone'] ?? '');
      _controllers['description'] = TextEditingController(text: data?['description'] ?? '');
      _controllers['coldRent'] = TextEditingController(text: data?['rentDetails']?['coldRent']?.toString() ?? '');
      _controllers['warmRent'] = TextEditingController(text: data?['rentDetails']?['warmRent']?.toString() ?? '');
      _controllers['deposit'] = TextEditingController(text: data?['rentDetails']?['deposit']?.toString() ?? '');
      _controllers['sizeSqm'] = TextEditingController(text: data?['propertyDetails']?['sizeSqm']?.toString() ?? '');
      _controllers['bedrooms'] = TextEditingController(text: data?['propertyDetails']?['bedrooms']?.toString() ?? '');
      _controllers['bathrooms'] = TextEditingController(text: data?['propertyDetails']?['bathrooms']?.toString() ?? '');
      
      _propertyType = data?['propertyType'] ?? 'apartment';

      // Load initial images
      final List<dynamic> initImgs = data?['media']?['images'] ?? [];
      _imagesBase64 = List<String>.from(initImgs);

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
    } 
    else if (widget.category == 'Food') {
      _controllers['title'] = TextEditingController(text: data?['title'] ?? '');
      _controllers['type'] = TextEditingController(text: data?['type'] ?? '');
      _controllers['address'] = TextEditingController(text: data?['address'] ?? '');
      _controllers['city'] = TextEditingController(text: data?['city'] ?? '');
      _controllers['state'] = TextEditingController(text: data?['state'] ?? '');
      _controllers['zipCode'] = TextEditingController(text: data?['zipCode'] ?? '');
      _controllers['phone'] = TextEditingController(text: data?['phone'] ?? '');
      _controllers['email'] = TextEditingController(text: data?['email'] ?? '');
      _controllers['website'] = TextEditingController(text: data?['website'] ?? '');
      _controllers['description'] = TextEditingController(text: data?['description'] ?? '');
      _controllers['openingHours'] = TextEditingController(text: data?['openingHours'] ?? '');
      _controllers['image'] = TextEditingController(text: data?['image'] ?? '');

      _subCategory = data?['subCategory'] ?? 'Restaurant';
      _priceRange = data?['priceRange'] ?? '$$';

      _dineInAvailable = data?['dineInAvailable'] ?? false;
      _deliveryAvailable = data?['deliveryAvailable'] ?? false;
      _takeoutAvailable = data?['takeoutAvailable'] ?? false;
      _cateringAvailable = data?['cateringAvailable'] ?? false;

      final List<dynamic> initCuisines = data?['cuisine'] ?? [];
      _foodCuisines.addAll(List<String>.from(initCuisines));

      final List<dynamic> initSpecs = data?['specialties'] ?? [];
      _foodSpecialties.addAll(List<String>.from(initSpecs));
    } 
    else if (widget.category == 'Jobs') {
      _controllers['title'] = TextEditingController(text: data?['title'] ?? '');
      _controllers['location'] = TextEditingController(text: data?['location'] ?? '');
      _controllers['contact'] = TextEditingController(text: data?['contact'] ?? data?['phone'] ?? '');
      _controllers['description'] = TextEditingController(text: data?['description'] ?? '');
      _controllers['salary'] = TextEditingController(text: data?['salary'] ?? '');
      _controllers['companyName'] = TextEditingController(text: data?['company'] ?? data?['companyName'] ?? '');
      _controllers['requirements'] = TextEditingController(text: data?['requirements'] ?? '');
      _controllers['benefits'] = TextEditingController(text: data?['benefits'] ?? '');
      _controllers['applyUrl'] = TextEditingController(text: data?['applyUrl'] ?? '');

      _jobType = data?['jobType'] ?? data?['type'] ?? 'Full Time';
      if (data?['companyLogo'] != null) {
        _imagesBase64 = [data!['companyLogo']];
      }
    } 
    else if (widget.category == 'Services') {
      _controllers['serviceName'] = TextEditingController(text: data?['serviceName'] ?? data?['title'] ?? '');
      _controllers['providerName'] = TextEditingController(text: data?['providerName'] ?? '');
      _controllers['city'] = TextEditingController(text: data?['city'] ?? '');
      _controllers['postalCode'] = TextEditingController(text: data?['postalCode'] ?? '');
      _controllers['area'] = TextEditingController(text: data?['area'] ?? '');
      _controllers['address'] = TextEditingController(text: data?['address'] ?? '');
      _controllers['contactPhone'] = TextEditingController(text: data?['contactPhone'] ?? data?['phone'] ?? '');
      _controllers['priceRange'] = TextEditingController(text: data?['priceRange'] ?? '');
      _controllers['whatsapp'] = TextEditingController(text: data?['whatsapp'] ?? '');
      _controllers['email'] = TextEditingController(text: data?['email'] ?? '');
      _controllers['website'] = TextEditingController(text: data?['website'] ?? '');
      _controllers['latitude'] = TextEditingController(text: data?['latitude']?.toString() ?? '');
      _controllers['longitude'] = TextEditingController(text: data?['longitude']?.toString() ?? '');
      _controllers['description'] = TextEditingController(text: data?['description'] ?? '');
      
      final List<dynamic> initAmenities = data?['amenities'] ?? [];
      _controllers['amenitiesText'] = TextEditingController(text: initAmenities.join(', '));

      _serviceType = data?['serviceType'] ?? 'Immigration';

      final List<dynamic> initImgs = data?['images'] ?? data?['media']?['images'] ?? [];
      _imagesBase64 = List<String>.from(initImgs);
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (file == null) return;

      final bytes = await file.readAsBytes();
      final base64String = 'data:image/${file.name.split('.').last};base64,${base64Encode(bytes)}';

      setState(() {
        if (widget.category == 'Jobs') {
          // Jobs only supports one companyLogo
          _imagesBase64 = [base64String];
        } else {
          _imagesBase64.add(base64String);
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
        'media': {'images': _imagesBase64},
      };
    } 
    else if (widget.category == 'Food') {
      return {
        'title': _controllers['title']?.text.trim(),
        'subCategory': _subCategory,
        'type': _controllers['type']?.text.trim(),
        'location': '${_controllers['city']?.text.trim()}, ${_controllers['address']?.text.trim()}',
        'address': _controllers['address']?.text.trim(),
        'city': _controllers['city']?.text.trim(),
        'state': _controllers['state']?.text.trim().isEmpty == true ? null : _controllers['state']?.text.trim(),
        'zipCode': _controllers['zipCode']?.text.trim(),
        'phone': _controllers['phone']?.text.trim(),
        'email': _controllers['email']?.text.trim().isEmpty == true ? null : _controllers['email']?.text.trim(),
        'website': _controllers['website']?.text.trim().isEmpty == true ? null : _controllers['website']?.text.trim(),
        'description': _controllers['description']?.text.trim().isEmpty == true ? null : _controllers['description']?.text.trim(),
        'priceRange': _priceRange,
        'openingHours': _controllers['openingHours']?.text.trim().isEmpty == true ? null : _controllers['openingHours']?.text.trim(),
        'cuisine': _foodCuisines,
        'specialties': _foodSpecialties,
        'deliveryAvailable': _deliveryAvailable,
        'takeoutAvailable': _takeoutAvailable,
        'dineInAvailable': _dineInAvailable,
        'cateringAvailable': _cateringAvailable,
        'image': _controllers['image']?.text.trim().isNotEmpty == true 
            ? _controllers['image']?.text.trim() 
            : (_imagesBase64.isNotEmpty ? _imagesBase64[0] : ''),
        'category': 'Food',
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
        'companyLogo': _imagesBase64.isNotEmpty ? _imagesBase64[0] : null,
        'jobType': _jobType,
        'type': _jobType,
        'requirements': _controllers['requirements']?.text.trim().isEmpty == true ? null : _controllers['requirements']?.text.trim(),
        'benefits': _controllers['benefits']?.text.trim().isEmpty == true ? null : _controllers['benefits']?.text.trim(),
        'applyUrl': _controllers['applyUrl']?.text.trim(),
      };
    } 
    else {
      // Services
      final lat = double.tryParse(_controllers['latitude']?.text ?? '');
      final lon = double.tryParse(_controllers['longitude']?.text ?? '');
      final amenitiesList = _controllers['amenitiesText']?.text
          .split(',')
          .map((s) => s.trim())
          .filter((s) => s.isNotEmpty)
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
        'images': _imagesBase64,
        'media': {'images': _imagesBase64},
        'amenities': amenitiesList,
        'serviceType': _serviceType,
        'city': _controllers['city']?.text.trim(),
        'area': _controllers['area']?.text.trim().isEmpty == true ? null : _controllers['area']?.text.trim(),
        'postalCode': _controllers['postalCode']?.text.trim(),
        'address': _controllers['address']?.text.trim().isEmpty == true ? null : _controllers['address']?.text.trim(),
        'description': _controllers['description']?.text.trim().isEmpty == true ? null : _controllers['description']?.text.trim(),
        'priceRange': _controllers['priceRange']?.text.trim().isEmpty == true ? null : _controllers['priceRange']?.text.trim(),
      };
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;

    if (widget.category == 'Accommodation' && _imagesBase64.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one Accommodation photo is required.')),
      );
      return;
    }

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

      final response = await (isEditing 
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

      final json = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(json['message'] ?? 'Submitted successfully!')),
        );
        Navigator.pop(context, true); // Return success flag
      } else {
        throw Exception(json['message'] ?? 'Failed to submit listing');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _submitting = false);
    }
  }

  Widget _buildField({
    required String key,
    required String label,
    required String hint,
    bool required = true,
    int maxLines = 1,
    int? maxLength,
    TextInputType keyboardType = TextInputType.text,
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
            decoration: InputDecoration(
              hintText: hint,
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
    required ValueChanged<String?> onChanged,
  }) {
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
            items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
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
              ..._imagesBase64.asMap().entries.map((entry) {
                final idx = entry.key;
                final img = entry.value;
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: img.startsWith('data:image') 
                          ? Image.memory(
                              base64Decode(img.split(',').last),
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            )
                          : Image.network(
                              ApiConfig.getImageUrl(img),
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
                        onTap: () => setState(() => _imagesBase64.removeAt(idx)),
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
              if (widget.category != 'Jobs' || _imagesBase64.isEmpty)
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
      _buildField(key: 'title', label: 'Title', hint: 'Cozy 2-Bedroom Apartment', maxLength: 100),
      _buildDropdown(
        label: 'Property Type',
        value: _propertyType,
        items: ['apartment', 'temporary_stays', 'shared_rooms'],
        onChanged: (val) => setState(() => _propertyType = val ?? 'apartment'),
      ),
      _buildField(key: 'city', label: 'City', hint: 'Munich', maxLength: 50),
      _buildField(key: 'postalCode', label: 'Postal Code', hint: '80331', maxLength: 20),
      _buildField(key: 'area', label: 'Area', hint: 'Schwabing', maxLength: 100),
      _buildField(key: 'address', label: 'Address', hint: 'Leopoldstraße 1', maxLength: 200),
      _buildField(key: 'contactPhone', label: 'Contact Phone', hint: '491701234567', maxLength: 20),
      _buildField(key: 'description', label: 'Description', hint: 'Detailed description…', maxLines: 4, maxLength: 5000),
      
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Text("💶 Pricing", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryGreen)),
      ),
      _buildField(key: 'coldRent', label: 'Cold Rent (€)', hint: '800', keyboardType: TextInputType.number),
      _buildField(key: 'warmRent', label: 'Warm Rent (€)', hint: '1000', keyboardType: TextInputType.number),
      _buildField(key: 'deposit', label: 'Deposit (€)', hint: '2400', keyboardType: TextInputType.number),
      
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Text("🏠 Property Details", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryGreen)),
      ),
      _buildField(key: 'sizeSqm', label: 'Size (sqm)', hint: '50', keyboardType: TextInputType.number),
      _buildField(key: 'bedrooms', label: 'Bedrooms', hint: '2', keyboardType: TextInputType.number),
      _buildField(key: 'bathrooms', label: 'Bathrooms', hint: '1', keyboardType: TextInputType.number),

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

  List<Widget> _buildFoodForm() {
    return [
      _buildField(key: 'title', label: 'Name', hint: 'Restaurant or Grocery name', maxLength: 100),
      _buildDropdown(
        label: 'Category',
        value: _subCategory,
        items: ['Restaurant', 'Grocery Store', 'Bakery', 'Cafe', 'Supermarket', 'Food Truck', 'Deli'],
        onChanged: (val) => setState(() => _subCategory = val ?? 'Restaurant'),
      ),
      _buildDropdown(
        label: 'Price Range',
        value: _priceRange,
        items: ['$', '$$', '$$$', '$$$$'],
        onChanged: (val) => setState(() => _priceRange = val ?? '$$'),
      ),
      _buildField(key: 'type', label: 'Type', hint: 'e.g., Indian, Italian, Organic', maxLength: 100),
      _buildField(key: 'address', label: 'Address', hint: 'Street address', maxLength: 200),
      _buildField(key: 'city', label: 'City', hint: 'Munich', maxLength: 50),
      _buildField(key: 'state', label: 'State/Region', hint: 'Bavaria', maxLength: 50),
      _buildField(key: 'zipCode', label: 'Zip Code', hint: '80331', maxLength: 20),
      _buildField(key: 'phone', label: 'Phone', hint: '491234567890', maxLength: 20),
      _buildField(key: 'email', label: 'Email', hint: 'contact@store.com', maxLength: 100),
      _buildField(key: 'website', label: 'Website', hint: 'https://www.store.com', maxLength: 200),
      _buildField(key: 'openingHours', label: 'Opening Hours', hint: 'Mon-Fri: 9am - 10pm', maxLength: 200),
      _buildField(key: 'description', label: 'Description', hint: 'Detailed description…', maxLines: 4, maxLength: 5000),

      const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Text("Cuisine & Specialties", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryGreen)),
      ),
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _cuisineInputCtrl,
              decoration: const InputDecoration(hintText: 'Add cuisine type...'),
              maxLength: 50,
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final text = _cuisineInputCtrl.text.trim();
              if (text.isNotEmpty && !_foodCuisines.contains(text)) {
                setState(() {
                  _foodCuisines.add(text);
                  _cuisineInputCtrl.clear();
                });
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),
            child: const Text("Add", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      Wrap(
        spacing: 6,
        children: _foodCuisines.map((c) => Chip(
          label: Text(c),
          onDeleted: () => setState(() => _foodCuisines.remove(c)),
        )).toList(),
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _specialtyInputCtrl,
              decoration: const InputDecoration(hintText: 'Add specialty...'),
              maxLength: 50,
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final text = _specialtyInputCtrl.text.trim();
              if (text.isNotEmpty && !_foodSpecialties.contains(text)) {
                setState(() {
                  _foodSpecialties.add(text);
                  _specialtyInputCtrl.clear();
                });
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),
            child: const Text("Add", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      Wrap(
        spacing: 6,
        children: _foodSpecialties.map((s) => Chip(
          label: Text(s),
          onDeleted: () => setState(() => _foodSpecialties.remove(s)),
        )).toList(),
      ),

      const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Text("Services Available", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryGreen)),
      ),
      CheckboxListTile(
        title: const Text("Dine-in"),
        value: _dineInAvailable,
        onChanged: (val) => setState(() => _dineInAvailable = val ?? false),
        controlAffinity: ListTileControlAffinity.leading,
      ),
      CheckboxListTile(
        title: const Text("Home Delivery"),
        value: _deliveryAvailable,
        onChanged: (val) => setState(() => _deliveryAvailable = val ?? false),
        controlAffinity: ListTileControlAffinity.leading,
      ),
      CheckboxListTile(
        title: const Text("Takeout"),
        value: _takeoutAvailable,
        onChanged: (val) => setState(() => _takeoutAvailable = val ?? false),
        controlAffinity: ListTileControlAffinity.leading,
      ),
      CheckboxListTile(
        title: const Text("Catering"),
        value: _cateringAvailable,
        onChanged: (val) => setState(() => _cateringAvailable = val ?? false),
        controlAffinity: ListTileControlAffinity.leading,
      ),

      const SizedBox(height: 20),
      _buildImageSelector(),
      _buildField(key: 'image', label: 'Or Image URL', hint: 'https://example.com/image.jpg', required: false, maxLength: 500),
    ];
  }

  List<Widget> _buildJobsForm() {
    return [
      _buildField(key: 'title', label: 'Job Title', hint: 'Software Engineer', maxLength: 100),
      _buildField(key: 'companyName', label: 'Company Name', hint: 'Tech Solutions GmbH', maxLength: 100),
      _buildField(key: 'location', label: 'Location (City)', hint: 'Munich', maxLength: 100),
      _buildField(key: 'contact', label: 'Contact Phone', hint: '49123456789', maxLength: 50),
      _buildField(key: 'salary', label: 'Salary', hint: '€3,000/month', maxLength: 50),
      _buildField(key: 'applyUrl', label: 'Apply URL', hint: 'https://company.com/apply', maxLength: 500),
      _buildDropdown(
        label: 'Job Type',
        value: _jobType,
        items: ['Full Time', 'Part Time', 'Contract', 'Internship', 'Freelance'],
        onChanged: (val) => setState(() => _jobType = val ?? 'Full Time'),
      ),
      _buildField(key: 'description', label: 'Description', hint: 'Job description…', maxLines: 4, maxLength: 5000),
      _buildField(key: 'requirements', label: 'Requirements (comma-separated)', hint: 'Flutter, Dart, 2+ years experience', maxLines: 2, maxLength: 2000),
      _buildField(key: 'benefits', label: 'Benefits (comma-separated)', hint: 'Health insurance, flexible hours', maxLines: 2, maxLength: 2000),

      const SizedBox(height: 20),
      _buildImageSelector(),
    ];
  }

  List<Widget> _buildServicesForm() {
    return [
      _buildField(key: 'serviceName', label: 'Service Name', hint: 'Visa Consultation', maxLength: 100),
      _buildField(key: 'providerName', label: 'Provider Name', hint: 'Max Mustermann', maxLength: 100),
      _buildDropdown(
        label: 'Service Type',
        value: _serviceType,
        items: ['Immigration', 'Legal', 'Financial', 'Tax', 'Consultation', 'Home Services', 'Tuition & Coaching', 'IT Services', 'Education', 'Relocation', 'Translation', 'Other'],
        onChanged: (val) => setState(() => _serviceType = val ?? 'Immigration'),
      ),
      _buildField(key: 'priceRange', label: 'Price Range', hint: '€50/hour', maxLength: 100),
      _buildField(key: 'city', label: 'City', hint: 'Munich', maxLength: 50),
      _buildField(key: 'postalCode', label: 'Postal Code', hint: '80331', maxLength: 20),
      _buildField(key: 'area', label: 'Area', hint: 'Maxvorstadt', maxLength: 100),
      _buildField(key: 'address', label: 'Address', hint: 'Street, No.', maxLength: 200),
      _buildField(key: 'contactPhone', label: 'Contact Phone', hint: '491701234567', maxLength: 20),
      _buildField(key: 'whatsapp', label: 'WhatsApp', hint: '491701234567', required: false, maxLength: 20),
      _buildField(key: 'email', label: 'Email', hint: 'name@example.com', maxLength: 100),
      _buildField(key: 'website', label: 'Website', hint: 'https://example.com', required: false, maxLength: 200),
      _buildField(key: 'latitude', label: 'Latitude', hint: '48.137154', required: false, maxLength: 20),
      _buildField(key: 'longitude', label: 'Longitude', hint: '11.576124', required: false, maxLength: 20),
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
    } else if (widget.category == 'Food') {
      formFields = _buildFoodForm();
    } else if (widget.category == 'Jobs') {
      formFields = _buildJobsForm();
    } else {
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
