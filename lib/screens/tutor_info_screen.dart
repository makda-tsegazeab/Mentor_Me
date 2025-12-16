import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';

class TutorInfoScreen extends StatefulWidget {
  const TutorInfoScreen({super.key});

  @override
  State<TutorInfoScreen> createState() => _TutorInfoScreenState();
}

class _TutorInfoScreenState extends State<TutorInfoScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _minPriceController = TextEditingController();
  final _ageController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _hoursController = TextEditingController();
  final _daysController = TextEditingController();

  String? _selectedSex;
  String? _selectedQualification;
  bool _available = true;
  bool _verified = false;
  File? _profileImage;
  File? _idFront;
  File? _idBack;

  String? _selectedIdType;
  DateTime? _idExpiryDate;

  List<String> selectedSubjects = [];
  List<String> selectedGrades = [];
  bool _subjectsError = false;
  bool _gradesError = false;

  String? _selectedHours;
  String? _selectedDays;

  bool _isUploading = false;

  final List<String> sexOptions = ['Male', 'Female', 'Other'];
  final List<String> qualificationOptions = [
    'High School',
    'Diploma',
    'Bachelor Degree',
    'Masters',
    'PhD'
  ];
  final List<String> idTypes = ['National ID', 'Passport', 'Kebele ID'];
  final List<String> gradeLevels = ['KG', '1-4', '5-6', '7-8', '9-10', '11-12'];
  final List<String> subjects = [
    'Mathematics',
    'English',
    'Amharic',
    'Tigrigna',
    'Physics',
    'Chemistry',
    'Biology',
    'Civics',
    'History',
    'Geography',
    'ICT',
    'Physical Education',
    'Art',
    'Ethics',
    'Social Studies',
    'Economics',
  ];
  final List<String> hourOptions = ['1', '2', '3', '4', '5', '6', '7', '8'];
  final List<String> daysOptions = ['1', '2', '3', '4', '5', '6', '7'];

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

  final String _cloudName = 'db4edv0oh';
  final String _uploadPreset = 'mentorme_uploads';

  @override
  void initState() {
    super.initState();
    _hoursController.text = '2';
    _daysController.text = '3';
    _selectedHours = '2';
    _selectedDays = '3';
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _minPriceController.dispose();
    _ageController.dispose();
    _idNumberController.dispose();
    _hoursController.dispose();
    _daysController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
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
          final qual = data['qualification'];
          if (qual is String) _selectedQualification = qual;
          final subs = data['subjects'];
          if (subs is List)
            selectedSubjects = subs.whereType<String>().toList();
          final grades = data['gradeLevels'];
          if (grades is List)
            selectedGrades = grades.whereType<String>().toList();
          final hours = data['hoursPerDay'];
          if (hours != null) {
            _selectedHours = hours.toString();
            _hoursController.text = _selectedHours ?? '';
          }
          final days = data['daysPerWeek'];
          if (days != null) {
            _selectedDays = days.toString();
            _daysController.text = _selectedDays ?? '';
          }
          final minPrice = data['minPricePerHour'];
          if (minPrice != null) _minPriceController.text = minPrice.toString();
          final available = data['available'];
          if (available is bool) _available = available;
          final verified = data['verified'];
          if (verified is bool) _verified = verified;
          final idType = data['idType'];
          if (idType is String) _selectedIdType = idType;
          final idNum = data['idNumber'];
          if (idNum is String) _idNumberController.text = idNum;
          final idExp = data['idExpiryDate'];
          if (idExp is String) {
            try {
              _idExpiryDate = DateTime.parse(idExp);
            } catch (_) {}
          }
        });
      }
    }
  }

  Future<void> _pickImage(Function(File) onSelected) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => onSelected(File(picked.path)));
  }

  Future<String?> _uploadToCloudinary(File image, String folder) async {
    try {
      setState(() => _isUploading = true);
      final url =
          Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = _uploadPreset
        ..fields['folder'] = folder
        ..files.add(await http.MultipartFile.fromPath('file', image.path));

      final response = await request.send();
      if (response.statusCode == 200) {
        final jsonData = json.decode(await response.stream.bytesToString());
        return jsonData['secure_url'];
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
    return null;
  }

  Future<void> _saveTutorProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final hasRequired = _hasRequiredTutorFields(markErrors: true);
    if (!hasRequired) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fill every required tutor field before continuing.',
            style: GoogleFonts.lexend(),
          ),
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      String? profileUrl;
      String? idFrontUrl;
      String? idBackUrl;

      if (_profileImage != null) {
        profileUrl =
            await _uploadToCloudinary(_profileImage!, 'mentorme_profiles');
      }
      if (_idFront != null) {
        idFrontUrl = await _uploadToCloudinary(_idFront!, 'mentorme_ids');
      }
      if (_idBack != null) {
        idBackUrl = await _uploadToCloudinary(_idBack!, 'mentorme_ids');
      }

      final hoursText = _hoursController.text.trim().isNotEmpty
          ? _hoursController.text.trim()
          : _selectedHours ?? '0';
      final daysText = _daysController.text.trim().isNotEmpty
          ? _daysController.text.trim()
          : _selectedDays ?? '0';

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'role': 'tutor',
        'name': _nameController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()),
        'sex': _selectedSex,
        'qualification': _selectedQualification,
        'city': _cityController.text.trim(),
        'subjects': selectedSubjects,
        'gradeLevels': selectedGrades,
        'hoursPerDay': int.tryParse(hoursText),
        'daysPerWeek': int.tryParse(daysText),
        'minPricePerHour':
            double.tryParse(_minPriceController.text.trim()) ?? 0.0,
        'available': _available,
        'verified': _verified,
        'idType': _selectedIdType,
        'idNumber': _idNumberController.text.trim(),
        'idExpiryDate': _idExpiryDate?.toIso8601String(),
        'profileImage': profileUrl,
        'idFront': idFrontUrl,
        'idBack': idBackUrl,
        'completedProfile': hasRequired,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (hasRequired) {
        final notif =
            Provider.of<NotificationProvider>(context, listen: false);
        final docRef =
            FirebaseFirestore.instance.collection('users').doc(user.uid);
        final existing = await docRef.get();
        final welcomeSent = existing.data()?['welcomeSent'] == true;
        if (!welcomeSent) {
          await notif.createNotification(
            userId: user.uid,
            title: 'Welcome!',
            body:
                'Thanks for completing your profile. Start exploring tutors and learners.',
            type: 'welcome',
            data: {},
          );
          await docRef.update({'welcomeSent': true});
        }
      }

      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error saving profile: $e')));
    }
  }

  bool _hasRequiredTutorFields({bool markErrors = false}) {
    final name = _nameController.text.trim();
    final city = _cityController.text.trim();
    final age = int.tryParse(_ageController.text.trim());
    final qualification = _selectedQualification;
    final sex = _selectedSex;
    final minPrice = _parseDouble(_minPriceController.text.trim());

    final hoursText = _hoursController.text.trim().isNotEmpty
        ? _hoursController.text.trim()
        : _selectedHours ?? '';
    final daysText = _daysController.text.trim().isNotEmpty
        ? _daysController.text.trim()
        : _selectedDays ?? '';

    final hours = int.tryParse(hoursText);
    final days = int.tryParse(daysText);
    final subjectsValid = selectedSubjects.isNotEmpty;
    final gradesValid = selectedGrades.isNotEmpty;

    final valid = name.isNotEmpty &&
        city.isNotEmpty &&
        age != null &&
        sex != null &&
        sex.isNotEmpty &&
        qualification != null &&
        qualification.isNotEmpty &&
        minPrice != null &&
        minPrice > 0 &&
        hours != null &&
        hours > 0 &&
        days != null &&
        days > 0 &&
        subjectsValid &&
        gradesValid;

    if (markErrors) {
      setState(() {
        _subjectsError = !subjectsValid;
        _gradesError = !gradesValid;
      });
    }

    return valid;
  }

  InputDecoration _fieldDecoration({
    String? hint,
    Widget? prefix,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.lexend(
        color: const Color(0xFF617589),
      ),
      prefixIcon: prefix,
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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

  double? _parseDouble(String value) {
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
    final parsed = _parseDouble(value.trim());
    if (parsed == null || parsed <= 0) return 'Enter valid price';
    return null;
  }

  Widget _profileHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
                  color: Colors.grey.shade200,
                  image: _profileImage != null
                      ? DecorationImage(
                          image: FileImage(_profileImage!), fit: BoxFit.cover)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: _profileImage == null
                    ? const Icon(Icons.person,
                        size: 52, color: Color(0xFF9BA5B0))
                    : null,
              ),
              Positioned(
                right: 4,
                bottom: 4,
                child: InkWell(
                  onTap: _isUploading
                      ? null
                      : () => _pickImage((f) => _profileImage = f),
                  child: Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2B8CEE),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child:
                        const Icon(Icons.edit, color: Colors.white, size: 18),
                  ),
                ),
              ),
              if (_isUploading)
                const Positioned.fill(
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Upload Profile Picture',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111418),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Must be a clear headshot.',
            style: TextStyle(color: Color(0xFF617589)),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(String title, Widget child, {Widget? badge}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111418)),
                ),
              ),
              if (badge != null) badge,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _chipGroup({
    required List<String> options,
    required List<String> selected,
    required void Function(List<String>) onChanged,
    required VoidCallback onAdd,
    String actionLabel = '+ Add subject',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: selected
              .map(
                (s) => Chip(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide.none,
                  ),
                  label: Text(
                    s,
                    style: const TextStyle(
                        color: Color(0xFF2B8CEE), fontWeight: FontWeight.w600),
                  ),
                  backgroundColor: const Color(0x332B8CEE),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  deleteIconColor: const Color(0xFF2B8CEE),
                  onDeleted: () {
                    final next = List<String>.from(selected)..remove(s);
                    onChanged(next);
                  },
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        ActionChip(
          label: Text(
            actionLabel,
            style: TextStyle(
                color: Color(0xFF617589), fontWeight: FontWeight.w600),
          ),
          onPressed: onAdd,
          backgroundColor: Colors.grey.shade100,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide.none,
          ),
        ),
      ],
    );
  }

  Widget _uploadButton(String label, File? file, Function(File) onPick) {
    return OutlinedButton.icon(
      onPressed: () => _pickImage(onPick),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        side: const BorderSide(color: Color(0xFF2B8CEE)),
        foregroundColor: const Color(0xFF2B8CEE),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: const Icon(Icons.upload_file),
      label: Text(file == null ? label : 'Replace $label'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);

    final lexendText = GoogleFonts.lexendTextTheme(baseTheme.textTheme);
    final hoursVal =
        double.tryParse(_selectedHours ?? _hoursController.text.trim()) ?? 2;
    final daysVal =
        double.tryParse(_selectedDays ?? _daysController.text.trim()) ?? 3;

    return Theme(
      data: baseTheme.copyWith(
        scaffoldBackgroundColor: const Color(0xFFF6F7F8),
        textTheme: lexendText,
        primaryTextTheme: GoogleFonts.lexendTextTheme(
          baseTheme.primaryTextTheme,
        ),
        appBarTheme: baseTheme.appBarTheme.copyWith(
          titleTextStyle: GoogleFonts.lexend(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF111418),
            fontSize: 20,
          ),
          toolbarTextStyle: GoogleFonts.lexend(
              textStyle: baseTheme.appBarTheme.toolbarTextStyle),
        ),
        inputDecorationTheme: baseTheme.inputDecorationTheme.copyWith(
          hintStyle: GoogleFonts.lexend(color: const Color(0xFF617589)),
        ),
      ),
      child: DefaultTextStyle.merge(
          style: GoogleFonts.lexend(),
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF111418),
              elevation: 0.5,
              title: const Text(
                'Edit Your Details',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111418),
                ),
              ),
              centerTitle: false,
            ),
            body: SafeArea(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _profileHeader(),
                      const SizedBox(height: 12),
                      _sectionCard(
                        'Personal Information',
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _nameController,
                              decoration: _fieldDecoration(hint: 'Full Name *'),
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Please enter name'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _ageController,
                                    keyboardType: TextInputType.number,
                                    decoration: _fieldDecoration(hint: 'Age *'),
                                    validator: (v) => v == null || v.isEmpty
                                        ? 'Enter age'
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedSex,
                                    style: GoogleFonts.lexend(
                                      color: const Color(0xFF111418),
                                      fontSize: 14,
                                    ),
                                    decoration: _fieldDecoration(hint: 'Sex *'),
                                    items: sexOptions
                                        .map((s) => DropdownMenuItem(
                                              value: s,
                                              child: Text(
                                                s,
                                                style: GoogleFonts.lexend(
                                                  color:
                                                      const Color(0xFF111418),
                                                ),
                                              ),
                                            ))
                                        .toList(),
                                    onChanged: (v) =>
                                        setState(() => _selectedSex = v),
                                    validator: (v) =>
                                        v == null ? 'Please select' : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: _selectedQualification,
                              decoration: _fieldDecoration(
                                  hint: 'Highest Qualification *'),
                              items: qualificationOptions
                                  .map((q) => DropdownMenuItem(
                                        value: q,
                                        child: Text(q),
                                      ))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedQualification = v),
                              validator: (v) => v == null
                                  ? 'Please select qualification'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            _cityAutocomplete(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _sectionCard(
                        'Tutoring Details',
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Subjects Taught*',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF111418)),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: const Color(0xFFD1D1D1)),
                              ),
                              child: _chipGroup(
                                options: subjects,
                                selected: selectedSubjects,
                                onChanged: (v) => setState(() {
                                  selectedSubjects = v;
                                  _subjectsError = v.isEmpty;
                                }),
                                onAdd: _showSubjectPicker,
                                actionLabel: '+ Add subject',
                              ),
                            ),
                            if (_subjectsError)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Add at least one subject',
                                  style: GoogleFonts.lexend(
                                    fontSize: 12,
                                    color: Colors.red.shade600,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 16),
                            const Text(
                              'Grade Levels*',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF111418)),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: const Color(0xFFD1D1D1)),
                              ),
                              child: _chipGroup(
                                options: gradeLevels,
                                selected: selectedGrades,
                                onChanged: (v) => setState(() {
                                  selectedGrades = v;
                                  _gradesError = v.isEmpty;
                                }),
                                onAdd: _showGradePicker,
                                actionLabel: '+ Add grade level',
                              ),
                            ),
                            if (_gradesError)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Add at least one grade level',
                                  style: GoogleFonts.lexend(
                                    fontSize: 12,
                                    color: Colors.red.shade600,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: const Color(0xFFD1D1D1)),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    child: _labeledSlider(
                                      label: 'Hours per Day',
                                      value: hoursVal,
                                      min: 1,
                                      max: 8,
                                      display: '${hoursVal.round()} Hours',
                                      onChanged: (v) => setState(() {
                                        final val = v.round().toString();
                                        _selectedHours = val;
                                        _hoursController.text = val;
                                      }),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: const Color(0xFFD1D1D1)),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    child: _labeledSlider(
                                      label: 'Days per Week',
                                      value: daysVal,
                                      min: 1,
                                      max: 7,
                                      display: '${daysVal.round()} Days',
                                      onChanged: (v) => setState(() {
                                        final val = v.round().toString();
                                        _selectedDays = val;
                                        _daysController.text = val;
                                      }),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _minPriceController,
                              keyboardType: TextInputType.number,
                              decoration: _fieldDecoration(
                                hint: 'Min. Price per Hour (Birr)',
                                prefix: const Padding(
                                  padding: EdgeInsets.only(left: 12, right: 6),
                                  child: Text('Birr',
                                      style:
                                          TextStyle(color: Color(0xFF617589))),
                                ),
                              ),
                              validator: _positiveDoubleValidator,
                            ),
                            const SizedBox(height: 12),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text(
                                'Available for new students',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF111418)),
                              ),
                              value: _available,
                              activeColor: const Color(0xFF2B8CEE),
                              onChanged: (v) => setState(() => _available = v),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _sectionCard(
                        'Verification',
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0x33F5A623),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.hourglass_top,
                                          color: Color(0xFFF5A623), size: 16),
                                      SizedBox(width: 6),
                                      Text(
                                        'Pending',
                                        style: TextStyle(
                                            color: Color(0xFFF5A623),
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: _selectedIdType,
                              decoration: _fieldDecoration(hint: 'ID Type'),
                              items: idTypes
                                  .map((t) => DropdownMenuItem(
                                        value: t,
                                        child: Text(t),
                                      ))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedIdType = v),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _idNumberController,
                              decoration: _fieldDecoration(hint: 'ID Number'),
                            ),
                            const SizedBox(height: 12),
                            InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _idExpiryDate ?? DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  setState(() => _idExpiryDate = picked);
                                }
                              },
                              child: InputDecorator(
                                decoration:
                                    _fieldDecoration(hint: 'ID Expiry Date *'),
                                child: Text(
                                  _idExpiryDate == null
                                      ? 'Select Expiry date'
                                      : '${_idExpiryDate!.year}-${_idExpiryDate!.month.toString().padLeft(2, '0')}-${_idExpiryDate!.day.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    color: _idExpiryDate == null
                                        ? const Color(0xFF617589)
                                        : const Color(0xFF111418),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            _uploadButton('Upload ID Front', _idFront,
                                (f) => _idFront = f),
                            const SizedBox(height: 10),
                            _uploadButton(
                                'Upload ID Back', _idBack, (f) => _idBack = f),
                            const SizedBox(height: 8),
                            const Text(
                              'Your documents are safe with us. We use them for verification purposes only.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Color(0xFF617589), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            bottomNavigationBar: Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, -2),
                  )
                ],
              ),
              child: ElevatedButton(
                onPressed: _isUploading ? null : _saveTutorProfile,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: const Color(0xFF2B8CEE),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Save Changes',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16),
                ),
              ),
            ),
          )),
    );
  }

  Widget _cityAutocomplete() {
    return Autocomplete<String>(
      optionsBuilder: (text) {
        final query = text.text.toLowerCase();
        if (query.isEmpty) return const Iterable<String>.empty();
        return _allCities.where(
          (c) => c.toLowerCase().contains(query),
        );
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        controller.text = _cityController.text;
        controller.selection = TextSelection.fromPosition(
            TextPosition(offset: controller.text.length));
        controller.addListener(() {
          _cityController.text = controller.text;
        });
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: _fieldDecoration(hint: 'City *'),
          validator: (v) => v == null || v.isEmpty ? 'Please enter city' : null,
        );
      },
      onSelected: (sel) => _cityController.text = sel,
    );
  }

  void _showSubjectPicker() {
    final remaining =
        subjects.where((s) => !selectedSubjects.contains(s)).toList();
    if (remaining.isEmpty) return;
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
                title: Text(subj),
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

  void _showGradePicker() {
    final remaining =
        gradeLevels.where((g) => !selectedGrades.contains(g)).toList();
    if (remaining.isEmpty) return;
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: ListView.separated(
            itemCount: remaining.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final grade = remaining[i];
              return ListTile(
                title: Text(grade),
                onTap: () {
                  setState(() => selectedGrades.add(grade));
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
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: Color(0xFF111418))),
            Text(display,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: Color(0xFF2B8CEE))),
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
}
