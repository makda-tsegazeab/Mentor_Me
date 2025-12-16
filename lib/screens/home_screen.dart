import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message_model.dart';
import '../models/notification_model.dart';
import '../providers/auth_provider.dart';
import '../providers/message_provider.dart';
import '../providers/notification_provider.dart';
import '../screens/chat_screen.dart';
import '../screens/relationships_screen.dart';
import '../services/interaction_logger.dart';
import '../theme/app_theme.dart';
import '../widgets/ui/empty_state.dart' as ui;
import '../widgets/ui/rating_badge.dart';
import '../models/recommendations.dart' as rec;
import '../services/recommendation_service.dart';
import '../services/content_recommender.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String? _userName;
  String? _userRole;
  String? _profileImage;
  double? _userRating;
  bool _isDarkMode = false;
  int _relationshipsInitialTab = 0;
  // NEW: hybrid recommendation service
  late final RecommendationService _recService;

  // Search filters
  String _selectedSubject = 'All Subjects';
  String _selectedGrade = 'All Grades';
  double _priceRange = 500;
  bool _onlyVerified = true;
  String _searchQuery = '';
  // Messages search
  final TextEditingController _messageSearchController =
      TextEditingController();
  String _messageSearchQuery = '';

  bool _isLoadingRecommendations = false;
  String? _recommendationsError;
  List<Map<String, dynamic>> _recommendedTutors = [];

  final List<String> _subjects = [
    'All Subjects',
    'Mathematics',
    'English',
    'Amharic',
    'Tigrigna',
    'Physics',
    'Chemistry',
    'Biology',
    'ICT',
  ];

  final List<String> _grades = [
    'All Grades',
    'KG',
    '1–4',
    '5–6',
    '7–8',
    '9–10',
    '11–12',
  ];

  // Debounce timer for search
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _recService = RecommendationService();
    _loadThemePreference();
    _loadUserData();
    _loadRecommendations();
    _searchQuery = '';
  }

  void _showTutorProfileSheet({
    required String name,
    String? userId,
    required Map<String, dynamic> userData,
    bool isStudentProfile = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final rating = (userData['rating'] as num?)?.toDouble() ?? 0.0;
    final profileImage = userData['profileImage']?.toString();
    final sex = (userData['sex'] ?? 'Not set').toString();
    final hours = userData['hoursPerDay']?.toString() ?? '-';
    final days = userData['daysPerWeek']?.toString() ?? '-';
    final price = userData['minPricePerHour'];
    final qualification =
        (userData['qualification'] ?? 'Not provided').toString();
    final preferredGender = (userData['preferredTutorSex'] ??
            userData['preferredTutorGender'] ??
            'Not set')
        .toString();
    final roleLabel = (() {
      final r = (userData['role'] ?? '').toString().toLowerCase();
      if (r == 'parent') return 'Parent';
      if (r == 'student') return 'Student';
      return 'Learner';
    })();
    final subjects =
        (userData['subjects'] as List<dynamic>? ?? []).cast<String>();
    final grades =
        (userData['gradeLevels'] as List<dynamic>? ?? []).cast<String>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final double maxSheetHeight = MediaQuery.of(ctx).size.height * 0.9;
        return Container(
          color: Colors.black.withOpacity(0.4),
          child: SafeArea(
            top: false,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF101922) : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxSheetHeight),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(
                    bottom: 24,
                    left: 16,
                    right: 16,
                    top: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 6, bottom: 12),
                          height: 5,
                          width: 72,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.grey.shade700
                                : const Color(0xFFDBE0E6),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            height: 96,
                            width: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark
                                  ? Colors.grey.shade700
                                  : const Color(0xFFF6F7F8),
                              image: profileImage != null
                                  ? DecorationImage(
                                      image: NetworkImage(profileImage),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: profileImage == null
                                ? Icon(
                                    Icons.person,
                                    size: 38,
                                    color: isDark
                                        ? Colors.grey.shade500
                                        : Colors.grey.shade400,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: _lexendTextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                if (isStudentProfile)
                                  Text(
                                    roleLabel,
                                    style: _lexendTextStyle(
                                      fontSize: 14,
                                      color: isDark
                                          ? Colors.grey.shade400
                                          : const Color(0xFF617589),
                                    ),
                                  )
                                else
                                  Row(
                                    children: [
                                      Text(
                                        rating.toStringAsFixed(1),
                                        style: _lexendTextStyle(
                                          fontSize: 14,
                                          color: isDark
                                              ? Colors.grey.shade400
                                              : const Color(0xFF617589),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      ..._buildRatingIcons(rating, isDark),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 3.3,
                        padding: EdgeInsets.zero,
                        children: [
                          _profileInfoTile('Sex', sex, isDark,
                              alignRight: false),
                          _profileInfoTile(
                              'Available Hours', '$hours hours/day', isDark,
                              alignRight: true),
                          _profileInfoTile(
                              'Available Days', '$days days/week', isDark,
                              alignRight: false),
                          if (!isStudentProfile)
                            _profileInfoTile(
                              'Price per Hour',
                              price == null
                                  ? '-'
                                  : 'Birr${price.toString()} /hr',
                              isDark,
                              alignRight: true,
                            ),
                          if (isStudentProfile)
                            _profileInfoTile('Preferred Tutor Gender',
                                preferredGender, isDark,
                                alignRight: true),
                          if (!isStudentProfile)
                            _profileInfoTile('Highest Qualification',
                                qualification, isDark,
                                spanTwo: true),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _chipSection(
                        title: 'Subjects Needed',
                        items: subjects,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                      _chipSection(
                        title: 'Grade Levels',
                        items: grades,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2B8CEE),
                                minimumSize: const Size.fromHeight(48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                Navigator.pop(ctx);
                                _startChat(
                                  name,
                                  userId ??
                                      '${_userRole == 'tutor' ? 'student' : 'tutor'}_fake_id_$name',
                                  isStudent: isStudentProfile,
                                );
                              },
                              child: Text(
                                'Message',
                                style: _lexendTextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          if (!isStudentProfile) ...[
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(48),
                                  side: BorderSide(
                                    color: isDark
                                        ? Colors.grey.shade700
                                        : const Color(0xFFD1D1D1),
                                  ),
                                  backgroundColor: isDark
                                      ? Colors.grey.shade800
                                      : const Color(0xFFF6F7F8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: userId == null
                                    ? null
                                    : () {
                                        Navigator.pop(ctx);
                                        _showReviewsSheet(
                                          tutorId: userId!,
                                          tutorName: name,
                                        );
                                      },
                                child: Text(
                                  'Show Reviews',
                                  style: _lexendTextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(
                              'Cancel',
                              style: _lexendTextStyle(
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.grey.shade400
                                    : const Color(0xFF617589),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildRatingIcons(double rating, bool isDark) {
    final icons = <Widget>[];
    int full = rating.floor();
    bool half = (rating - full) >= 0.25 && (rating - full) < 0.75;
    int total = half ? full + 1 : full;
    for (int i = 0; i < 5; i++) {
      if (i < full) {
        icons.add(const Icon(Icons.star, size: 18, color: Color(0xFFF6AC17)));
      } else if (half && i == full) {
        icons.add(
            const Icon(Icons.star_half, size: 18, color: Color(0xFFF6AC17)));
      } else {
        icons.add(Icon(Icons.star,
            size: 18,
            color: isDark ? Colors.grey.shade500 : Colors.grey.shade400));
      }
    }
    return icons;
  }

  Widget _profileInfoTile(String label, String value, bool isDark,
      {bool alignRight = false, bool spanTwo = false}) {
    final content = Column(
      crossAxisAlignment:
          alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: _lexendTextStyle(
            fontSize: 13,
            color: isDark ? Colors.grey.shade400 : const Color(0xFF617589),
          ),
        ),
        Text(
          value,
          style: _lexendTextStyle(
            fontSize: 14,
            color: isDark ? Colors.white : const Color(0xFF111418),
          ),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey.shade700 : const Color(0xFFDBE0E6),
          ),
        ),
      ),
      child: content,
    );
  }

  Widget _chipSection(
      {required String title,
      required List<String> items,
      required bool isDark}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: _lexendTextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF111418),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.isEmpty
              ? [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.grey.shade800
                          : const Color(0xFFF6F7F8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Not provided',
                      style: _lexendTextStyle(
                        color: isDark
                            ? Colors.grey.shade300
                            : const Color(0xFF111418),
                      ),
                    ),
                  )
                ]
              : items
                  .map(
                    (item) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.grey.shade800
                            : const Color(0xFFF6F7F8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        item,
                        style: _lexendTextStyle(
                          color: isDark
                              ? Colors.grey.shade300
                              : const Color(0xFF111418),
                        ),
                      ),
                    ),
                  )
                  .toList(),
        ),
      ],
    );
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('darkMode') ?? false;
    });
  }

  Future<void> _saveThemePreference(bool isDarkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', isDarkMode);
  }

  Future<void> _loadUserData() async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user != null) {
      var doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        setState(() {
          _userRole = doc.data()?['role'];
          _userName = doc.data()?['name'];
          _profileImage = doc.data()?['profileImage'];
          _userRating = (doc.data()?['rating'] as num?)?.toDouble();
        });
        await _maybeSendWelcome(user.uid);
      } else {
        doc = await FirebaseFirestore.instance
            .collection('tutors')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          setState(() {
            _userRole = 'tutor';
            _userName = doc.data()?['name'];
            _profileImage = doc.data()?['profileImage'];
            _userRating = (doc.data()?['rating'] as num?)?.toDouble();
          });
          await _maybeSendWelcome(user.uid);
        }
      }
    }
  }

  Future<void> _maybeSendWelcome(String userId) async {
    // Welcome notification now sent from info screens after profile completion.
    return;
  }

  /// Load recommendations:
  /// - For learners (student/parent): HYBRID (content + MF)
  /// - For tutors: content-only (tutor_recommendations)
  Future<void> _loadRecommendations() async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('🔥 _loadRecommendations: no current user');
      return;
    }

    if (!mounted) return;

    setState(() {
      _isLoadingRecommendations = true;
      _recommendationsError = null;
    });

    try {
      debugPrint('🔍 Loading recommendations for uid=${user.uid}');

      // 1️⃣ Get role from users collection
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get(const GetOptions(source: Source.server));

      final role = (userDoc.data()?['role'] as String?) ?? 'student';
      if (_userRole == null) {
        setState(() {
          _userRole = role;
        });
      }

      // 🔥 NEW: recompute content-based recs on the client
      await ContentRecommender.recomputeForCurrentUser();

      // 2️⃣ Branch by role
      if (role == 'tutor') {
        // ----------------------------
        // TUTOR SIDE → content-only
        // ----------------------------
        debugPrint(
            '👨‍🏫 Tutor: using tutor_recommendations (content-based only)');

        final doc = await FirebaseFirestore.instance
            .collection('tutor_recommendations')
            .doc(user.uid)
            .get(const GetOptions(source: Source.server));

        debugPrint(
            '📄 tutor_recommendations/${user.uid} exists: ${doc.exists}');
        debugPrint('📄 raw data: ${doc.data()}');

        if (!doc.exists || doc.data() == null) {
          if (!mounted) return;
          setState(() {
            _recommendedTutors = [];
            _recommendationsError = null;
          });
          return;
        }

        final data = doc.data()!;
        final rawItemsDynamic = data['items'];

        if (rawItemsDynamic == null) {
          debugPrint('⚠️ "items" field missing in tutor_recommendations doc.');
          if (!mounted) return;
          setState(() {
            _recommendedTutors = [];
            _recommendationsError = null;
          });
          return;
        }

        if (rawItemsDynamic is! List) {
          debugPrint(
            '❌ "items" is not a List. Got: ${rawItemsDynamic.runtimeType}',
          );
          if (!mounted) return;
          setState(() {
            _recommendedTutors = [];
            _recommendationsError =
                'Invalid recommendations format (items is not a list)';
          });
          return;
        }

        final rawItems = rawItemsDynamic.cast<dynamic>();
        debugPrint('✅ tutor items length = ${rawItems.length}');

        final items = <Map<String, dynamic>>[];
        for (final item in rawItems) {
          if (item is Map) {
            items.add(Map<String, dynamic>.from(item as Map));
          } else {
            debugPrint('⚠️ Skipping non-map tutor recommendation item: $item');
          }
        }

        if (!mounted) return;
        setState(() {
          _recommendedTutors = items;
          _recommendationsError = null;
        });
      } else {
        // ----------------------------
        // LEARNER SIDE → HYBRID
        // ----------------------------
        debugPrint('👩‍🎓 Learner: using hybrid (content + MF)');

        // Uses RecommendationService to merge:
        //   - recommendations/{learnerId}
        //   - mf_recommendations/{learnerId}
        final List<rec.HybridTutorRec> hybrid =
            await _recService.getHybridTutorRecommendationsForLearner(user.uid);

        debugPrint('✅ Hybrid returned ${hybrid.length} items');

        // Convert HybridTutorRec → Map<String,dynamic> so we can reuse
        // _buildRecommendedTutorCard(Map) with no UI changes.
        final items = <Map<String, dynamic>>[];
        for (final h in hybrid) {
          items.add({
            'tutorId': h.tutorId,
            'name': h.name ?? 'Tutor',
            'city': h.city ?? 'Location not set',
            'subjects': h.subjects,
            'gradeLevels': h.gradeLevels,
            'minPricePerHour': h.minPricePerHour,
            'score': h.finalScore, // 👈 hybrid final score
            'reasons': h.reasons, // may be empty
            // profileImage is not stored in MF recs — card will handle null
          });
        }

        if (!mounted) return;
        setState(() {
          _recommendedTutors = items;
          _recommendationsError = null;
        });
      }
    } catch (e, st) {
      debugPrint('❌ Error loading recommendations: $e');
      debugPrint('STACK:\n$st');

      if (!mounted) return;
      setState(() {
        _recommendedTutors = [];
        _recommendationsError = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() => _isLoadingRecommendations = false);
    }
  }

  // Role-based text helpers
  String _getWelcomeMessage() {
    switch (_userRole) {
      case 'tutor':
        return 'Find learners that match your expertise';
      case 'parent':
        return 'Find the perfect tutor for your child';
      case 'student':
      default:
        return 'Find the perfect tutor for your needs';
    }
  }

  String _getSearchHintText() {
    switch (_userRole) {
      case 'tutor':
        return 'Search students by name...';
      case 'parent':
      case 'student':
      default:
        return 'Search for tutors by name...';
    }
  }

  String _getSearchTargetRole() {
    switch (_userRole) {
      case 'tutor':
        return 'student'; // Tutors search for students
      case 'parent':
        return 'tutor'; // Parents search for tutors
      case 'student':
      default:
        return 'tutor'; // Students search for tutors
    }
  }

  String _getSearchTargetCollection() {
    switch (_userRole) {
      case 'tutor':
        return 'users'; // Tutors search in users collection for students
      case 'parent':
      case 'student':
      default:
        return 'users'; // Students/parents search in users collection for tutors
    }
  }

  String _getAIRecommendationTitle() {
    switch (_userRole) {
      case 'tutor':
        return 'AI Recommended Students';
      case 'parent':
      case 'student':
      default:
        return 'AI Recommended Tutors';
    }
  }

  String _getAIRecommendationSubtitle() {
    switch (_userRole) {
      case 'tutor':
        return 'Based on your expertise and teaching preferences';
      case 'parent':
      case 'student':
      default:
        return 'Based on your profile and learning preferences';
    }
  }

  // Updated to show "Your Learners" for tutors
  String _getTopRatedTitle() {
    switch (_userRole) {
      case 'tutor':
        return 'Your Learners';
      case 'parent':
      case 'student':
      default:
        return 'Top Rated Tutors';
    }
  }

  TextStyle _lexendTextStyle({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w500,
    Color? color,
  }) {
    return GoogleFonts.lexend(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  // HOME TAB
  Widget _buildHomeTab() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final defaultStyle = _lexendTextStyle(
      color: theme.colorScheme.onBackground,
    );

    return Container(
      color: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      child: DefaultTextStyle(
        style: defaultStyle,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with profile picture and theme toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (_profileImage != null)
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: NetworkImage(_profileImage!),
                        )
                      else
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.blue.shade100,
                          child: Text(
                            _userName != null && _userName!.isNotEmpty
                                ? _userName!.substring(0, 1).toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Hello, ${_userName ?? 'there'}! 👋",
                            style: _lexendTextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getWelcomeMessage(),
                            style: _lexendTextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () async {
                      final newMode = !_isDarkMode;
                      setState(() {
                        _isDarkMode = newMode;
                      });
                      await _saveThemePreference(newMode);
                      // Force rebuild of the entire app
                      (context as Element).markNeedsBuild();
                    },
                    icon: Icon(
                      _isDarkMode ? Icons.light_mode : Icons.dark_mode,
                      color: Colors.blue.shade700,
                      size: 28,
                    ),
                  ),
                ],
              ),

              if (_userRole == 'admin') ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/admin'),
                    icon: Icon(Icons.admin_panel_settings,
                        color: Colors.blue.shade700),
                    label: Text(
                      'Open Admin Console',
                      style: _lexendTextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 30),

              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF101922)
                        : const Color(0xFFF6F7F8),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 56,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1F2434)
                              : const Color(0xFFEFEFEF),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(24),
                            bottomLeft: Radius.circular(24),
                          ),
                        ),
                        child: const Icon(
                          Icons.search,
                          color: Colors.grey,
                          size: 28,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          onChanged: (value) {
                            if (_debounce?.isActive ?? false) {
                              _debounce!.cancel();
                            }
                            _debounce = Timer(
                              const Duration(milliseconds: 500),
                              () {
                                setState(() {
                                  _searchQuery = value;
                                });
                              },
                            );
                          },
                          style: _lexendTextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          decoration: InputDecoration(
                            hintText: _getSearchHintText(),
                            hintStyle: _lexendTextStyle(
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade500,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Search Results Section
              if (_searchQuery.isNotEmpty) ...[
                Text(
                  'Search Results for "$_searchQuery"',
                  style: _lexendTextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildSearchResults(),
                const SizedBox(height: 30),
              ],

              // Recommended Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recommended For You',
                    style: _lexendTextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _getAIRecommendationSubtitle(),
                style: _lexendTextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),

              // AI Recommended Cards
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(width: 4),
                    ..._buildRecommendationCards(),
                    const SizedBox(width: 4),
                  ],
                ),
              ),

              if (_userRole == 'tutor') ...[
                const SizedBox(height: 24),
                Text(
                  'My Schedules',
                  style: _lexendTextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildTutorScheduleSection(),
              ],

              if (_userRole == 'student' || _userRole == 'parent') ...[
                const SizedBox(height: 30),
                Text(
                  _getTopRatedTitle(),
                  style: _lexendTextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildTopRatedList(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Recommendation card for tutors viewing students (tutor_recommendations)
  Widget _buildRecommendedStudentCard(Map<String, dynamic> rec) {
    final name = (rec['name'] ?? 'Student').toString();
    final learnerId = (rec['learnerId'] ?? rec['studentId'] ?? '').toString();
    final city = (rec['city'] ?? 'Location not set').toString();

    final gradeLevels =
        (rec['gradeLevels'] as List<dynamic>? ?? []).cast<String>();
    final gradeText = gradeLevels.isEmpty
        ? 'Student'
        : 'Grades: ${gradeLevels.take(2).join(', ')}';

    final age = rec['age'];
    final gender = rec['sex']?.toString();
    final subjects = (rec['subjects'] as List<dynamic>? ?? []).cast<String>();
    final reasons = (rec['reasons'] as List<dynamic>? ?? []).cast<String>();
    final score = (rec['score'] as num?)?.toDouble() ?? 0.0;
    final matchPercent = (score.clamp(0.0, 1.0) * 100).round();
    final highlight =
        reasons.isNotEmpty ? reasons.first : 'Matches your expertise';
    final subjectsText = subjects.isEmpty
        ? 'Interests not provided'
        : 'Interests: ${subjects.take(3).join(', ')}';

    return SizedBox(
      width: 260,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      name.substring(0, 1),
                      style: _lexendTextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: _lexendTextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            gradeText,
                            if (age is num) 'Age ${age.toInt()}',
                            if (gender != null && gender.isNotEmpty) gender,
                            city,
                          ].where((e) => e.isNotEmpty).join(' • '),
                          style: _lexendTextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$matchPercent% match',
                      style: _lexendTextStyle(
                        fontSize: 11,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                highlight,
                style: _lexendTextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                subjectsText,
                style: _lexendTextStyle(
                  fontSize: 12,
                  color: Colors.blueGrey.shade600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _viewProfile(
                          name,
                          isStudent: true,
                          userId: learnerId.isEmpty ? null : learnerId,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue.shade700,
                        side: BorderSide(color: Colors.blue.shade700),
                        minimumSize: const Size(0, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'View Profile',
                        style: _lexendTextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: ElevatedButton(
                      onPressed: learnerId.isEmpty
                          ? null
                          : () {
                              _startChat(name, learnerId, isStudent: true);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Icon(Icons.chat, size: 18),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Legacy tutor card (used in some places)
  Widget _buildTutorCard(
    String name,
    String subjects,
    double rating,
    String recommendation,
    bool isAIRecommended,
    double width,
    int age,
    String city,
    double minPrice,
  ) {
    return SizedBox(
      width: width,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      name.substring(0, 1),
                      style: _lexendTextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: _lexendTextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '$age  • $city',
                          style: _lexendTextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isAIRecommended)
                    Icon(
                      Icons.auto_awesome,
                      color: Colors.amber.shade600,
                      size: 16,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                subjects,
                style: _lexendTextStyle(
                  fontSize: 12,
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber.shade600, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    rating.toString(),
                    style: _lexendTextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Birr$minPrice/hr',
                    style: _lexendTextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _viewProfile(name, isStudent: false);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue.shade700,
                        side: BorderSide(color: Colors.blue.shade700),
                        minimumSize: const Size(0, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'View Profile',
                        style: _lexendTextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: ElevatedButton(
                      onPressed: () {
                        _startChat(
                          name,
                          'tutor_fake_id_$name',
                          isStudent: false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Icon(Icons.chat, size: 18),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildRecommendationCards() {
    if (_isLoadingRecommendations) {
      return [
        _buildRecommendationStatusCard(
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      ];
    }

    if (_recommendationsError != null) {
      debugPrint('❌ _recommendationsError: $_recommendationsError');
      return [
        _buildRecommendationStatusCard(
          message: 'Unable to load recommendations.\nTap to retry.\n\n'
              'Details: $_recommendationsError',
          onTap: _loadRecommendations,
        ),
      ];
    }

    if (_recommendedTutors.isEmpty) {
      return [
        _buildRecommendationStatusCard(
          message: _userRole == 'tutor'
              ? 'No personalized students yet.\nUpdate your profile to get matches.'
              : 'No personalized tutors yet.\nUpdate your interests to get matches.',
        ),
      ];
    }

    final widgets = <Widget>[];
    for (final rec in _recommendedTutors) {
      if (widgets.isNotEmpty) {
        widgets.add(const SizedBox(width: 16));
      }
      widgets.add(_buildRecommendedTutorCard(rec));
    }
    return widgets;
  }

  Widget _buildRecommendationStatusCard({
    String? message,
    Widget? child,
    VoidCallback? onTap,
  }) {
    final content = child ??
        Text(
          message ?? '',
          textAlign: TextAlign.center,
          style: _lexendTextStyle(
            fontSize: 13,
            color: Colors.blueGrey.shade700,
            fontWeight: FontWeight.w500,
          ),
        );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blue.shade100),
        ),
        child: Center(child: content),
      ),
    );
  }

  Widget _buildRecommendedTutorCard(Map<String, dynamic> rec) {
    final name = (rec['name'] ?? 'Tutor').toString();
    final tutorId = (rec['tutorId'] ?? '').toString();
    final learnerId =
        (rec['learnerId'] ?? rec['studentId'] ?? rec['uid'] ?? '').toString();
    final city = (rec['city'] ?? 'Location not set').toString();
    final profileImage = rec['profileImage']?.toString();
    final reasons = (rec['reasons'] as List<dynamic>? ?? []).cast<String>();
    final reason =
        reasons.isNotEmpty ? reasons.first : 'Matches your learning goals';
    final score = (rec['score'] as num?)?.toDouble() ?? 0.85;
    final matchPercent = (score.clamp(0.0, 1.0) * 100).round();
    final theme = Theme.of(context);
    final viewingLearner = _userRole == 'tutor';
    final targetUserId = viewingLearner && learnerId.isNotEmpty
        ? learnerId
        : tutorId;
    final hasTarget = targetUserId.isNotEmpty;

    return Container(
      width: 320,
      margin: const EdgeInsets.only(right: 16, bottom: 12),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? const Color(0xFF10121C)
            : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              theme.brightness == Brightness.dark ? 0.32 : 0.08,
            ),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark
                        ? const Color(0xFF1F2434)
                        : const Color(0xFFEFEFEF),
                    borderRadius: BorderRadius.circular(20),
                    image: profileImage != null
                        ? DecorationImage(
                            image: NetworkImage(profileImage),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: profileImage == null
                      ? Icon(
                          Icons.person,
                          size: 36,
                          color: Colors.grey.shade500,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: _lexendTextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        city,
                        style: _lexendTextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: theme.brightness == Brightness.dark
                                    ? Colors.grey.shade800
                                    : const Color(0xFFE8EAEE),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: FractionallySizedBox(
                                  widthFactor:
                                      (matchPercent / 100).clamp(0.0, 1.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF6AC17),
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$matchPercent% Match',
                            style: _lexendTextStyle(
                              color: const Color(0xFFF6AC17),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              reason,
              style: _lexendTextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: hasTarget
                        ? () => _startChat(
                              name,
                              targetUserId,
                              isStudent: viewingLearner,
                            )
                        : null,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary.withOpacity(
                        0.18,
                      ),
                      foregroundColor: theme.colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Message',
                      style: _lexendTextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: hasTarget
                        ? () => _viewProfile(
                              name,
                              isStudent: viewingLearner,
                              userId: targetUserId,
                            )
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'View Profile',
                      style: _lexendTextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Unified profile view dialog
  Future<void> _viewProfile(
    String name, {
    bool isStudent = false,
    String? userId,
    Map<String, dynamic>? userData,
  }) async {
    final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (!isStudent &&
        userId != null &&
        currentUser != null &&
        _userRole != 'tutor') {
      InteractionLogger.recordLearnerInteraction(
        learnerId: currentUser.uid,
        tutorId: userId,
        event: 'view',
      );
    }

    Map<String, dynamic> effectiveData = userData ?? {};
    if (userId != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get(const GetOptions(source: Source.serverAndCache));
        if (doc.exists && doc.data() != null) {
          final fetched = doc.data()!;
          effectiveData = {...fetched, ...effectiveData};
        }
      } catch (e) {
        debugPrint('viewProfile fetch error: $e');
      }
    }

    _showTutorProfileSheet(
      name: name,
      userId: userId,
      userData: effectiveData,
      isStudentProfile: isStudent,
    );
  }

  Widget _buildSearchResults() {
    // Creates a new stream for each search query
    Stream<QuerySnapshot> searchStream() async* {
      if (_searchQuery.isEmpty) {
        return;
      }
      try {
        final targetRole = _getSearchTargetRole();
        final collection = _getSearchTargetCollection();

        final snapshot = await FirebaseFirestore.instance
            .collection(collection)
            .where('role', isEqualTo: targetRole)
            .where('name', isGreaterThanOrEqualTo: _searchQuery)
            .where('name', isLessThanOrEqualTo: '${_searchQuery}\uf8ff')
            .limit(20)
            .get();

        yield snapshot;
      } catch (e) {
        debugPrint('🔴 Stream Error: $e');
        yield* Stream<QuerySnapshot>.empty();
      }
    }

    return StreamBuilder<QuerySnapshot>(
      stream: searchStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Searching...',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          final error = snapshot.error.toString();
          debugPrint('🔴 Search Error: $error');

          if (error.contains('index') ||
              error.contains('FAILED_PRECONDITION')) {
            debugPrint('🔧 INDEX REQUIRED: $error');
            return _buildIndexRequiredMessage();
          }

          return Center(
            child: Column(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Search Error',
                  style: _lexendTextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please check your connection or try again',
                  style: _lexendTextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: Text(
                    'Retry Search',
                    style: _lexendTextStyle(),
                  ),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          debugPrint('✅ No results found for "$_searchQuery"');
          return const Center(
            child: Column(
              children: [
                Icon(Icons.search_off, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No results found',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  'Try searching with a different name',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final results = snapshot.data!.docs;
        debugPrint(
          '✅ SERVER-SIDE SEARCH: Found ${results.length} results for "$_searchQuery"',
        );

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.bolt, color: Colors.green.shade700, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fast Search Enabled',
                          style: _lexendTextStyle(
                            fontSize: 14,
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Results from ${results.length} ${_userRole == 'tutor' ? 'students' : 'tutors'}',
                          style: _lexendTextStyle(
                            fontSize: 12,
                            color: Colors.green.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ...results.map((doc) => _buildSearchResultCard(doc)).toList(),
          ],
        );
      },
    );
  }

  Widget _buildIndexRequiredMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.build, size: 64, color: Colors.orange.shade600),
            const SizedBox(height: 24),
            Text(
              'Search Optimization Required',
              style: _lexendTextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'To enable fast search for 1000+ users, we need to create a search index.',
              style: _lexendTextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Quick Fix:',
                      style: _lexendTextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '1. Check your console for a Firebase index link\n'
                      '2. Click the link to create the index\n'
                      '3. Wait 2–5 minutes for it to build\n'
                      '4. Search will become instant!',
                      style: _lexendTextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {});
              },
              icon: const Icon(Icons.search),
              label: Text(
                'Use Basic Search For Now',
                style: _lexendTextStyle(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultCard(DocumentSnapshot doc) {
    final userData = doc.data() as Map<String, dynamic>;
    final userId = doc.id;
    final name = userData['name'] ?? 'Unknown';
    final sex = userData['sex'] ?? '';
    final age = userData['age'];
    final city = userData['city'] ?? '';
    final subjects =
        (userData['subjects'] as List<dynamic>? ?? []).cast<String>();
    final gradeLevels =
        (userData['gradeLevels'] as List<dynamic>? ?? []).cast<String>();
    final qualification = userData['qualification']?.toString();
    final available = userData['available'] == true;
    final profileImage = userData['profileImage'];
    final isVerified = userData['verified'] ?? false;

    final isStudent = _userRole == 'tutor';
    final displayInfo = isStudent
        ? userData['grade'] ?? 'Student'
        : 'Birr${userData['minPricePerHour'] ?? 0}/hr';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          backgroundImage:
              profileImage != null ? NetworkImage(profileImage) : null,
          child: profileImage == null
              ? Text(
                  name.substring(0, 1),
                  style: _lexendTextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Row(
          children: [
            Text(
              name,
              style: _lexendTextStyle(fontWeight: FontWeight.w600),
            ),
            if (isVerified && !isStudent) ...[
              const SizedBox(width: 4),
              Icon(Icons.verified, color: Colors.blue.shade700, size: 16),
            ],
            if (!isStudent) ...[
              const SizedBox(width: 8),
              RatingBadge(tutorId: userId),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              [
                if (age is num) 'Age ${age.toInt()}',
                if (sex != '') sex,
                if (!isStudent && city.isNotEmpty) city,
              ].join(' • '),
              style: _lexendTextStyle(),
            ),
            if (!isStudent && subjects.isNotEmpty)
              Text(
                'Subjects: ${subjects.take(3).join(', ')}',
                style: _lexendTextStyle(),
              ),
            if (!isStudent && gradeLevels.isNotEmpty)
              Text(
                'Grades: ${gradeLevels.take(3).join(', ')}',
                style: _lexendTextStyle(),
              ),
            if (!isStudent && qualification != null && qualification.isNotEmpty)
              Text(
                'Qualification: $qualification',
                style: _lexendTextStyle(),
              ),
            if (!isStudent)
              Text(
                '${available ? 'Available' : 'Unavailable'} • $displayInfo',
                style: _lexendTextStyle(
                  color:
                      available ? Colors.green.shade700 : Colors.red.shade400,
                  fontWeight: FontWeight.w600,
                ),
              ),
            if (isStudent)
              Text(
                '$sex • $displayInfo',
                style: _lexendTextStyle(),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.chat, color: Colors.green.shade600),
              onPressed: () {
                _startChat(name, userId, isStudent: isStudent);
              },
            ),
            IconButton(
              icon: Icon(Icons.visibility, color: Colors.blue.shade700),
              onPressed: () {
                _viewProfile(
                  name,
                  isStudent: isStudent,
                  userId: userId,
                  userData: userData,
                );
              },
            ),
          ],
        ),
        onTap: () {
          _viewProfile(
            name,
            isStudent: isStudent,
            userId: userId,
            userData: userData,
          );
        },
      ),
    );
  }

  void _startChat(
    String personName,
    String personId, {
    bool isStudent = false,
  }) {
    final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (currentUser == null || personId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to start chat right now.',
            style: _lexendTextStyle(),
          ),
        ),
      );
      return;
    }

    FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get().then((doc) {
      if (_userRole != 'tutor' && !isStudent) {
        InteractionLogger.recordLearnerInteraction(
          learnerId: currentUser.uid,
          tutorId: personId,
          event: 'view',
        );
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            receiverId: personId,
            receiverName: personName,
          ),
        ),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to start chat: $error',
            style: _lexendTextStyle(),
          ),
        ),
      );
    });
  }

  Widget _buildTopRatedList() {
    if (_userRole == 'tutor') {
      return _buildTutorLearnersList();
    }

    // Fetch tutors then sort by rating client-side (avoids index issues)
    final userQuery = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'tutor')
        .limit(50);

    return StreamBuilder<QuerySnapshot>(
      stream: userQuery.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          final error = snapshot.error.toString();
          debugPrint('🔥 TopRated error: $error');
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: _lexendTextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Text(
              'No tutors available.',
              style: _lexendTextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          );
        }

        // Sort by rating desc client-side
        final sorted = List<QueryDocumentSnapshot>.from(docs)
          ..sort((a, b) {
            final ra = ((a.data() as Map<String, dynamic>?)?['rating'] as num?)
                    ?.toDouble() ??
                0.0;
            final rb = ((b.data() as Map<String, dynamic>?)?['rating'] as num?)
                    ?.toDouble() ??
                0.0;
            return rb.compareTo(ra);
          });

        return _renderTopRatedDocs(sorted.take(5).toList());
      },
    );
  }

  Widget _renderTopRatedDocs(List<QueryDocumentSnapshot> docs) {
    if (docs.isEmpty) {
      return Center(
        child: Text(
          'No tutors available.',
          style: _lexendTextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
      );
    }

    return Column(
      children: docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final rating = (data['rating'] as num?)?.toDouble() ?? (data['ratingAvg'] as num?)?.toDouble() ?? 0.0;
        final city = (data['city'] ?? '').toString();
        return _buildUserListItem(
          data['name'] ?? 'Unknown',
          data['sex'] ?? '',
          'Rating ${rating.toStringAsFixed(1)}',
          doc.id,
          data['profileImage'],
          data['verified'] ?? false,
          rating: rating,
          city: city,
          viewOnly: true,
        );
      }).toList(),
    );
  }

  void _showReviewsSheet(
      {required String tutorId, required String tutorName}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final textColor =
            isDark ? Colors.white : const Color(0xFF111418);

        Future<Map<String, dynamic>> loadData() async {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(tutorId)
              .get(const GetOptions(source: Source.serverAndCache));
          final data = doc.data() ?? {};
          final ratingsSnap = await FirebaseFirestore.instance
              .collection('users')
              .doc(tutorId)
              .collection('ratings')
              .orderBy('updatedAt', descending: true)
              .limit(20)
              .get();
          return {
            'user': data,
            'reviews': ratingsSnap.docs,
          };
        }

        return FutureBuilder<Map<String, dynamic>>(
          future: loadData(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF101922)
                      : Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            final userData =
                snapshot.data!['user'] as Map<String, dynamic>? ?? {};
            final reviews =
                snapshot.data!['reviews'] as List<QueryDocumentSnapshot>;
            final avg = (userData['rating'] as num?)?.toDouble() ??
                (userData['ratingAvg'] as num?)?.toDouble() ??
                0.0;
            final count = (userData['ratingCount'] as num?)?.toInt() ?? 0;

            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF101922) : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        height: 5,
                        width: 72,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey.shade700
                              : const Color(0xFFDBE0E6),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    Text(
                      'Reviews for $tutorName',
                      style: _lexendTextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star,
                            size: 20, color: Color(0xFFF6AC17)),
                        const SizedBox(width: 6),
                        Text(
                          avg.toStringAsFixed(1),
                          style: _lexendTextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '($count reviews)',
                          style: _lexendTextStyle(
                            fontSize: 13,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (reviews.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'No reviews yet.',
                          style: _lexendTextStyle(
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: reviews.length,
                        itemBuilder: (context, index) {
                          final rev =
                              reviews[index].data() as Map<String, dynamic>;
                          final score =
                              (rev['score'] as num?)?.toInt() ?? 0;
                          final comment =
                              (rev['comment'] ?? '').toString().trim();
                          final updatedAt =
                              rev['updatedAt'] as Timestamp?;
                          final when = updatedAt != null
                              ? updatedAt.toDate().toLocal()
                              : null;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.grey.shade900
                                  : const Color(0xFFF6F7F8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.star,
                                        size: 16,
                                        color: Color(0xFFF6AC17)),
                                    const SizedBox(width: 4),
                                    Text(
                                      score.toString(),
                                      style: _lexendTextStyle(
                                          fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(width: 8),
                                    if (when != null)
                                      Text(
                                        _formatTime(when),
                                        style: _lexendTextStyle(
                                          fontSize: 12,
                                          color: isDark
                                              ? Colors.grey.shade500
                                              : Colors.grey.shade600,
                                        ),
                                      ),
                                  ],
                                ),
                                if (comment.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    comment,
                                    style: _lexendTextStyle(
                                      color: isDark
                                          ? Colors.grey.shade300
                                          : const Color(0xFF111418),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTutorLearnersList() {
    final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const SizedBox.shrink();

    final query = FirebaseFirestore.instance
        .collection('tutoring_relationships')
        .where('tutorId', isEqualTo: currentUser.uid)
        .where('status', isEqualTo: 'active')
        .orderBy('startedAt', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading learners: ${snapshot.error}',
              style: _lexendTextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }

        final relations = snapshot.data?.docs ?? [];
        if (relations.isEmpty) {
          return Center(
            child: Text(
              'No active learners yet.',
              style: _lexendTextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          );
        }

        return Column(
          children: relations
              .map(
                (rel) => FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(rel['studentId'])
                      .get(),
                  builder: (context, userSnap) {
                    if (!userSnap.hasData) return const SizedBox.shrink();
                    final student = userSnap.data!;
                    final data = student.data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: Text(
                          data['name'] ?? 'Learner',
                          style: _lexendTextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          data['gradeLevels'] != null
                              ? (data['gradeLevels'] as List).join(', ')
                              : 'Grade info missing',
                          style: _lexendTextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.message,
                                  color: Colors.green.shade600, size: 20),
                              onPressed: () {
                                _startChat(
                                  data['name'] ?? 'Learner',
                                  student.id,
                                  isStudent: true,
                                );
                              },
                            ),
                            TextButton(
                              onPressed: () => _viewProfile(
                                data['name'] ?? 'Learner',
                                isStudent: true,
                                userId: student.id,
                                userData: data,
                              ),
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.blue.shade700,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'View Profile',
                                style: _lexendTextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildUserListItem(
    String name,
    String sex,
    String displayInfo,
    String userId,
    String? profileImage,
    bool isVerified, {
    bool isStudent = false,
    double? rating,
    bool viewOnly = false,
    String? city,
  }) {
    Widget subtitle;
    if (rating != null) {
      subtitle = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star, size: 16, color: Color(0xFFF6AC17)),
              const SizedBox(width: 4),
              Text(
                rating.toStringAsFixed(1),
                style: _lexendTextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          if (city != null && city.isNotEmpty)
            Text(
              city,
              style: _lexendTextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
        ],
      );
    } else {
      subtitle = Text(
        '$sex • $displayInfo',
        style: _lexendTextStyle(),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          backgroundImage:
              profileImage != null ? NetworkImage(profileImage) : null,
          child: profileImage == null
              ? Text(
                  name.substring(0, 1),
                  style: _lexendTextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Row(
          children: [
            Text(
              name,
              style: _lexendTextStyle(fontWeight: FontWeight.w600),
            ),
            if (isVerified && !isStudent) ...[
              const SizedBox(width: 4),
              Icon(Icons.verified, color: Colors.blue.shade700, size: 16),
            ],
          ],
        ),
        subtitle: subtitle,
        trailing: viewOnly
            ? OutlinedButton(
                onPressed: () {
                  _viewProfile(name, isStudent: isStudent, userId: userId);
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  side: const BorderSide(color: Color(0xFF2B8CEE)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'View Profile',
                  style: _lexendTextStyle(
                    color: const Color(0xFF2B8CEE),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              )
            : IconButton(
                icon: Icon(Icons.chat, color: Colors.green.shade600, size: 20),
                onPressed: () {
                  _startChat(name, userId, isStudent: isStudent);
                },
              ),
        onTap: () {
          FirebaseFirestore.instance.collection('users').doc(userId).get().then(
            (doc) {
              if (doc.exists) {
                _viewProfile(
                  name,
                  isStudent: isStudent,
                  userId: userId,
                  userData: doc.data() as Map<String, dynamic>,
                );
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildMessagesTab() {
    final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Center(
        child: Text(
          'Please login to view messages',
          style: _lexendTextStyle(),
        ),
      );
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF101922) : const Color(0xFFF6F7F8);
    final cardColor = isDark ? theme.colorScheme.surfaceVariant : Colors.white;
    const primaryColor = Color(0xFF2B8CEE);

    return StreamBuilder<List<Message>>(
      stream: Provider.of<MessageProvider>(
        context,
      ).getConversations(currentUser.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: _lexendTextStyle(),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your conversations will appear here',
                          style: _lexendTextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        final conversations = snapshot.data!;
        final filtered = conversations.where((c) {
          final isSender = c.senderId == currentUser.uid;
          final otherName =
              (isSender ? c.receiverName : c.senderName).toLowerCase();
          final lastMsg = c.content.toLowerCase();
          final q = _messageSearchQuery.toLowerCase();
          if (q.isEmpty) return true;
          return otherName.contains(q) || lastMsg.contains(q);
        }).toList();

        return Container(
          color: bgColor,
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: bgColor,
                child: Center(
                  child: Text(
                    'Messages',
                    style: _lexendTextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onBackground,
                    ),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? theme.colorScheme.surfaceVariant
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      Icon(Icons.search,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _messageSearchController,
                          onChanged: (v) =>
                              setState(() => _messageSearchQuery = v),
                          style: _lexendTextStyle(
                            color: theme.colorScheme.onSurface,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search for a conversation...',
                            hintStyle: _lexendTextStyle(
                                color: isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade500),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final conversation = filtered[index];
                    final isCurrentUserSender =
                        conversation.senderId == currentUser.uid;
                    final otherPersonName = isCurrentUserSender
                        ? conversation.receiverName
                        : conversation.senderName;
                    final otherPersonId = isCurrentUserSender
                        ? conversation.receiverId
                        : conversation.senderId;
                    final isUnread =
                        conversation.receiverId == currentUser.uid &&
                            !conversation.isRead;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color:
                                Colors.black.withOpacity(isDark ? 0.15 : 0.07),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                receiverId: otherPersonId,
                                receiverName: otherPersonName,
                              ),
                            ),
                          );
                        },
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: const Color(0xFFE5ECFA),
                              child: Text(
                                otherPersonName.substring(0, 1).toUpperCase(),
                                style: _lexendTextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          otherPersonName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: _lexendTextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _formatTime(conversation.timestamp),
                                        style: _lexendTextStyle(
                                          fontSize: 12,
                                          color: isDark
                                              ? Colors.grey.shade500
                                              : Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          conversation.content,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: _lexendTextStyle(
                                            fontSize: 14,
                                            color: isDark
                                                ? Colors.grey.shade300
                                                : Colors.grey.shade600,
                                          ),
                                        ),
                                      ),
                                      if (isUnread) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          height: 20,
                                          width: 20,
                                          decoration: const BoxDecoration(
                                            color: primaryColor,
                                            shape: BoxShape.circle,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            '1',
                                            style: _lexendTextStyle(
                                              fontSize: 12,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    IconData icon;
    Color iconColor;

    switch (notification.type) {
      case 'meeting_request':
        icon = Icons.person_add;
        iconColor = Colors.blue.shade700;
        break;
      case 'meeting_accepted':
        icon = Icons.check_circle;
        iconColor = Colors.green.shade700;
        break;
      case 'meeting_declined':
        icon = Icons.cancel;
        iconColor = Colors.red.shade700;
        break;
      case 'meeting_reminder':
        icon = Icons.access_time;
        iconColor = Colors.orange.shade700;
        break;
      case 'verification_required':
        icon = Icons.verified;
        iconColor = Colors.purple.shade700;
        break;
      default:
        icon = Icons.notifications;
        iconColor = Colors.grey.shade700;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          notification.title,
          style: _lexendTextStyle(
            fontWeight:
                notification.isRead ? FontWeight.normal : FontWeight.w600,
            color: notification.isRead ? Colors.grey : Colors.black,
          ),
        ),
        subtitle: Text(
          notification.body,
          style: _lexendTextStyle(
            color: notification.isRead ? Colors.grey : Colors.black87,
          ),
        ),
        trailing: notification.isRead
            ? null
            : Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
        onTap: () {
          Provider.of<NotificationProvider>(
            context,
            listen: false,
          ).markAsRead(notification.id);

          _handleNotificationTap(notification);
        },
      ),
    );
  }

  Widget _buildNotificationsTab() {
    final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Center(
        child: Text(
          'Please login to view notifications',
          style: _lexendTextStyle(),
        ),
      );
    }

    final currentUserId = currentUser.uid;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F8FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.notifications_none, color: Color(0xFF2B8CEE)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _userRole == 'tutor'
                        ? 'Stay updated with your teaching activities'
                        : 'Stay updated with your learning journey',
                    style: _lexendTextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<List<NotificationModel>>(
              stream: Provider.of<NotificationProvider>(
                context,
                listen: true,
              ).getUserNotifications(currentUserId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: _lexendTextStyle(),
                    ),
                  );
                }

                final notifications = snapshot.data ?? [];

                if (notifications.isEmpty) {
                  return const ui.EmptyState(
                    icon: Icons.notifications_off,
                    title: 'No notifications yet',
                    message: 'Your notifications will appear here',
                  );
                }

                return ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return _buildNotificationItem(notification);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(NotificationModel notification) {
    if (notification.type.startsWith('tutoring_request')) {
      setState(() {
        _selectedIndex = 3;
        _relationshipsInitialTab =
            notification.type == 'tutoring_request' ? 0 : 1;
      });
    }
  }

  Widget _buildTutorScheduleSection() {
    final uid = firebase_auth.FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();
    final stream = Provider.of<MessageProvider>(context, listen: false)
        .getTutoringRelationships(uid);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('schedule stream error: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !(snapshot.hasData && (snapshot.data?.isNotEmpty ?? false))) {
          return const Center(child: CircularProgressIndicator());
        }

        final rels = snapshot.data ?? const [];
        if (rels.isEmpty) {
          return Text(
            'No scheduled sessions yet.',
            style: _lexendTextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          );
        }

        final Map<String, List<String>> schedule = {};
        for (final rel in rels) {
          final name = rel['studentName']?.toString() ?? 'Learner';
          final days =
              (rel['preferredDays'] as List<dynamic>? ?? const []).cast<String>();
          if (days.isEmpty) {
            schedule.putIfAbsent('Unscheduled', () => []).add(name);
          } else {
            for (final d in days) {
              schedule.putIfAbsent(d, () => []).add(name);
            }
          }
        }

        const dayOrder = [
          'Sun',
          'Mon',
          'Tue',
          'Wed',
          'Thu',
          'Fri',
          'Sat',
          'Unscheduled'
        ];

        final entries = schedule.entries.toList()
          ..sort((a, b) =>
              dayOrder.indexOf(a.key).compareTo(dayOrder.indexOf(b.key)));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: entries.map((entry) {
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.key,
                    style: _lexendTextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: entry.value
                        .map(
                          (name) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F8FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              name,
                              style: _lexendTextStyle(
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildProfileTab() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
    final isTutor = _userRole == 'tutor';
    final messageProvider =
        Provider.of<MessageProvider>(context, listen: false);
    final relationshipsStream = currentUser == null
        ? Stream<List<Map<String, dynamic>>>.value(const [])
        : (isTutor
            ? messageProvider.getTutoringRelationships(currentUser.uid)
            : messageProvider.getStudentRelationships(currentUser.uid));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blue.shade100,
                    backgroundImage: _profileImage != null
                        ? NetworkImage(_profileImage!)
                        : null,
                    child: _profileImage == null
                        ? Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.blue.shade700,
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _userName ?? 'User Name',
                    style: _lexendTextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userRole?.toUpperCase() ?? 'STUDENT',
                    style: _lexendTextStyle(
                      fontSize: 14,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: relationshipsStream,
                    builder: (context, snapshot) {
                      final rels = snapshot.data ?? const [];
                      final active = rels
                          .where((r) =>
                              (r['status'] ?? '').toString().toLowerCase() ==
                              'active')
                          .toList();
                      final counterpartCount = active.length;
                      final sessions = active.fold<int>(0, (sum, rel) {
                        final d = rel['daysPerWeek'];
                        if (d is num) return sum + d.toInt();
                        return sum;
                      });
                      final stats = <Widget>[
                        _buildProfileStat(
                          isTutor ? 'Students' : 'Tutors',
                          counterpartCount.toString(),
                        ),
                        _buildProfileStat('Sessions', sessions.toString()),
                      ];
                      if (isTutor) {
                        final ratingText = _userRating != null
                            ? _userRating!.toStringAsFixed(1)
                            : '--';
                        stats.add(_buildProfileStat('Rating', ratingText));
                      }
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: stats,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildProfileOption(
                  'Edit Profile',
                  Icons.edit_outlined,
                  onTap: () {
                    final role = _userRole ?? 'student';
                    switch (role) {
                      case 'tutor':
                        Navigator.pushNamed(context, '/tutor-info');
                        break;
                      case 'parent':
                        Navigator.pushNamed(context, '/parent-info');
                        break;
                      case 'student':
                      default:
                        Navigator.pushNamed(context, '/student-info');
                    }
                  },
                ),
                _buildProfileOption('Settings', Icons.settings_outlined),
                _buildProfileOption('Help & Support', Icons.help_outline),
                _buildProfileOption(
                  'Logout',
                  Icons.logout,
                  isLogout: true,
                  onTap: () async {
                    await authProvider.logout();
                    Navigator.pushReplacementNamed(context, '/');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: _lexendTextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: _lexendTextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileOption(
    String title,
    IconData icon, {
    bool isLogout = false,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: isLogout ? Colors.red : Colors.blue.shade700),
      title: Text(
        title,
        style: _lexendTextStyle(
          color: isLogout ? Colors.red : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _messageSearchController.dispose();
    super.dispose();
  }

  Stream<int> _getUnreadMessageCount() {
    final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (currentUser == null) return Stream.value(0);

    return FirebaseFirestore.instance
        .collection('messages')
        .where('receiverId', isEqualTo: currentUser.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length)
        .handleError((error) {
      return 0;
    });
  }

  Stream<int> _getUnreadNotificationCount() {
    final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (currentUser == null) return Stream.value(0);

    return FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: currentUser.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length)
        .handleError((error) {
      return 0;
    });
  }

  Stream<int> _getRelationshipAttentionCount() {
    final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (currentUser == null) return Stream.value(0);

    final uid = currentUser.uid;
    if (_userRole == 'tutor') {
      return FirebaseFirestore.instance
          .collection('meetingRequests')
          .where('toUserId', isEqualTo: uid)
          .where('status', isEqualTo: 'pending')
          .snapshots()
          .map((s) => s.docs.length)
          .handleError((error) {
        return 0;
      });
    } else {
      return FirebaseFirestore.instance
          .collection('meetingRequests')
          .where('fromUserId', isEqualTo: uid)
          .where('status', isEqualTo: 'approved')
          .where('studentVerifiedMeeting', isEqualTo: false)
          .snapshots()
          .map((s) => s.docs.length)
          .handleError((error) {
        return 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      debugShowCheckedModeBanner: false,
      home: Builder(
        builder: (context) => Scaffold(
          appBar: null,
          body: SafeArea(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                _buildHomeTab(), // index 0
                _buildMessagesTab(), // index 1
                _buildNotificationsTab(), // index 2
                RelationshipsScreen(
                  initialTab: _relationshipsInitialTab,
                ), // index 3
                _buildProfileTab(), // index 4
              ],
            ),
          ),
          bottomNavigationBar: StreamBuilder<int>(
            stream: _getUnreadMessageCount(),
            builder: (context, msgSnapshot) {
              final unreadMsgCount = msgSnapshot.data ?? 0;

              return StreamBuilder<int>(
                stream: _getUnreadNotificationCount(),
                builder: (context, notifSnapshot) {
                  final unreadNotifCount = notifSnapshot.data ?? 0;
                  final effectiveNotifCount =
                      _selectedIndex == 2 ? 0 : unreadNotifCount;

                  return StreamBuilder<int>(
                    stream: _getRelationshipAttentionCount(),
                    builder: (context, relSnapshot) {
                      final relCount = relSnapshot.data ?? 0;
                      final effectiveRelCount = 0;

                      return Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: BottomNavigationBar(
                          currentIndex: _selectedIndex,
                          onTap: (index) {
                            setState(() => _selectedIndex = index);
                          },
                          type: BottomNavigationBarType.fixed,
                          backgroundColor: Colors.white,
                          selectedItemColor: Colors.blue.shade700,
                          unselectedItemColor: Colors.grey.shade600,
                          selectedLabelStyle: _lexendTextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                          unselectedLabelStyle: _lexendTextStyle(),
                          items: [
                            BottomNavigationBarItem(
                              icon: const Icon(Icons.home_outlined),
                              activeIcon: const Icon(Icons.home),
                              label: 'Home',
                            ),
                            BottomNavigationBarItem(
                              icon: Stack(
                                children: [
                                  const Icon(Icons.chat_bubble_outline),
                                  if (unreadMsgCount > 0)
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 16,
                                          minHeight: 16,
                                        ),
                                        child: Text(
                                          unreadMsgCount > 99
                                              ? '99+'
                                              : unreadMsgCount.toString(),
                                          style: _lexendTextStyle(
                                            color: Colors.white,
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              activeIcon: Stack(
                                children: [
                                  const Icon(Icons.chat),
                                  if (unreadMsgCount > 0)
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 16,
                                          minHeight: 16,
                                        ),
                                        child: Text(
                                          unreadMsgCount > 99
                                              ? '99+'
                                              : unreadMsgCount.toString(),
                                          style: _lexendTextStyle(
                                            color: Colors.white,
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              label: 'Messages',
                            ),
                            BottomNavigationBarItem(
                              icon: Stack(
                                children: [
                                  const Icon(Icons.notifications_outlined),
                                  if (effectiveNotifCount > 0)
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 16,
                                          minHeight: 16,
                                        ),
                                        child: Text(
                                          effectiveNotifCount > 99
                                              ? '99+'
                                              : effectiveNotifCount.toString(),
                                          style: _lexendTextStyle(
                                            color: Colors.white,
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              activeIcon: const Icon(Icons.notifications),
                              label: 'Notifications',
                            ),
                            BottomNavigationBarItem(
                              icon: Stack(
                                children: [
                                  const Icon(Icons.group_outlined),
                                  if (effectiveRelCount > 0)
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 16,
                                          minHeight: 16,
                                        ),
                                        child: Text(
                                          effectiveRelCount > 99
                                              ? '99+'
                                              : effectiveRelCount.toString(),
                                          style: _lexendTextStyle(
                                            color: Colors.white,
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              activeIcon: const Icon(Icons.group),
                              label: 'Relationships',
                            ),
                            BottomNavigationBarItem(
                              icon: const Icon(Icons.person_outlined),
                              activeIcon: const Icon(Icons.person),
                              label: 'Profile',
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
