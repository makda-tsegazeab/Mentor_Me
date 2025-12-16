import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';

class ParentInfoScreen extends StatefulWidget {
  const ParentInfoScreen({super.key});

  @override
  State<ParentInfoScreen> createState() => _ParentInfoScreenState();
}

class _ParentInfoScreenState extends State<ParentInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _ageController = TextEditingController();
  final _maxPriceController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _hoursController = TextEditingController();
  final _daysController = TextEditingController();

  String? _selectedSex;
  String? _selectedHours;
  String? _selectedDays;
  String? _selectedIdType;
  DateTime? _idExpiryDate;
  bool _isUploading = false;
  bool _verified = false;

  File? _profileImage;
  File? _idFront;
  File? _idBack;

  final List<String> sexOptions = ['Male', 'Female'];
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

  final List<String> _allCities = [
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

  List<String> selectedSubjects = [];
  List<String> selectedGrades = [];

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
    _ageController.dispose();
    _maxPriceController.dispose();
    _idNumberController.dispose();
    _hoursController.dispose();
    _daysController.dispose();
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
      _nameController.text = data['name'] ?? '';
      _ageController.text = (data['age'] ?? '').toString();
      _cityController.text = data['city'] ?? '';
      _selectedSex = data['sex'];
      selectedSubjects = List<String>.from(data['subjects'] ?? []);
      selectedGrades = List<String>.from(data['gradeLevels'] ?? []);
      _selectedHours = (data['hoursPerDay'] ?? '2').toString();
      _selectedDays = (data['daysPerWeek'] ?? '3').toString();
      _hoursController.text = _selectedHours ?? '';
      _daysController.text = _selectedDays ?? '';
      _maxPriceController.text = (data['maxPricePerHour'] ?? '').toString();
      _selectedIdType = data['idType'];
      _idNumberController.text = data['idNumber'] ?? '';
      if (data['idExpiryDate'] != null) {
        _idExpiryDate = DateTime.tryParse(data['idExpiryDate']);
      }
      _verified = data['verified'] == true;
    });
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
        final payload = json.decode(await response.stream.bytesToString());
        return payload['secure_url'];
      }
    } catch (e) {
      debugPrint('Upload error: $e');
    } finally {
      setState(() => _isUploading = false);
    }
    return null;
  }

  Future<void> _saveParentProfile() async {
    if (!_formKey.currentState!.validate()) return;
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
        'role': 'parent',
        'name': _nameController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()),
        'sex': _selectedSex,
        'city': _cityController.text.trim(),
        'subjects': selectedSubjects,
        'gradeLevels': selectedGrades,
        'hoursPerDay': int.tryParse(hoursText),
        'daysPerWeek': int.tryParse(daysText),
        'maxPricePerHour': double.tryParse(
                _maxPriceController.text.trim().replaceAll(',', '')) ??
            0,
        'idType': _selectedIdType,
        'idNumber': _idNumberController.text.trim(),
        'idExpiryDate': _idExpiryDate?.toIso8601String(),
        'profileImage': profileUrl,
        'idFront': idFrontUrl,
        'idBack': idBackUrl,
        'verified': _verified,
        'completedProfile': true,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      final notif = Provider.of<NotificationProvider>(context, listen: false);
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
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error saving profile: $e')));
      }
    }
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
                      : () =>
                          _pickImage((f) => setState(() => _profileImage = f)),
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
            'This helps tutors find the right fit.',
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
            style: const TextStyle(
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
                'Create Learner Profile',
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
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
                            _cityAutocomplete(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _sectionCard(
                        'Academic Needs',
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                                // border: Border.all(color: Color(0xFFD1D1D1)),
                              ),
                              child: _chipGroup(
                                options: gradeLevels,
                                selected: selectedGrades,
                                onChanged: (v) =>
                                    setState(() => selectedGrades = v),
                                onAdd: _showGradePicker,
                                actionLabel: '+ Add grade level',
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Subjects you need help with*',
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
                                // border: Border.all(color: Color(0xFFD1D1D1)),
                              ),
                              child: _chipGroup(
                                options: subjects,
                                selected: selectedSubjects,
                                onChanged: (v) =>
                                    setState(() => selectedSubjects = v),
                                onAdd: _showParentSubjectPicker,
                                actionLabel: '+ Add subject',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _sectionCard(
                        'Tutoring Preferences',
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Hours per Day',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF111418)),
                                      ),
                                      const SizedBox(height: 8),
                                      TextFormField(
                                        controller: _hoursController,
                                        keyboardType: TextInputType.number,
                                        decoration: _fieldDecoration(
                                            hint: 'e.g. 3 hours'),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Days per Week',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF111418)),
                                      ),
                                      const SizedBox(height: 8),
                                      TextFormField(
                                        controller: _daysController,
                                        keyboardType: TextInputType.number,
                                        decoration: _fieldDecoration(
                                            hint: 'e.g. 5 days'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _maxPriceController,
                              keyboardType: TextInputType.number,
                              decoration: _fieldDecoration(
                                hint: 'Max Price per Hour (Birr)',
                                prefix: const Padding(
                                  padding: EdgeInsets.only(left: 12, right: 6),
                                  child: Text('Birr',
                                      style:
                                          TextStyle(color: Color(0xFF617589))),
                                ),
                                suffix: const Padding(
                                  padding: EdgeInsets.only(right: 12),
                                  child: Text('/hr',
                                      style:
                                          TextStyle(color: Color(0xFF617589))),
                                ),
                              ),
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
                                    color: _verified
                                        ? const Color(0x332B8CEE)
                                        : const Color(0x33F5A623),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                          _verified
                                              ? Icons.verified
                                              : Icons.hourglass_top,
                                          color: _verified
                                              ? const Color(0xFF2B8CEE)
                                              : const Color(0xFFF5A623),
                                          size: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        _verified ? 'Verified' : 'Pending',
                                        style: TextStyle(
                                            color: _verified
                                                ? const Color(0xFF2B8CEE)
                                                : const Color(0xFFF5A623),
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
                              items: [
                                'National ID',
                                'Passport',
                                'Driver\'s License'
                              ]
                                  .map((t) => DropdownMenuItem(
                                        value: t,
                                        child: Text(t),
                                      ))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedIdType = v),
                              validator: (_) => null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _idNumberController,
                              decoration: _fieldDecoration(hint: 'ID Number'),
                              validator: (_) => null,
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
                                      ? 'Select date'
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
                                (f) => setState(() => _idFront = f)),
                            const SizedBox(height: 10),
                            _uploadButton('Upload ID Back', _idBack,
                                (f) => setState(() => _idBack = f)),
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
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
                onPressed: _isUploading ? null : _saveParentProfile,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: const Color(0xFF2B8CEE),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Save and Continue',
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

  void _showParentSubjectPicker() {
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
}
