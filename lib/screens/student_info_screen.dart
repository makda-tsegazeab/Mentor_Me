import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import 'package:http/http.dart' as http;

class StudentInfoScreen extends StatefulWidget {
  const StudentInfoScreen({super.key});

  @override
  State<StudentInfoScreen> createState() => _StudentInfoScreenState();
}

class _StudentInfoScreenState extends State<StudentInfoScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _cityController = TextEditingController();
  final _maxPriceController = TextEditingController();

  String? _selectedSex;
  String? _selectedGradeGroup;
  String _preferredTutorGender = 'No preference';
  String? _selectedHours;
  String? _selectedDays;

  List<String> selectedSubjects = [];
  File? _selectedImage;
  bool _isUploading = false;
  bool _sexError = false;
  bool _studentSubjectsError = false;
  bool _studentGradeError = false;

  final List<String> sexOptions = ['Male', 'Female'];
  final List<String> tutorGenderOptions = ['Male', 'Female', 'No preference'];
  final List<String> gradeGroups = [
    '5-6',
    '7-8',
    '9-10',
    '11-12',
  ];
  final List<String> subjects = [
    'Mathematics',
    'English',
    'Amharic',
    'Tigrigna',
    'Physics',
    'Chemistry',
    'Biology',
    'ICT',
    'History',
    'Geography',
    'Civics',
    'Art',
    'Economics',
    'Social Studies',
    'Physical Education',
    'Ethics',
  ];

  // Cities list from requirements
  final List<String> _allCities = const [
    "Mekelle",
    "Aksum",
    "Adwa",
    "Abi Adi",
    "Maychew",
    "Hagere Selam",
    "Enticho",
    "Yeha",
    "Rama",
    "Adet",
    "Tanqua Melash",
    "Laelay Maychew",
    "Tahtay Maychew",
    "Edaga Arbi",
    "Adigrat",
    "Wukro",
    "Hawzen",
    "Idaga Hamus",
    "Freweyni",
    "Zalambessa",
    "Atsbi",
    "Agulae",
    "Bizet",
    "Alamata",
    "Korem",
    "Mekoni",
    "Ofla",
    "Hiwane",
    "Waja",
    "Selewa",
    "Emba Alaje",
    "Shire (Inda Selassie)",
    "Sheraro",
    "Adi Daero",
    "Selekleka",
    "May Tsebri",
    "Inda Aba Guna",
    "Humera",
    "Dansha",
    "May Kadra",
    "Adi Remets",
    "Tsegede",
    "Tselemti",
  ];

  // Cloudinary configuration
  final String _cloudName = 'db4edv0oh';
  final String _apiKey = '278836196421443';
  final String _uploadPreset = 'mentorme_uploads';

  @override
  void initState() {
    super.initState();
    // Defaults so sliders and validation have non-zero values even before user interaction
    _selectedHours = '2';
    _selectedDays = '3';
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _cityController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (!doc.exists) return;
    final data = doc.data() ?? {};

    setState(() {
      final name = data['name'];
      if (name is String) _nameController.text = name;

      final age = data['age'];
      if (age != null) _ageController.text = age.toString();

      final city = data['city'];
      if (city is String) _cityController.text = city;

      final sex = data['sex'];
      if (sex is String) _selectedSex = sex;

      final gradeLevels = data['gradeLevels'];
      if (gradeLevels is List &&
          gradeLevels.isNotEmpty &&
          gradeLevels.first is String) {
        _selectedGradeGroup = gradeLevels.first as String;
      }

      final prefGender = data['preferredTutorGender'];
      if (prefGender is String && prefGender.isNotEmpty) {
        _preferredTutorGender = prefGender;
      }

      final maxPrice = data['maxPricePerHour'];
      if (maxPrice != null) _maxPriceController.text = maxPrice.toString();

      final subs = data['subjects'];
      if (subs is List) selectedSubjects = subs.whereType<String>().toList();

      final hours = data['hoursPerDay'];
      if (hours != null) _selectedHours = hours.toString();

      final days = data['daysPerWeek'];
      if (days != null) _selectedDays = days.toString();
    });
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() => _selectedImage = File(picked.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<String?> _uploadToCloudinary(File image) async {
    try {
      setState(() => _isUploading = true);

      final url =
          Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = _uploadPreset
        ..fields['folder'] = 'mentorme_profiles'
        ..files.add(await http.MultipartFile.fromPath('file', image.path));

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonData = json.decode(responseData);
        return jsonData['secure_url'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final hasRequired = _hasRequiredStudentFields(markErrors: true);
    if (!hasRequired) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please complete all required learner fields to continue.',
            style: GoogleFonts.lexend(),
          ),
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await _uploadToCloudinary(_selectedImage!);
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'role': 'student',
        'name': _nameController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()) ?? 0,
        'sex': _selectedSex,
        'city': _cityController.text.trim(),
        'gradeLevels': [_selectedGradeGroup],
        'subjects': selectedSubjects,
        'preferredTutorGender': _preferredTutorGender,
        'hoursPerDay': int.tryParse(_selectedHours ?? '0') ?? 0,
        'daysPerWeek': int.tryParse(_selectedDays ?? '0') ?? 0,
        'maxPricePerHour': double.tryParse(
                _maxPriceController.text.trim().replaceAll(',', '')) ??
            0,
        'profileImage': imageUrl,
        'completedProfile': hasRequired,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (hasRequired) {
        final notif = Provider.of<NotificationProvider>(context, listen: false);
        final docRef =
            FirebaseFirestore.instance.collection('users').doc(user.uid);
        final existing = await docRef.get();
        final welcomeSent = existing.data()?['welcomeSent'] == true;
        if (!welcomeSent) {
          await notif.createNotification(
            userId: user.uid,
            title: 'Welcome!',
            body: 'Thanks for completing your profile. Start exploring tutors and learners.',
            type: 'welcome',
            data: {},
          );
          await docRef.update({'welcomeSent': true});
        }
      }

      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving profile: $e')),
      );
    }
  }

  bool _hasRequiredStudentFields({bool markErrors = false}) {
    final name = _nameController.text.trim();
    final city = _cityController.text.trim();
    final age = int.tryParse(_ageController.text.trim());
    final sex = _selectedSex;
    final grade = _selectedGradeGroup;
    final subjectsValid = selectedSubjects.isNotEmpty;
    final hours = int.tryParse(_selectedHours ?? '0');
    final days = int.tryParse(_selectedDays ?? '0');
    final maxPrice = _parseDoubleInput(_maxPriceController.text.trim());

    final valid = name.isNotEmpty &&
        city.isNotEmpty &&
        age != null &&
        age > 0 &&
        sex != null &&
        grade != null &&
        subjectsValid &&
        hours != null &&
        hours > 0 &&
        days != null &&
        days > 0 &&
        maxPrice != null &&
        maxPrice > 0;

    if (markErrors) {
      setState(() {
        _sexError = sex == null;
        _studentSubjectsError = !subjectsValid;
        _studentGradeError = grade == null;
      });
    }

    return valid;
  }

  double? _parseDoubleInput(String value) {
    if (value.isEmpty) return null;
    return double.tryParse(value.replaceAll(',', ''));
  }

  String? _positiveIntValidator(String? value, String label) {
    if (value == null || value.trim().isEmpty) return 'Enter $label';
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed <= 0) return 'Enter valid $label';
    return null;
  }

  String? _positiveDoubleValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter price';
    final parsed = _parseDoubleInput(value.trim());
    if (parsed == null || parsed <= 0) return 'Enter valid price';
    return null;
  }

  InputDecoration _input({
    required String hint,
    Widget? prefix,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.lexend(
        color: const Color(0xFF617589),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      prefixIcon: prefix,
      suffixIcon: suffix,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD1D1D1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD1D1D1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2B8CEE), width: 1.2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.lexendTextTheme(Theme.of(context).textTheme);
    final double hoursVal =
        ((double.tryParse(_selectedHours ?? '2') ?? 2).clamp(1, 4)).toDouble();
    final double daysVal =
        ((double.tryParse(_selectedDays ?? '3') ?? 3).clamp(1, 7)).toDouble();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        title: Text(
          'Create Learner Profile',
          style: GoogleFonts.lexend(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF111418),
            fontSize: 16,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        actions: const [SizedBox(width: 48)],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header - CHANGED: White background and Lexend font
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            children: [
                              Container(
                                height: 128,
                                width: 128,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                  color: Colors.grey.shade200,
                                  image: _selectedImage != null
                                      ? DecorationImage(
                                          fit: BoxFit.cover,
                                          image: FileImage(_selectedImage!),
                                        )
                                      : null,
                                ),
                                child: _selectedImage == null
                                    ? const Icon(Icons.person,
                                        size: 52, color: Color(0xFF9BA5B0))
                                    : null,
                              ),
                              Positioned(
                                bottom: 4,
                                right: 4,
                                child: InkWell(
                                  onTap: _isUploading ? null : _pickImage,
                                  child: Container(
                                    height: 40,
                                    width: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2B8CEE),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 3),
                                    ),
                                    child: const Icon(Icons.edit,
                                        size: 18, color: Colors.white),
                                  ),
                                ),
                              ),
                              if (_isUploading)
                                const Positioned.fill(
                                  child: Center(
                                      child: CircularProgressIndicator()),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Upload Profile Picture',
                            style: GoogleFonts.lexend(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF111418),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Must be a clear headshot.',
                            style: GoogleFonts.lexend(
                              color: const Color(0xFF617589),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(height: 12, color: Color(0xFFF6F7F8)),
                const SizedBox(height: 12),
                _section(
                  title: 'Personal Information',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Full Name',
                        style: GoogleFonts.lexend(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111418),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameController,
                        style: GoogleFonts.lexend(
                          color: const Color(0xFF111418),
                          fontSize: 14,
                        ),
                        decoration: _input(hint: 'Enter your full name'),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Please enter name' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Age',
                                  style: GoogleFonts.lexend(
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF111418),
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _ageController,
                                  style: GoogleFonts.lexend(
                                    color: const Color(0xFF111418),
                                    fontSize: 14,
                                  ),
                                  keyboardType: TextInputType.number,
                                  decoration: _input(hint: 'e.g., 16'),
                                  validator: (v) =>
                                      _positiveIntValidator(v, 'age'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'City',
                                  style: GoogleFonts.lexend(
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF111418),
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _cityAutocomplete(),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Sex',
                        style: GoogleFonts.lexend(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111418),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: sexOptions.map((opt) {
                          final selected = _selectedSex == opt;
                          return ChoiceChip(
                            showCheckmark: false,
                            label: Text(
                              opt,
                              style: GoogleFonts.lexend(
                                color: selected
                                    ? const Color(0xFF2B8CEE)
                                    : const Color(0xFF617589),
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            selected: selected,
                            onSelected: (_) => setState(() {
                              _selectedSex = opt;
                              _sexError = false;
                            }),
                            selectedColor:
                                const Color(0xFF2B8CEE).withOpacity(0.2),
                            backgroundColor: Colors.grey.shade100,
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          );
                        }).toList(),
                      ),
                      if (_sexError)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            'Select your sex',
                            style: GoogleFonts.lexend(
                              fontSize: 12,
                              color: Colors.red.shade600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(height: 12, color: Color(0xFFF6F7F8)),
                const SizedBox(height: 12),
                _section(
                  title: 'Academic Needs',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Grade Level',
                        style: GoogleFonts.lexend(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111418),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // CHANGED: Added border around grade level dropdown
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFD1D1D1)),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _selectedGradeGroup,
                          style: GoogleFonts.lexend(
                            color: const Color(0xFF111418),
                            fontSize: 14,
                          ),
                          decoration:
                              _input(hint: 'Select grade level').copyWith(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                          items: gradeGroups
                              .map((g) => DropdownMenuItem<String>(
                                    value: g,
                                    child: Text(
                                      g,
                                      style: GoogleFonts.lexend(
                                        fontSize: 14,
                                      ),
                                    ),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() {
                            _selectedGradeGroup = v;
                            _studentGradeError = false;
                          }),
                          validator: (v) =>
                              v == null ? 'Please select grade level' : null,
                        ),
                      ),
                      if (_studentGradeError)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            'Select a grade level',
                            style: GoogleFonts.lexend(
                              fontSize: 12,
                              color: Colors.red.shade600,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        'Subjects you need help with',
                        style: GoogleFonts.lexend(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111418),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // CHANGED: Added border around subjects field
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFD1D1D1)),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: _buildSubjectChips(),
                      ),
                      if (_studentSubjectsError)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            'Select at least one subject',
                            style: GoogleFonts.lexend(
                              fontSize: 12,
                              color: Colors.red.shade600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(height: 12, color: Color(0xFFF6F7F8)),
                const SizedBox(height: 12),
                _section(
                  title: 'Tutoring Preferences',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Preferred Tutor Gender',
                        style: GoogleFonts.lexend(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111418),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: tutorGenderOptions.map((opt) {
                          final selected = _preferredTutorGender == opt;
                          return ChoiceChip(
                            showCheckmark: false,
                            label: Text(
                              opt,
                              style: GoogleFonts.lexend(
                                color: selected
                                    ? const Color(0xFF2B8CEE)
                                    : const Color(0xFF617589),
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            selected: selected,
                            onSelected: (_) =>
                                setState(() => _preferredTutorGender = opt),
                            selectedColor:
                                const Color(0xFF2B8CEE).withOpacity(0.2),
                            backgroundColor: Colors.grey.shade100,
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      // CHANGED: Added border around hours per day
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFD1D1D1)),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: _labeledSlider(
                          label: 'Hours per Day',
                          value: hoursVal,
                          min: 1,
                          max: 4,
                          display: '${hoursVal.round()} Hours',
                          onChanged: (v) => setState(
                              () => _selectedHours = v.round().toString()),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // CHANGED: Added border around days per week
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFD1D1D1)),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: _labeledSlider(
                          label: 'Days per Week',
                          value: daysVal,
                          min: 1,
                          max: 7,
                          display: '${daysVal.round()} Days',
                          onChanged: (v) => setState(
                              () => _selectedDays = v.round().toString()),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Max Price Per Hour',
                        style: GoogleFonts.lexend(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111418),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _maxPriceController,
                        style: GoogleFonts.lexend(
                          color: const Color(0xFF111418),
                          fontSize: 14,
                        ),
                        keyboardType: TextInputType.number,
                        decoration: _input(
                          hint: 'Enter amount',
                          prefix: Padding(
                            padding: const EdgeInsets.only(left: 12, right: 6),
                            child: Text(
                              'Birr',
                              style: GoogleFonts.lexend(
                                color: const Color(0xFF617589),
                                fontSize: 14,
                              ),
                            ),
                          ),
                          suffix: Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Text(
                              '/hr',
                              style: GoogleFonts.lexend(
                                color: const Color(0xFF617589),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        validator: _positiveDoubleValidator,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2B8CEE),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isUploading ? null : _saveProfile,
                    child: Text(
                      'Save and Continue',
                      style: GoogleFonts.lexend(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'By continuing, you agree to our Terms of Service and Privacy Policy.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lexend(
                    color: const Color(0xFF617589),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _section({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.lexend(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111418),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildSubjectChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...selectedSubjects.map(
          (s) => Container(
            // CHANGED: Removed black borders from subjects
            decoration: BoxDecoration(
              color: const Color(0x332B8CEE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    s,
                    style: GoogleFonts.lexend(
                      color: const Color(0xFF2B8CEE),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () {
                      setState(() => selectedSubjects.remove(s));
                    },
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Color(0xFF2B8CEE),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: _showSubjectPicker,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              '+ Add subject',
              style: GoogleFonts.lexend(
                color: const Color(0xFF617589),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showSubjectPicker() {
    final remaining =
        subjects.where((s) => !selectedSubjects.contains(s)).toList();
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: ListView.separated(
            itemCount: remaining.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final subj = remaining[i];
              return ListTile(
                title: Text(
                  subj,
                  style: GoogleFonts.lexend(
                    fontSize: 16,
                  ),
                ),
                onTap: () {
                  setState(() => selectedSubjects.add(subj));
                  Navigator.pop(ctx);
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _labeledSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required String display,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.lexend(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF111418),
                fontSize: 14,
              ),
            ),
            Text(
              display,
              style: GoogleFonts.lexend(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2B8CEE),
                fontSize: 14,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max - min).round(),
          activeColor: const Color(0xFF2B8CEE),
          inactiveColor: const Color(0xFFD1D1D1),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _cityAutocomplete() {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: _cityController.text),
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text.isEmpty)
          return const Iterable<String>.empty();
        final query = textEditingValue.text.toLowerCase();
        return _allCities.where((c) => c.toLowerCase().contains(query));
      },
      displayStringForOption: (option) => option,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          style: GoogleFonts.lexend(
            color: const Color(0xFF111418),
            fontSize: 14,
          ),
          decoration: _input(hint: 'Enter your city'),
          validator: (v) => v == null || v.isEmpty ? 'Please enter city' : null,
        );
      },
      onSelected: (selection) {
        _cityController.text = selection;
      },
    );
  }
}
