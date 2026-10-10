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

  // New dropdowns
  String? _selectedCareerLevel;
  String? _selectedIndustry;

  static const List<String> _careerLevelOptions = [
    'Student',
    'Working Professional',
    'Job Seeker',
    'Self-employed',
  ];

  static const List<String> _industryOptions = [
    'IT / Technology',
    'Biotechnology / Life Sciences',
    'Healthcare / Medicine',
    'Finance / Banking',
    'Engineering / Manufacturing',
    'Marketing / Sales',
    'Legal / Law',
    'Education / Academia',
    'Other',
  ];

  String? _photoBase64 = UserSession.instance.photoBase64;
  final ImagePicker _picker = ImagePicker();

  static const Color primaryGreen = Color(0xFF4E7F6D);

  @override
  void initState() {
    super.initState();
    _loadData();
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
      _selectedIndustry = prefs.getString(key('industry'));
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
          _selectedIndustry = data['industry'] as String? ?? _selectedIndustry;
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
        await prefs.setString(key('industry'), _selectedIndustry ?? '');
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
              'name': name.text,
              'phone': phone.text,
              'dob': dob.text,
              'gender': _selectedGender ?? '',
              'location': location.text,
              'preferredCity': preferredCity.text,
              'education': education.text,
              'profession': profession.text,
              'germanLevel': germanLevel.text,
              'stateOfOrigin': stateOfOrigin.text,
              'motherTongue': motherTongue.text,
              'linkedinUrl': linkedinUrl.text,
              'careerLevel': _selectedCareerLevel ?? '',
              'industry': _selectedIndustry ?? '',
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
      await prefs.setString(key('industry'), _selectedIndustry ?? '');
      await prefs.setString(key('photo'), _photoBase64 ?? '');

      // Update global session cache so the UI updates immediately
      await UserSession.instance.updateProfile(
        name: name.text,
        phone: phone.text,
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
                      _input("Full Name", name),
                      _input("Phone Number", phone),
                      _input("Email", email),
                      _dobPicker(),
                      _genderRadio(),
                      _input("Current Location", location),
                      _input("Preferred City in Germany", preferredCity),
                      _careerLevelDropdown(),
                      _input("Education (Last/Current Degree)", education),
                      _industryDropdown(),
                      _input("Profession", profession),
                      _input("German Language Level (A1, A2, B1, B2)", germanLevel),
                      _input("State of Origin (e.g. Maharashtra, India)", stateOfOrigin),
                      _input("Mother Tongue", motherTongue),
                      _linkedinInput(),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saving
                              ? null
                              : () {
                                  bool isValid = _formKey.currentState!.validate();
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
                                  if (_selectedCareerLevel == null || _selectedCareerLevel!.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Please select your career level')),
                                    );
                                    isValid = false;
                                  }
                                  if (_selectedIndustry == null || _selectedIndustry!.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Please select your industry')),
                                    );
                                    isValid = false;
                                  }
                                  // Photo must be a real user-uploaded base64 image
                                  // or an already-uploaded Cloudinary URL (http...).
                                  // A Google/social profile URL does NOT count — but
                                  // Cloudinary URLs are from our own upload flow.
                                  final _photo = _photoBase64?.trim() ?? '';
                                  final photoOk = _photo.startsWith('data:image') ||
                                      _photo.startsWith('http');
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
                            backgroundColor: primaryGreen,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Save Information",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_saving)
              Container(
                color: Colors.black.withOpacity(0.15),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _input(String label, TextEditingController controller, {bool required = true}) {
    bool isPhone = label.toLowerCase().contains("phone");
    bool isGerman = label.toLowerCase().contains("german");

    int limit = 100;
    if (isPhone) limit = 15;
    else if (isGerman) limit = 15;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            maxLength: limit,
            keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
            inputFormatters: isPhone ? [FilteringTextInputFormatter.digitsOnly] : null,
            decoration: InputDecoration(
              counterText: "", // Hides the character counter below input
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
                borderSide: const BorderSide(color: primaryGreen, width: 1.5),
              ),
            ),
            validator: required
                ? (value) {
                    if (value == null || value.isEmpty) {
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
          const Text(
            'LinkedIn URL',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
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
                borderSide: const BorderSide(color: primaryGreen, width: 1.5),
              ),
              prefixIcon: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                child: Icon(Icons.link, color: primaryGreen, size: 20),
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
                borderSide: const BorderSide(color: primaryGreen, width: 1.5),
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

  /// Industry / Specialization dropdown
  Widget _industryDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Industry / Specialization',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _industryOptions.contains(_selectedIndustry)
                ? _selectedIndustry
                : null,
            hint: const Text('Select industry'),
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
                borderSide: const BorderSide(color: primaryGreen, width: 1.5),
              ),
            ),
            items: _industryOptions.map((industry) {
              return DropdownMenuItem(value: industry, child: Text(industry));
            }).toList(),
            onChanged: (val) => setState(() => _selectedIndustry = val),
            validator: (val) =>
                (val == null || val.isEmpty) ? 'Please select your industry' : null,
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
            primary: primaryGreen,
            onPrimary: Colors.white,
            onSurface: Colors.black87,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        dob.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  Widget _dobPicker() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Date of Birth',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      dob.text.isNotEmpty ? dob.text : 'Select date',
                      style: TextStyle(
                        fontSize: 15,
                        color: dob.text.isNotEmpty ? Colors.black87 : Colors.grey,
                      ),
                    ),
                  ),
                  const Icon(Icons.event, color: primaryGreen, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _genderRadio() {
    const options = ['Male', 'Female', 'Other'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gender',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: options.map((option) {
                return RadioListTile<String>(
                  title: Text(option, style: const TextStyle(fontSize: 15)),
                  value: option,
                  groupValue: _selectedGender,
                  activeColor: primaryGreen,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  visualDensity: VisualDensity.compact,
                  onChanged: (v) => setState(() => _selectedGender = v),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
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
                  ? Icon(Icons.person, size: 60, color: Colors.white)
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 4,
              child: CircleAvatar(
                backgroundColor: primaryGreen,
                radius: 16,
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
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
