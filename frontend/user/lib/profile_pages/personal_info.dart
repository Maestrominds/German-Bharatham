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
  final TextEditingController passport = TextEditingController();

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
      passport.text = prefs.getString(key('passport')) ?? '';
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
          passport.text = data['passport'] ?? passport.text;
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
        await prefs.setString(key('passport'), passport.text);
        await prefs.setString(key('photo'), _photoBase64 ?? '');
      }
    } catch (_) {}
  }

  Future<void> _saveData() async {
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
            'passport': passport.text,
            'photo': _photoBase64 ?? '',
          }),
        );
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
    await prefs.setString(key('passport'), passport.text);
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
      body: SingleChildScrollView(
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
                _input("Education", education),
                _input("Profession", profession),
                _input("German Language Level (A1, A2, B1, B2)", germanLevel),
                _input("Passport Number", passport),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
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
                      if (_photoBase64 == null || _photoBase64!.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please upload a profile picture')),
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
                    child: const Text("Save Information",style: TextStyle(color: Colors.white,fontSize: 16,fontWeight: FontWeight.w600,),),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _input(String label, TextEditingController controller) {
    bool isPhone = label.toLowerCase().contains("phone");
    bool isPassport = label.toLowerCase().contains("passport");
    bool isGerman = label.toLowerCase().contains("german");

    int limit = 100;
    if (isPhone) limit = 15;
    else if (isPassport) limit = 20;
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
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "Required field";
            }
            return null;
          },
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
        final raw = _photoBase64!.contains(',') ? _photoBase64!.split(',').last : _photoBase64!;
        imageProvider = MemoryImage(base64Decode(raw));
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
