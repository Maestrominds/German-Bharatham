import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import '../user_session.dart';
import '../services/api_config.dart';

class PersonalInformationPage extends StatefulWidget {
  final bool isInitialSetup;
  final void Function(BuildContext context)? onSetupComplete;

  const PersonalInformationPage({
    super.key,
    this.isInitialSetup = false,
    this.onSetupComplete,
  });

  static const Color primaryGreen = Color(0xFF4E7F6D);

  @override
  State<PersonalInformationPage> createState() =>
      _PersonalInformationPageState();
}

class _PersonalInformationPageState extends State<PersonalInformationPage> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  final TextEditingController name = TextEditingController();
  final TextEditingController phone = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController dob = TextEditingController();
  String? _selectedGender;
  final TextEditingController location = TextEditingController();
  final TextEditingController preferredCity = TextEditingController();
  final TextEditingController education = TextEditingController();
  final TextEditingController profession = TextEditingController();
  final TextEditingController germanLevel = TextEditingController();
  final TextEditingController stateOfOrigin = TextEditingController();
  final TextEditingController motherTongue = TextEditingController();
  final TextEditingController linkedinUrl = TextEditingController();
  final TextEditingController industry = TextEditingController();

  // Career level dropdown
  String? _selectedCareerLevel;

  static const List<String> _careerLevelOptions = [
    'Student',
    'Working Professional',
    'Job Seeker',
    'Self-employed',
  ];

  // Dynamic dropdown lists with fallback defaults
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

  List<String> _languageOptions = [
    'English',
    'German',
    'Tamil',
    'Hindi',
    'Telugu',
    'Malayalam',
    'Kannada',
    'Marathi',
    'Bengali',
    'Gujarati',
    'Punjabi',
    'Other',
  ];

  List<String> _cityOptions = [
    'Berlin',
    'Munich',
    'Frankfurt',
    'Hamburg',
    'Stuttgart',
    'Düsseldorf',
    'Cologne',
    'Leipzig',
    'Dresden',
    'Nuremberg',
    'Hanover',
    'Bonn',
    'Mannheim',
    'Karlsruhe',
    'Aachen',
    'Other',
  ];

  String? _photoBase64 = UserSession.instance.photoBase64;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadData();
    _fetchDropdownOptions();
  }

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    email.dispose();
    dob.dispose();
    location.dispose();
    preferredCity.dispose();
    education.dispose();
    profession.dispose();
    germanLevel.dispose();
    stateOfOrigin.dispose();
    motherTongue.dispose();
    linkedinUrl.dispose();
    industry.dispose();
    super.dispose();
  }

  Future<void> _fetchDropdownOptions() async {
    try {
      // 🌟 Fetch dynamic options directly from dedicated backend database endpoint
      final res = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/api/profile-options'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (!mounted) return;
        setState(() {
          if (data['domains'] is List) {
            final list = (data['domains'] as List)
                .map((e) => e is Map ? e['name']?.toString().trim() ?? '' : e.toString().trim())
                .where((name) => name.isNotEmpty)
                .toList();
            if (list.isNotEmpty) _domainOptions = list;
          }
          if (data['languages'] is List) {
            final list = (data['languages'] as List)
                .map((e) => e is Map ? e['name']?.toString().trim() ?? '' : e.toString().trim())
                .where((name) => name.isNotEmpty)
                .toList();
            if (list.isNotEmpty) _languageOptions = list;
          }
          if (data['cities'] is List) {
            final list = (data['cities'] as List)
                .map((e) => e is Map ? e['name']?.toString().trim() ?? '' : e.toString().trim())
                .where((name) => name.isNotEmpty)
                .toList();
            if (list.isNotEmpty) _cityOptions = list;
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _loadData() async {
    // First load from SharedPreferences as a quick cache
    final prefs = await SharedPreferences.getInstance();
    final uid = UserSession.instance.userId ?? 'guest';
    String key(String field) => 'pi_${uid}_$field';
    setState(() {
      name.text = prefs.getString(key('name')) ?? (UserSession.instance.name ?? '');
      phone.text = prefs.getString(key('phone')) ?? (UserSession.instance.phone ?? '');
      email.text = prefs.getString(key('email')) ?? (UserSession.instance.email ?? '');
      dob.text = prefs.getString(key('dob')) ?? '';
      _selectedGender = prefs.getString(key('gender')) ?? '';
      location.text = prefs.getString(key('location')) ?? '';
      preferredCity.text = prefs.getString(key('preferredCity')) ?? '';
      education.text = prefs.getString(key('education')) ?? '';
      profession.text = prefs.getString(key('profession')) ?? '';
      germanLevel.text = prefs.getString(key('germanLevel')) ?? '';
      stateOfOrigin.text = prefs.getString(key('stateOfOrigin')) ?? '';
      motherTongue.text = prefs.getString(key('motherTongue')) ?? '';
      linkedinUrl.text = prefs.getString(key('linkedinUrl')) ?? '';
      _selectedCareerLevel = prefs.getString(key('careerLevel'));
      industry.text = prefs.getString(key('industry')) ?? '';
      _photoBase64 = prefs.getString(key('photo')) ?? UserSession.instance.photoBase64;
    });

    // Then fetch from backend if logged in
    final token = UserSession.instance.token;
    if (token == null) return;
    try {
      final res = await http.get(
        Uri.parse(ApiConfig.profileEndpoint),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        setState(() {
          name.text = data['name'] ?? name.text;
          phone.text = data['phone'] ?? phone.text;
          email.text = data['email'] ?? email.text;
          dob.text = data['dob'] ?? dob.text;
          _selectedGender = data['gender'] as String? ?? _selectedGender ?? '';
          location.text = data['location'] ?? location.text;
          preferredCity.text = data['preferredCity'] ?? preferredCity.text;
          education.text = data['education'] ?? education.text;
          profession.text = data['profession'] ?? profession.text;
          germanLevel.text = data['germanLevel'] ?? germanLevel.text;
          stateOfOrigin.text = data['stateOfOrigin'] ?? stateOfOrigin.text;
          motherTongue.text = data['motherTongue'] ?? motherTongue.text;
          linkedinUrl.text = data['linkedinUrl'] ?? linkedinUrl.text;
          _selectedCareerLevel = data['careerLevel'] as String? ?? _selectedCareerLevel;
          industry.text = data['industry'] ?? industry.text;
          _photoBase64 = data['photo'] ?? _photoBase64;
        });
        // Update local cache
        await prefs.setString(key('name'), name.text);
        await prefs.setString(key('phone'), phone.text);
        await prefs.setString(key('email'), email.text);
        await prefs.setString(key('dob'), dob.text);
        await prefs.setString(key('gender'), _selectedGender ?? '');
        await prefs.setString(key('location'), location.text);
        await prefs.setString(key('preferredCity'), preferredCity.text);
        await prefs.setString(key('education'), education.text);
        await prefs.setString(key('profession'), profession.text);
        await prefs.setString(key('germanLevel'), germanLevel.text);
        await prefs.setString(key('stateOfOrigin'), stateOfOrigin.text);
        await prefs.setString(key('motherTongue'), motherTongue.text);
        await prefs.setString(key('linkedinUrl'), linkedinUrl.text);
        await prefs.setString(key('careerLevel'), _selectedCareerLevel ?? '');
        await prefs.setString(key('industry'), industry.text);
        await prefs.setString(key('photo'), _photoBase64 ?? '');
      }
    } catch (_) {}
  }

  Future<void> _saveData() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final token = UserSession.instance.token;
      if (token != null) {
        try {
          final res = await http.put(
            Uri.parse(ApiConfig.profileEndpoint),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'name': name.text.trim(),
              'phone': phone.text.trim(),
              'dob': dob.text.trim(),
              'gender': _selectedGender ?? '',
              'location': location.text.trim(),
              'preferredCity': preferredCity.text.trim(),
              'education': education.text.trim(),
              'profession': profession.text.trim(),
              'germanLevel': germanLevel.text.trim(),
              'stateOfOrigin': stateOfOrigin.text.trim(),
              'motherTongue': motherTongue.text.trim(),
              'linkedinUrl': linkedinUrl.text.trim(),
              'careerLevel': _selectedCareerLevel ?? '',
              'industry': industry.text.trim(),
              'photo': _photoBase64 ?? '',
            }),
          ).timeout(const Duration(seconds: 15));
          if (res.statusCode != 200 && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Save failed: ${jsonDecode(res.body)['message'] ?? res.statusCode}')),
            );
            return;
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Network error: $e')),
            );
          }
          return;
        }
      }

      // Also save to SharedPreferences as local cache
      final prefs = await SharedPreferences.getInstance();
      final uid = UserSession.instance.userId ?? 'guest';
      String key(String field) => 'pi_${uid}_$field';
      await prefs.setString(key('name'), name.text.trim());
      await prefs.setString(key('phone'), phone.text.trim());
      await prefs.setString(key('email'), email.text.trim());
      await prefs.setString(key('dob'), dob.text.trim());
      await prefs.setString(key('gender'), _selectedGender ?? '');
      await prefs.setString(key('location'), location.text.trim());
      await prefs.setString(key('preferredCity'), preferredCity.text.trim());
      await prefs.setString(key('education'), education.text.trim());
      await prefs.setString(key('profession'), profession.text.trim());
      await prefs.setString(key('germanLevel'), germanLevel.text.trim());
      await prefs.setString(key('stateOfOrigin'), stateOfOrigin.text.trim());
      await prefs.setString(key('motherTongue'), motherTongue.text.trim());
      await prefs.setString(key('linkedinUrl'), linkedinUrl.text.trim());
      await prefs.setString(key('careerLevel'), _selectedCareerLevel ?? '');
      await prefs.setString(key('industry'), industry.text.trim());
      await prefs.setString(key('photo'), _photoBase64 ?? '');

      // Update global session cache so the UI updates immediately
      await UserSession.instance.updateProfile(
        name: name.text.trim(),
        phone: phone.text.trim(),
        photoBase64: _photoBase64,
      );

      if (mounted) {
        if (widget.isInitialSetup && widget.onSetupComplete != null) {
          widget.onSetupComplete!(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile Updated Successfully")),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text("Personal Information"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: widget.isInitialSetup
            ? const SizedBox.shrink()
            : IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: Image.asset(
                  'assets/images/left-arrow.png',
                  width: 22,
                  height: 22,
                ),
              ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: _cardDecoration(),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _profilePicture(),
                      const SizedBox(height: 24),
                      _input("Full Name", name, required: true),
                      _input("Phone Number", phone, required: true),
                      _input("Email", email),
                      _dobPicker(),
                      _genderRadio(),
                      _input("Current Location", location),

                      // Compulsory: City in Germany (Searchable / Scrollable dropdown)
                      SearchableDropdownInput(
                        label: "Preferred City in Germany",
                        controller: preferredCity,
                        options: _cityOptions,
                        hintText: "Type or select city (e.g. Berlin, Munich)",
                        isRequired: true,
                      ),

                      _careerLevelDropdown(),
                      _input("Education (Last/Current Degree)", education),

                      // Compulsory: Domain / Industry (Searchable / Scrollable dropdown)
                      SearchableDropdownInput(
                        label: "Domain / Industry",
                        controller: industry,
                        options: _domainOptions,
                        hintText: "Type or select domain (e.g. IT, Medical)",
                        isRequired: true,
                      ),

                      _input("Profession", profession),
                      _input("German Language Level (A1, A2, B1, B2)", germanLevel),
                      _input("State of Origin (e.g. Maharashtra, India)", stateOfOrigin),

                      // Compulsory: Language / Mother Tongue (Searchable / Scrollable dropdown)
                      SearchableDropdownInput(
                        label: "Language / Mother Tongue",
                        controller: motherTongue,
                        options: _languageOptions,
                        hintText: "Type or select language (e.g. Tamil, German)",
                        isRequired: true,
                      ),

                      // Compulsory: LinkedIn URL
                      _linkedinInput(),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saving
                              ? null
                              : () {
                                  bool isValid = _formKey.currentState!.validate();

                                  if (name.text.trim().isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Please enter your full name')),
                                    );
                                    isValid = false;
                                  }

                                  if (phone.text.trim().isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Please enter your phone number')),
                                    );
                                    isValid = false;
                                  }

                                  if (_selectedGender == null || _selectedGender!.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Please select your gender')),
                                    );
                                    isValid = false;
                                  }

                                  if (dob.text.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Please select your date of birth')),
                                    );
                                    isValid = false;
                                  }

                                  // Compulsory check: City
                                  if (preferredCity.text.trim().isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('City in Germany is required')),
                                    );
                                    isValid = false;
                                  }

                                  if (_selectedCareerLevel == null || _selectedCareerLevel!.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Please select your career level')),
                                    );
                                    isValid = false;
                                  }

                                  // Compulsory check: Domain
                                  if (industry.text.trim().isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Domain is required')),
                                    );
                                    isValid = false;
                                  }

                                  // Compulsory check: Language
                                  if (motherTongue.text.trim().isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Language is required')),
                                    );
                                    isValid = false;
                                  }

                                  // Compulsory check: LinkedIn URL
                                  if (linkedinUrl.text.trim().isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('LinkedIn URL is required')),
                                    );
                                    isValid = false;
                                  } else {
                                    final uri = Uri.tryParse(linkedinUrl.text.trim());
                                    if (uri == null || !uri.hasScheme || !uri.host.contains('linkedin')) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Please enter a valid LinkedIn URL (e.g. https://linkedin.com/in/yourprofile)')),
                                      );
                                      isValid = false;
                                    }
                                  }

                                  // Photo check
                                  final photo = _photoBase64?.trim() ?? '';
                                  final photoOk = photo.startsWith('data:image') ||
                                      photo.startsWith('http');
                                  if (!photoOk) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Please add a profile photo to continue'),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                    isValid = false;
                                  }

                                  if (isValid) {
                                    _saveData();
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PersonalInformationPage.primaryGreen,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  widget.isInitialSetup ? "Complete Setup" : "Save Changes",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _genderRadio() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Gender",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildGenderOption("Male"),
              const SizedBox(width: 16),
              _buildGenderOption("Female"),
              const SizedBox(width: 16),
              _buildGenderOption("Other"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenderOption(String value) {
    final isSelected = _selectedGender == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGender = value;
        });
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? PersonalInformationPage.primaryGreen : Colors.grey,
                width: 2,
              ),
            ),
            child: isSelected
                ? Center(
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: PersonalInformationPage.primaryGreen,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _dobPicker() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Date of Birth",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _pickDate,
            child: AbsorbPointer(
              child: TextFormField(
                controller: dob,
                decoration: InputDecoration(
                  hintText: "DD/MM/YYYY",
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  suffixIcon: const Icon(Icons.calendar_today,
                      color: PersonalInformationPage.primaryGreen, size: 20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _input(String label, TextEditingController controller, {bool required = false}) {
    final isPhone = label.toLowerCase().contains("phone");
    final isGerman = label.toLowerCase().contains("german");
    int limit = 100;
    if (isPhone) limit = 15;
    else if (isGerman) limit = 15;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              if (required)
                const Text(
                  ' *',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            maxLength: limit,
            keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
            inputFormatters: isPhone ? [FilteringTextInputFormatter.digitsOnly] : null,
            decoration: InputDecoration(
              counterText: "",
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: PersonalInformationPage.primaryGreen, width: 1.5),
              ),
            ),
            validator: required
                ? (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Required field";
                    }
                    return null;
                  }
                : null,
          ),
        ],
      ),
    );
  }

  /// LinkedIn URL field with URL validation
  Widget _linkedinInput() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text(
                'LinkedIn URL',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Text(
                ' *',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: linkedinUrl,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              hintText: 'https://linkedin.com/in/yourprofile',
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: PersonalInformationPage.primaryGreen, width: 1.5),
              ),
              prefixIcon: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                child: Icon(Icons.link, color: PersonalInformationPage.primaryGreen, size: 20),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'LinkedIn URL is required';
              }
              final uri = Uri.tryParse(value.trim());
              if (uri == null || !uri.hasScheme || !uri.host.contains('linkedin')) {
                return 'Please enter a valid LinkedIn URL';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  /// Career Level dropdown
  Widget _careerLevelDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Career Level',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _careerLevelOptions.contains(_selectedCareerLevel)
                ? _selectedCareerLevel
                : null,
            hint: const Text('Select career level'),
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: PersonalInformationPage.primaryGreen, width: 1.5),
              ),
            ),
            items: _careerLevelOptions.map((level) {
              return DropdownMenuItem(value: level, child: Text(level));
            }).toList(),
            onChanged: (val) => setState(() => _selectedCareerLevel = val),
            validator: (val) =>
                (val == null || val.isEmpty) ? 'Please select your career level' : null,
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    DateTime? initialDate;
    if (dob.text.isNotEmpty) {
      try {
        final parts = dob.text.split('/');
        if (parts.length == 3) {
          initialDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        }
      } catch (_) {}
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime(2000),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: PersonalInformationPage.primaryGreen,
            onPrimary: Colors.white,
            onSurface: Colors.black87,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final formatted =
          "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      setState(() {
        dob.text = formatted;
      });
    }
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  Widget _profilePicture() {
    ImageProvider? imageProvider;
    if (_photoBase64 != null && _photoBase64!.trim().isNotEmpty) {
      try {
        if (_photoBase64!.startsWith('http')) {
          imageProvider = NetworkImage(_photoBase64!);
        } else {
          final raw = _photoBase64!.contains(',') ? _photoBase64!.split(',').last : _photoBase64!;
          imageProvider = MemoryImage(base64Decode(raw));
        }
      } catch (_) {}
    }

    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: Stack(
          children: [
            CircleAvatar(
              radius: 56,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: imageProvider,
              child: imageProvider == null
                  ? const Icon(Icons.person, size: 60, color: Colors.white)
                  : null,
            ),
            const Positioned(
              bottom: 0,
              right: 4,
              child: CircleAvatar(
                backgroundColor: PersonalInformationPage.primaryGreen,
                radius: 16,
                child: Icon(Icons.camera_alt, color: Colors.white, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 60);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _photoBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
      }
    }
  }
}

/// 🌟 Searchable, scrollable dropdown field with live filtering,
/// showing up to 4 items at a time and supporting custom typed values.
class SearchableDropdownInput extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final List<String> options;
  final String hintText;
  final bool isRequired;
  final String? Function(String?)? validator;

  const SearchableDropdownInput({
    super.key,
    required this.label,
    required this.controller,
    required this.options,
    this.hintText = '',
    this.isRequired = false,
    this.validator,
  });

  @override
  State<SearchableDropdownInput> createState() => _SearchableDropdownInputState();
}

class _SearchableDropdownInputState extends State<SearchableDropdownInput> {
  final FocusNode _focusNode = FocusNode();
  bool _isOpen = false;
  String _filter = '';

  @override
  void initState() {
    super.initState();
    _filter = widget.controller.text;
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() {
          _isOpen = true;
          _filter = widget.controller.text;
        });
      }
    });
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (_filter != widget.controller.text) {
      setState(() {
        _filter = widget.controller.text;
        if (!_isOpen && _focusNode.hasFocus) {
          _isOpen = true;
        }
      });
    }
  }

  List<String> _getFilteredOptions() {
    final query = _filter.trim().toLowerCase();
    if (query.isEmpty) {
      return widget.options;
    }
    return widget.options
        .where((opt) => opt.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredOptions();
    final hasExactMatch = widget.options.any(
      (opt) => opt.trim().toLowerCase() == widget.controller.text.trim().toLowerCase(),
    );
    final isCustomValue = widget.controller.text.trim().isNotEmpty && !hasExactMatch;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              if (widget.isRequired)
                const Text(
                  ' *',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            decoration: InputDecoration(
              hintText: widget.hintText,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: PersonalInformationPage.primaryGreen, width: 1.5),
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.controller.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                      onPressed: () {
                        widget.controller.clear();
                        setState(() {
                          _filter = '';
                          _isOpen = true;
                        });
                      },
                    ),
                  IconButton(
                    icon: Icon(
                      _isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: PersonalInformationPage.primaryGreen,
                    ),
                    onPressed: () {
                      setState(() {
                        _isOpen = !_isOpen;
                        if (_isOpen && !_focusNode.hasFocus) {
                          _focusNode.requestFocus();
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
            validator: widget.validator ??
                (widget.isRequired
                    ? (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'This field is required';
                        }
                        return null;
                      }
                    : null),
          ),
          if (_isOpen) ...[
            const SizedBox(height: 4),
            Container(
              constraints: const BoxConstraints(maxHeight: 180), // Shows ~4 items and allows scrolling
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Scrollbar(
                  thumbVisibility: true,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    shrinkWrap: true,
                    itemCount: filtered.length + (isCustomValue ? 1 : 0),
                    separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
                    itemBuilder: (context, index) {
                      // Custom typed value option at the top
                      if (isCustomValue && index == 0) {
                        return InkWell(
                          onTap: () {
                            setState(() => _isOpen = false);
                            _focusNode.unfocus();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            color: const Color(0xFFF0FDF4),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_outline, size: 18, color: PersonalInformationPage.primaryGreen),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Use custom: "${widget.controller.text.trim()}"',
                                    style: const TextStyle(
                                      color: PersonalInformationPage.primaryGreen,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final option = filtered[isCustomValue ? index - 1 : index];
                      final isSelected = option.trim().toLowerCase() == widget.controller.text.trim().toLowerCase();

                      return InkWell(
                        onTap: () {
                          widget.controller.text = option;
                          setState(() {
                            _filter = option;
                            _isOpen = false;
                          });
                          _focusNode.unfocus();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          color: isSelected ? const Color(0xFFE8F5E8) : Colors.transparent,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  option,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                    color: isSelected ? PersonalInformationPage.primaryGreen : Colors.black87,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check, size: 16, color: PersonalInformationPage.primaryGreen),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
