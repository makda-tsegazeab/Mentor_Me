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
  final bool isEdit;

  const ParentInfoScreen({super.key, this.isEdit = false});

  @override
  State<ParentInfoScreen> createState() => _ParentInfoScreenState();
}

class _ParentInfoScreenState extends State<ParentInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _ageController = TextEditingController();
  final _maxPriceController = TextEditingController();
  final _hoursController = TextEditingController();
  final _daysController = TextEditingController();

  String? _selectedSex;
  String? _selectedHours;
  String? _selectedDays;
  String _preferredTutorGender = 'No preference';
  bool _isUploading = false;

  File? _profileImage;

  final List<String> sexOptions = ['Male', 'Female'];
  final List<String> tutorGenderOptions = ['Male', 'Female', 'No preference'];
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
      final prefGender = data['preferredTutorGender'];
      if (prefGender is String && prefGender.isNotEmpty) {
        _preferredTutorGender = prefGender;
      }
      _maxPriceController.text = (data['maxPricePerHour'] ?? '').toString();
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
      if (_profileImage != null) {
        profileUrl =
            await _uploadToCloudinary(_profileImage!, 'mentorme_profiles');
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
        'preferredTutorGender': _preferredTutorGender,
        'maxPricePerHour': double.tryParse(
                _maxPriceController.text.trim().replaceAll(',', '')) ??
            0,
        'profileImage': profileUrl,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fillColor =
        isDark ? theme.colorScheme.surfaceVariant : Colors.white;
    final borderColor =
        isDark ? theme.colorScheme.outline : const Color(0xFFD1D1D1);
    final hintColor = isDark
        ? theme.colorScheme.onSurfaceVariant
        : const Color(0xFF617589);

    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.lexend(color: hintColor),
      prefixIcon: prefix,
      suffixIcon: suffix,
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2B8CEE), width: 1.2),
      ),
    );
  }

  Widget _profileHeader() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor =
        isDark ? theme.colorScheme.surface : Colors.white;
    final textColor =
        isDark ? theme.colorScheme.onSurface : const Color(0xFF111418);
    final subtitleColor = isDark
        ? theme.colorScheme.onSurfaceVariant
        : const Color(0xFF617589);
    final imageBg =
        isDark ? theme.colorScheme.surfaceVariant : Colors.grey.shade200;
    final shadowColor =
        isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.06);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
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
                  color: imageBg,
                  image: _profileImage != null
                      ? DecorationImage(
                          image: FileImage(_profileImage!), fit: BoxFit.cover)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor,
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
          Text(
            'Upload Profile Picture',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'This helps tutors find the right fit.',
            style: TextStyle(color: subtitleColor),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(String title, Widget child, {Widget? badge}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor =
        isDark ? theme.colorScheme.surface : Colors.white;
    final textColor =
        isDark ? theme.colorScheme.onSurface : const Color(0xFF111418);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
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
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textColor),
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
              color: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).colorScheme.onSurfaceVariant
                  : const Color(0xFF617589),
              fontWeight: FontWeight.w600,
            ),
          ),
          onPressed: onAdd,
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).colorScheme.surfaceVariant
              : Colors.grey.shade100,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide.none,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);
    final isDark = baseTheme.brightness == Brightness.dark;
    final scaffoldBg = isDark
        ? baseTheme.scaffoldBackgroundColor
        : const Color(0xFFF6F7F8);
    final appBarBg =
        isDark ? baseTheme.colorScheme.surface : Colors.white;
    final appBarFg = baseTheme.colorScheme.onSurface;
    final hintColor = isDark
        ? baseTheme.colorScheme.onSurfaceVariant
        : const Color(0xFF617589);
    final titleColor =
        isDark ? baseTheme.colorScheme.onSurface : const Color(0xFF111418);
    final contentText =
        isDark ? baseTheme.colorScheme.onSurface : const Color(0xFF111418);
    final mutedText = isDark
        ? baseTheme.colorScheme.onSurfaceVariant
        : const Color(0xFF617589);
    final mutedSurface =
        isDark ? baseTheme.colorScheme.surfaceVariant : Colors.grey.shade100;
    final contentSurface =
        isDark ? baseTheme.colorScheme.surfaceVariant : Colors.white;
    final footerBg =
        isDark ? baseTheme.colorScheme.surface : Colors.white;

    final lexendText = GoogleFonts.lexendTextTheme(baseTheme.textTheme);
    final double hoursVal =
        ((double.tryParse(_selectedHours ?? '2') ?? 2).clamp(1, 4)).toDouble();
    final double daysVal =
        ((double.tryParse(_selectedDays ?? '3') ?? 3).clamp(1, 7)).toDouble();

    return Theme(
      data: baseTheme.copyWith(
        scaffoldBackgroundColor: scaffoldBg,
        textTheme: lexendText,
        primaryTextTheme: GoogleFonts.lexendTextTheme(
          baseTheme.primaryTextTheme,
        ),
        appBarTheme: baseTheme.appBarTheme.copyWith(
          titleTextStyle: GoogleFonts.lexend(
            fontWeight: FontWeight.w700,
            color: titleColor,
            fontSize: 20,
          ),
          toolbarTextStyle: GoogleFonts.lexend(
              textStyle: baseTheme.appBarTheme.toolbarTextStyle),
        ),
        inputDecorationTheme: baseTheme.inputDecorationTheme.copyWith(
          hintStyle: GoogleFonts.lexend(color: hintColor),
        ),
      ),
      child: DefaultTextStyle.merge(
          style: GoogleFonts.lexend(),
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: appBarBg,
              foregroundColor: appBarFg,
              elevation: 0.5,
              title: Text(
                widget.isEdit ? 'Edit Profile' : 'Create Your Profile',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: titleColor,
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
                                      color: contentText,
                                      fontSize: 14,
                                    ),
                                    decoration: _fieldDecoration(hint: 'Sex *'),
                                    items: sexOptions
                                        .map((s) => DropdownMenuItem(
                                              value: s,
                                              child: Text(
                                                s,
                                                style: GoogleFonts.lexend(
                                                  color: contentText,
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
                            Text(
                              'Grade Levels*',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: contentText),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: contentSurface,
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
                            Text(
                              'Subjects you need help with*',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: contentText),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: contentSurface,
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
                            Text(
                              'Preferred Tutor Gender',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: contentText),
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
                                          : mutedText,
                                      fontWeight: selected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                  selected: selected,
                                  onSelected: (_) => setState(
                                      () => _preferredTutorGender = opt),
                                  selectedColor:
                                      const Color(0xFF2B8CEE).withOpacity(0.2),
                                  backgroundColor: mutedSurface,
                                  side: BorderSide.none,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: const Color(0xFFD1D1D1)),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: _labeledSlider(
                                label: 'Hours per Day',
                                value: hoursVal,
                                min: 1,
                                max: 4,
                                display: '${hoursVal.round()} Hours',
                                onChanged: (v) => setState(() {
                                  final val = v.round().toString();
                                  _selectedHours = val;
                                  _hoursController.text = val;
                                }),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: const Color(0xFFD1D1D1)),
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
                    ],
                  ),
                ),
              ),
            ),
            bottomNavigationBar: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                decoration: BoxDecoration(
                  color: footerBg,
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
            ),
          )),
    );
  }

  Widget _cityAutocomplete() {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: _cityController.text),
      optionsBuilder: (text) {
        final query = text.text.toLowerCase();
        if (query.isEmpty) return const Iterable<String>.empty();
        return _allCities.where(
          (c) => c.toLowerCase().contains(query),
        );
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: _fieldDecoration(hint: 'City *'),
          onChanged: (value) => _cityController.text = value,
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

  Widget _labeledSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required String display,
    required ValueChanged<double> onChanged,
  }) {
    final theme = Theme.of(context);
    final textColor = theme.brightness == Brightness.dark
        ? theme.colorScheme.onSurface
        : const Color(0xFF111418);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: textColor)),
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
