import 'package:cloud_firestore/cloud_firestore.dart';

class TutoringRequest {
  final String id;
  final String studentId;
  final String studentName;
  final String tutorId;
  final String tutorName;
  final String status; // pending / approved / declined
  final String message;
  final List<String> subjects;
  final List<String> preferredDays;
  final int hoursPerWeek;
  final Timestamp createdAt;

  TutoringRequest({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.tutorId,
    required this.tutorName,
    this.status = 'pending',
    this.message = '',
    this.subjects = const [],
    this.preferredDays = const [],
    this.hoursPerWeek = 0,
    Timestamp? createdAt,
  }) : createdAt = createdAt ?? Timestamp.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'tutorId': tutorId,
      'tutorName': tutorName,
      'status': status,
      'message': message,
      'subjects': subjects,
      'preferredDays': preferredDays,
      'hoursPerWeek': hoursPerWeek,
      'createdAt': createdAt,
    };
  }

  factory TutoringRequest.fromMap(Map<String, dynamic> map) {
    return TutoringRequest(
      id: map['id'] ?? '',
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      tutorId: map['tutorId'] ?? '',
      tutorName: map['tutorName'] ?? '',
      status: map['status'] ?? 'pending',
      message: map['message'] ?? '',
      subjects: List<String>.from(map['subjects'] ?? []),
      preferredDays: List<String>.from(map['preferredDays'] ?? []),
      hoursPerWeek: (map['hoursPerWeek'] as num?)?.toInt() ?? 0,
      createdAt: map['createdAt'] ?? Timestamp.now(),
    );
  }
}


// import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart';
// import 'package:provider/provider.dart';
// import '../providers/auth_provider.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
// import '../providers/message_provider.dart';
// import '../screens/chat_screen.dart';
// import '../models/message_model.dart';
// import '../screens/relationships_screen.dart';
// import 'dart:async';
// import '../models/notification_model.dart';
// import '../providers/notification_provider.dart';
// import '../widgets/ui/rating_badge.dart';
// import '../theme/app_theme.dart';
// import '../widgets/ui/empty_state.dart' as ui;
// import '../services/interaction_logger.dart';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   int _selectedIndex = 0;
//   String? _userName;
//   String? _userRole;
//   String? _profileImage;
//   bool _isDarkMode = false;

//   // Search filters
//   String _selectedSubject = 'All Subjects';
//   String _selectedGrade = 'All Grades';
//   double _priceRange = 500;
//   bool _onlyVerified = true;
//   String _searchQuery = '';

//   bool _isLoadingRecommendations = false;
//   String? _recommendationsError;
//   List<Map<String, dynamic>> _recommendedTutors = [];

//   final List<String> _subjects = [
//     'All Subjects',
//     'Mathematics',
//     'English',
//     'Amharic',
//     'Tigrigna',
//     'Physics',
//     'Chemistry',
//     'Biology',
//     'ICT',
//   ];

//   final List<String> _grades = [
//     'All Grades',
//     'KG',
//     '1–4',
//     '5–6',
//     '7–8',
//     '9–10',
//     '11–12',
//   ];

//   // Debounce timer for search
//   Timer? _debounce;

//   @override
//   void initState() {
//     super.initState();
//     _loadUserData();
//     _loadRecommendations();
//     _searchQuery = '';
//   }

//   Future<void> _loadUserData() async {
//     final user = firebase_auth.FirebaseAuth.instance.currentUser;
//     if (user != null) {
//       var doc = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(user.uid)
//           .get();

//       if (doc.exists) {
//         setState(() {
//           _userRole = doc.data()?['role'];
//           _userName = doc.data()?['name'];
//           _profileImage = doc.data()?['profileImage'];
//         });
//       } else {
//         doc = await FirebaseFirestore.instance
//             .collection('tutors')
//             .doc(user.uid)
//             .get();

//         if (doc.exists) {
//           setState(() {
//             _userRole = 'tutor';
//             _userName = doc.data()?['name'];
//             _profileImage = doc.data()?['profileImage'];
//           });
//         }
//       }
//     }
//   }

//   Future<void> _loadRecommendations() async {
//     final user = firebase_auth.FirebaseAuth.instance.currentUser;
//     if (user == null) {
//       debugPrint('🔥 _loadRecommendations: no current user');
//       return;
//     }

//     if (!mounted) return;

//     setState(() {
//       _isLoadingRecommendations = true;
//       _recommendationsError = null;
//     });
//     if (kIsWeb) {
//       debugPrint(
//           'Fetching recommendations on web now that we only use server-side gets.');
//     }

//     try {
//       debugPrint('🔍 Loading recommendations for uid=${user.uid}');

//       final userDoc = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(user.uid)
//           .get(const GetOptions(source: Source.server));

//       final role = (userDoc.data()?['role'] as String?) ?? 'student';
//       if (_userRole == null) {
//         setState(() {
//           _userRole = role;
//         });
//       }

//       final String recCollection =
//           role == 'tutor' ? 'tutor_recommendations' : 'recommendations';

//       debugPrint('📚 Using rec collection: $recCollection for role=$role');

//       final doc = await FirebaseFirestore.instance
//           .collection(recCollection)
//           .doc(user.uid)
//           .get(const GetOptions(source: Source.server));

//       debugPrint('📄 $recCollection/${user.uid} exists: ${doc.exists}');
//       debugPrint('📄 raw data: ${doc.data()}');

//       if (!doc.exists || doc.data() == null) {
//         if (!mounted) return;
//         setState(() {
//           _recommendedTutors = [];
//           _recommendationsError = null;
//         });
//         return;
//       }

//       final data = doc.data()!;
//       final rawItemsDynamic = data['items'];

//       if (rawItemsDynamic == null) {
//         debugPrint('⚠️ "items" field missing in $recCollection doc.');
//         if (!mounted) return;
//         setState(() {
//           _recommendedTutors = [];
//           _recommendationsError = null;
//         });
//         return;
//       }

//       if (rawItemsDynamic is! List) {
//         debugPrint(
//             '❌ "items" is not a List. Got: ${rawItemsDynamic.runtimeType}');
//         if (!mounted) return;
//         setState(() {
//           _recommendedTutors = [];
//           _recommendationsError =
//               'Invalid recommendations format (items is not a list)';
//         });
//         return;
//       }

//       final rawItems = rawItemsDynamic.cast<dynamic>();
//       debugPrint('✅ items length = ${rawItems.length}');

//       final items = <Map<String, dynamic>>[];
//       for (final item in rawItems) {
//         if (item is Map) {
//           items.add(Map<String, dynamic>.from(item as Map));
//         } else {
//           debugPrint('⚠️ Skipping non-map recommendation item: $item');
//         }
//       }

//       debugPrint('✅ Parsed ${items.length} recommendation maps');

//       if (!mounted) return;
//       setState(() {
//         _recommendedTutors = items;
//         _recommendationsError = null;
//       });
//     } catch (e, st) {
//       debugPrint('❌ Error loading recommendations: $e');
//       debugPrint('STACK:\n$st');

//       if (!mounted) return;
//       setState(() {
//         _recommendedTutors = [];
//         _recommendationsError = e.toString();
//       });
//     } finally {
//       if (!mounted) return;
//       setState(() => _isLoadingRecommendations = false);
//     }
//   }

//   String _getWelcomeMessage() {
//     switch (_userRole) {
//       case 'tutor':
//         return 'Find learners that match your expertise';
//       case 'parent':
//         return 'Find the perfect tutor for your child';
//       case 'student':
//       default:
//         return 'Find the perfect tutor for your needs';
//     }
//   }

//   String _getMainTitle() {
//     switch (_userRole) {
//       case 'tutor':
//         return 'Find Learners';
//       case 'parent':
//       case 'student':
//       default:
//         return 'Find Tutors';
//     }
//   }

//   String _getSearchHintText() {
//     switch (_userRole) {
//       case 'tutor':
//         return 'Search students by name...';
//       case 'parent':
//       case 'student':
//       default:
//         return 'Search for tutors by name...';
//     }
//   }

//   String _getSearchTargetRole() {
//     switch (_userRole) {
//       case 'tutor':
//         return 'student';
//       case 'parent':
//         return 'tutor';
//       case 'student':
//       default:
//         return 'tutor';
//     }
//   }

//   String _getSearchTargetCollection() {
//     switch (_userRole) {
//       case 'tutor':
//         return 'users';
//       case 'parent':
//       case 'student':
//       default:
//         return 'users';
//     }
//   }

//   String _getAIRecommendationTitle() {
//     switch (_userRole) {
//       case 'tutor':
//         return 'Recommended For You';
//       case 'parent':
//       case 'student':
//       default:
//         return 'Recommended For You';
//     }
//   }

//   String _getTopRatedTitle() {
//     switch (_userRole) {
//       case 'tutor':
//         return 'Your Students';
//       case 'parent':
//       case 'student':
//       default:
//         return 'Top Rated Tutors';
//     }
//   }

//   // NEW: Header section matching HTML design
//   Widget _buildHeader() {
//     final theme = Theme.of(context);
//     return Container(
//       padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
//       decoration: BoxDecoration(
//         color: theme.colorScheme.background,
//       ),
//       child: Row(
//         children: [
//           // Profile picture and greeting
//           Expanded(
//             child: Row(
//               children: [
//                 Container(
//                   width: 40,
//                   height: 40,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: Colors.grey.shade300,
//                     image: _profileImage != null
//                         ? DecorationImage(
//                             image: NetworkImage(_profileImage!),
//                             fit: BoxFit.cover,
//                           )
//                         : null,
//                   ),
//                   child: _profileImage == null
//                       ? Icon(
//                           Icons.person,
//                           color: Colors.grey.shade600,
//                           size: 20,
//                         )
//                       : null,
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Hello, ${_userName ?? 'there'}!',
//                         style: TextStyle(
//                           fontSize: 20,
//                           fontWeight: FontWeight.w700,
//                           color: theme.colorScheme.onBackground,
//                         ),
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                       Text(
//                         _getWelcomeMessage(),
//                         style: TextStyle(
//                           fontSize: 14,
//                           color:
//                               theme.colorScheme.onBackground.withOpacity(0.7),
//                         ),
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           // Theme toggle button
//           IconButton(
//             onPressed: () {
//               setState(() => _isDarkMode = !_isDarkMode);
//             },
//             icon: Icon(
//               _isDarkMode ? Icons.light_mode : Icons.dark_mode,
//               color: theme.colorScheme.onBackground,
//               size: 28,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // NEW: Search bar matching HTML design
//   Widget _buildSearchBar() {
//     final theme = Theme.of(context);
//     final iconColor = theme.colorScheme.onSurfaceVariant;
//     final shadowColor =
//         theme.brightness == Brightness.dark ? Colors.black45 : Colors.black12;
//     return Container(
//       padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
//       child: Container(
//         height: 48,
//         decoration: BoxDecoration(
//           color: theme.colorScheme.surface,
//           borderRadius: BorderRadius.circular(12),
//           boxShadow: [
//             BoxShadow(
//               color: shadowColor,
//               blurRadius: 10,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child: TextField(
//           onChanged: (value) {
//             if (_debounce?.isActive ?? false) _debounce!.cancel();
//             _debounce = Timer(
//               const Duration(milliseconds: 500),
//               () {
//                 setState(() {
//                   _searchQuery = value;
//                 });
//               },
//             );
//           },
//           cursorColor: theme.colorScheme.primary,
//           decoration: InputDecoration(
//             hintText: _getSearchHintText(),
//             hintStyle: TextStyle(
//               color: iconColor,
//               fontSize: 16,
//             ),
//             border: InputBorder.none,
//             prefixIcon: Padding(
//               padding: const EdgeInsets.only(left: 16, right: 12),
//               child: Icon(
//                 Icons.search,
//                 color: iconColor,
//                 size: 24,
//               ),
//             ),
//             contentPadding: const EdgeInsets.symmetric(vertical: 12),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildHomeTab() {
//     final theme = Theme.of(context);
//     final textColor = theme.colorScheme.onBackground;
//     final secondaryText = theme.colorScheme.onBackground.withOpacity(0.7);
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Container(
//           padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
//           decoration: BoxDecoration(
//             color: theme.colorScheme.background,
//           ),
//           child: Row(
//             children: [
//               Container(
//                 width: 48,
//                 height: 48,
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(16),
//                   color: theme.brightness == Brightness.light
//                       ? Colors.grey.shade200
//                       : Colors.grey.shade700,
//                 ),
//                 child: Icon(
//                   Icons.person,
//                   color: theme.brightness == Brightness.light
//                       ? Colors.grey.shade500
//                       : Colors.grey.shade300,
//                   size: 28,
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Text(
//                   'Hi, ${_userName ?? 'there'}!',
//                   style: TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.w700,
//                     color: textColor,
//                   ),
//                 ),
//               ),
//               IconButton(
//                 padding: EdgeInsets.zero,
//                 onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
//                 icon: Icon(
//                   _isDarkMode ? Icons.light_mode : Icons.dark_mode,
//                   color: textColor,
//                   size: 28,
//                 ),
//               ),
//             ],
//           ),
//         ),
//         _buildSearchBar(),
//         if (_searchQuery.isNotEmpty) ...[
//           Padding(
//             padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
//             child: Text(
//               'Search Results for "$_searchQuery"',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w600,
//                 color: textColor,
//               ),
//             ),
//           ),
//           _buildSearchResults(),
//         ],
//         Padding(
//           padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 'Recommended For You',
//                 style: TextStyle(
//                   fontSize: 22,
//                   fontWeight: FontWeight.w700,
//                   color: textColor,
//                 ),
//               ),
//               TextButton(
//                 onPressed: () {},
//                 child: Text(
//                   'See All',
//                   style: TextStyle(
//                     color: theme.colorScheme.primary,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(height: 4),
//         SizedBox(
//           height: 260,
//           child: ListView(
//             scrollDirection: Axis.horizontal,
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             children: [
//               const SizedBox(width: 4),
//               ..._buildRecommendationCards(style: RecommendationCardStyle.large),
//               const SizedBox(width: 4),
//             ],
//           ),
//         ),
//         Padding(
//           padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 'Top Rated Tutors',
//                 style: TextStyle(
//                   fontSize: 22,
//                   fontWeight: FontWeight.w700,
//                   color: textColor,
//                 ),
//               ),
//               TextButton(
//                 onPressed: () {},
//                 child: Text(
//                   'See All',
//                   style: TextStyle(
//                     color: theme.colorScheme.primary,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(height: 8),
//         Expanded(child: _buildTopRatedList()),
//       ],
//     );
//   }

//   Widget _buildRecommendedStudentCard(Map<String, dynamic> rec) {
//     final name = (rec['name'] ?? 'Student').toString();
//     final learnerId = (rec['learnerId'] ?? rec['studentId'] ?? '').toString();
//     final city = (rec['city'] ?? 'Location not set').toString();
//     final gradeLevels =
//         (rec['gradeLevels'] as List<dynamic>? ?? []).cast<String>();
//     final gradeText = gradeLevels.isEmpty
//         ? 'Student'
//         : 'Grade ${gradeLevels.take(2).join(', ')}';
//     final age = rec['age'];
//     final gender = rec['sex']?.toString();
//     final subjects = (rec['subjects'] as List<dynamic>? ?? []).cast<String>();
//     final reasons = (rec['reasons'] as List<dynamic>? ?? []).cast<String>();
//     final score = (rec['score'] as num?)?.toDouble() ?? 0.0;
//     final matchPercent = (score.clamp(0.0, 1.0) * 100).round();
//     final highlight =
//         reasons.isNotEmpty ? reasons.first : 'Matches your expertise';
//     final subjectsText = subjects.isEmpty
//         ? 'Interests not provided'
//         : 'Interests: ${subjects.take(3).join(', ')}';

//     return Container(
//       width: 260,
//       margin: const EdgeInsets.only(right: 16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Profile row
//             Row(
//               children: [
//                 Container(
//                   width: 56,
//                   height: 56,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: Colors.blue.shade100,
//                     image: rec['profileImage'] != null
//                         ? DecorationImage(
//                             image: NetworkImage(rec['profileImage']!),
//                             fit: BoxFit.cover,
//                           )
//                         : null,
//                   ),
//                   child: rec['profileImage'] == null
//                       ? Center(
//                           child: Text(
//                             name.substring(0, 1),
//                             style: const TextStyle(
//                               color: Color(0xFF2B8CEE),
//                               fontWeight: FontWeight.bold,
//                               fontSize: 18,
//                             ),
//                           ),
//                         )
//                       : null,
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         name,
//                         style: const TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w700,
//                           color: Color(0xFF111418),
//                         ),
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                       Text(
//                         gradeText,
//                         style: const TextStyle(
//                           fontSize: 14,
//                           color: Color(0xFF617589),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),

//             // Highlight tag
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//               decoration: BoxDecoration(
//                 color: const Color(0x332B8CEE),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Text(
//                 highlight,
//                 style: const TextStyle(
//                   fontSize: 14,
//                   color: Color(0xFF617589),
//                   fontWeight: FontWeight.w500,
//                 ),
//                 maxLines: 2,
//                 overflow: TextOverflow.ellipsis,
//               ),
//             ),
//             const SizedBox(height: 12),

//             // Subjects
//             Text(
//               subjectsText,
//               style: const TextStyle(
//                 fontSize: 14,
//                 color: Color(0xFF617589),
//               ),
//               maxLines: 2,
//               overflow: TextOverflow.ellipsis,
//             ),
//             const Spacer(),

//             // Buttons
//             Row(
//               children: [
//                 Expanded(
//                   child: OutlinedButton(
//                     onPressed: () {
//                       _viewProfile(
//                         name,
//                         isStudent: true,
//                         userId: learnerId.isEmpty ? null : learnerId,
//                       );
//                     },
//                     style: OutlinedButton.styleFrom(
//                       foregroundColor: const Color(0xFF111418),
//                       side: const BorderSide(color: Color(0xFFD1D1D1)),
//                       backgroundColor: const Color(0xFFF6F7F8),
//                       minimumSize: const Size(0, 40),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     child: const Text(
//                       'View Profile',
//                       style: TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: ElevatedButton(
//                     onPressed: learnerId.isEmpty
//                         ? null
//                         : () {
//                             _startChat(
//                               name,
//                               learnerId,
//                               isStudent: true,
//                             );
//                           },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color(0xFF2B8CEE),
//                       foregroundColor: Colors.white,
//                       minimumSize: const Size(0, 40),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     child: const Text(
//                       'Message',
//                       style: TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildRecommendedTutorCard(Map<String, dynamic> rec) {
//     final name = (rec['name'] ?? 'Tutor').toString();
//     final tutorId = (rec['tutorId'] ?? '').toString();
//     final city = (rec['city'] ?? 'Location not set').toString();
//     final subjects = (rec['subjects'] as List<dynamic>? ?? []).cast<String>();
//     final gradeLevels =
//         (rec['gradeLevels'] as List<dynamic>? ?? []).cast<String>();
//     final qualification = rec['qualification']?.toString();
//     final gender = rec['sex']?.toString();
//     final age = rec['age'];
//     final available = rec['available'] == true;
//     final verified = rec['verified'] == true;
//     final profileImage = rec['profileImage']?.toString();
//     final reasons = (rec['reasons'] as List<dynamic>? ?? []).cast<String>();
//     final score = (rec['score'] as num?)?.toDouble() ?? 0.0;
//     final minPrice = rec['minPricePerHour'] as num?;
//     final matchPercent = (score.clamp(0.0, 1.0) * 100).round();
//     final highlight =
//         reasons.isNotEmpty ? reasons.first : 'Matches your learning goals';
//     final subjectsText = subjects.isEmpty
//         ? 'Subjects not provided'
//         : 'Subjects: ${subjects.take(3).join(', ')}';
//     final priceText = minPrice == null
//         ? 'Rate unavailable'
//         : 'From ETB ${minPrice.round()} / hr';

//     return Container(
//       width: 260,
//       margin: const EdgeInsets.only(right: 16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Profile row
//             Row(
//               children: [
//                 Stack(
//                   children: [
//                     Container(
//                       width: 56,
//                       height: 56,
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         color: Colors.blue.shade100,
//                         image: profileImage != null
//                             ? DecorationImage(
//                                 image: NetworkImage(profileImage),
//                                 fit: BoxFit.cover,
//                               )
//                             : null,
//                       ),
//                       child: profileImage == null
//                           ? Center(
//                               child: Text(
//                                 name.substring(0, 1),
//                                 style: const TextStyle(
//                                   color: Color(0xFF2B8CEE),
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: 18,
//                                 ),
//                               ),
//                             )
//                           : null,
//                     ),
//                     if (verified)
//                       Positioned(
//                         right: 0,
//                         bottom: 0,
//                         child: Container(
//                           padding: const EdgeInsets.all(2),
//                           decoration: BoxDecoration(
//                             color: Colors.white,
//                             shape: BoxShape.circle,
//                           ),
//                           child: Icon(
//                             Icons.verified,
//                             color: Colors.blue.shade700,
//                             size: 16,
//                           ),
//                         ),
//                       ),
//                   ],
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         name,
//                         style: const TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w700,
//                           color: Color(0xFF111418),
//                         ),
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                       Text(
//                         '${age is num ? 'Age ${age.toInt()}' : 'Tutor'} • $city',
//                         style: const TextStyle(
//                           fontSize: 14,
//                           color: Color(0xFF617589),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),

//             // Highlight tag
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//               decoration: BoxDecoration(
//                 color: const Color(0x332B8CEE),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Text(
//                 highlight,
//                 style: const TextStyle(
//                   fontSize: 14,
//                   color: Color(0xFF617589),
//                   fontWeight: FontWeight.w500,
//                 ),
//                 maxLines: 2,
//                 overflow: TextOverflow.ellipsis,
//               ),
//             ),
//             const SizedBox(height: 12),

//             // Subjects and price
//             Text(
//               subjectsText,
//               style: const TextStyle(
//                 fontSize: 14,
//                 color: Color(0xFF617589),
//               ),
//               maxLines: 2,
//               overflow: TextOverflow.ellipsis,
//             ),
//             const SizedBox(height: 8),
//             Text(
//               priceText,
//               style: const TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w600,
//                 color: Color(0xFF111418),
//               ),
//             ),
//             const Spacer(),

//             // Buttons
//             Row(
//               children: [
//                 Expanded(
//                   child: OutlinedButton(
//                     onPressed: () {
//                       _viewProfile(
//                         name,
//                         isStudent: false,
//                         userId: tutorId.isEmpty ? null : tutorId,
//                       );
//                     },
//                     style: OutlinedButton.styleFrom(
//                       foregroundColor: const Color(0xFF111418),
//                       side: const BorderSide(color: Color(0xFFD1D1D1)),
//                       backgroundColor: const Color(0xFFF6F7F8),
//                       minimumSize: const Size(0, 40),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     child: const Text(
//                       'View Profile',
//                       style: TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: ElevatedButton(
//                     onPressed: tutorId.isEmpty
//                         ? null
//                         : () {
//                             _startChat(name, tutorId, isStudent: false);
//                           },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color(0xFF2B8CEE),
//                       foregroundColor: Colors.white,
//                       minimumSize: const Size(0, 40),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     child: const Text(
//                       'Message',
//                       style: TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildMinimalRecommendedTutorCard(Map<String, dynamic> rec) {
//     final theme = Theme.of(context);
//     final name = (rec['name'] ?? 'Tutor').toString();
//     final tutorId = (rec['tutorId'] ?? '').toString();
//     final city = (rec['city'] ?? 'Location not set').toString();
//     final profileImage = rec['profileImage']?.toString();
//     final reasons = (rec['reasons'] as List<dynamic>? ?? []).cast<String>();
//     final reasonSummary =
//         reasons.isNotEmpty ? reasons.first : 'Matches your learning goals';

//     final profileData = Map<String, dynamic>.from(rec);
//     profileData.remove('tutorId');

//     final cardColor = theme.cardColor;
//     final shadowColor = theme.brightness == Brightness.dark
//         ? Colors.black.withOpacity(0.3)
//         : Colors.black.withOpacity(0.08);
//     final textColor = theme.colorScheme.onSurface;
//     final mutedColor = theme.colorScheme.onSurfaceVariant;
//     final viewProfileBg = theme.brightness == Brightness.light
//         ? const Color(0xFFF4F6F8)
//         : Colors.white10;
//     final viewProfileTextColor = theme.brightness == Brightness.light
//         ? const Color(0xFF1C2536)
//         : Colors.white;

//     return Container(
//       width: 260,
//       margin: const EdgeInsets.only(right: 16),
//       decoration: BoxDecoration(
//         color: cardColor,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: shadowColor,
//             blurRadius: 12,
//             offset: const Offset(0, 6),
//           ),
//         ],
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 CircleAvatar(
//                   radius: 26,
//                   backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
//                   backgroundImage:
//                       profileImage != null ? NetworkImage(profileImage) : null,
//                   child: profileImage == null
//                       ? Text(
//                           name.substring(0, 1),
//                           style: const TextStyle(
//                             color: Color(0xFF2B8CEE),
//                             fontWeight: FontWeight.bold,
//                             fontSize: 18,
//                           ),
//                         )
//                       : null,
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         name,
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w700,
//                           color: textColor,
//                         ),
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                       const SizedBox(height: 2),
//                       Text(
//                         city,
//                         style: TextStyle(
//                           fontSize: 13,
//                           color: mutedColor,
//                         ),
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             Text(
//               reasonSummary,
//               style: TextStyle(
//                 fontSize: 14,
//                 color: mutedColor,
//               ),
//               maxLines: 2,
//               overflow: TextOverflow.ellipsis,
//             ),
//             const SizedBox(height: 16),
//             Row(
//               children: [
//                 Expanded(
//                   child: OutlinedButton(
//                     onPressed: () {
//                       _viewProfile(
//                         name,
//                         isStudent: false,
//                         userId: tutorId.isEmpty ? null : tutorId,
//                         userData: profileData,
//                       );
//                     },
//                     style: OutlinedButton.styleFrom(
//                       foregroundColor: viewProfileTextColor,
//                       backgroundColor: viewProfileBg,
//                       minimumSize: const Size(0, 40),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     child: const Text(
//                       'View Profile',
//                       style: TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: ElevatedButton(
//                     onPressed: tutorId.isEmpty
//                         ? null
//                         : () => _startChat(name, tutorId, isStudent: false),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: theme.colorScheme.primary,
//                       foregroundColor: Colors.white,
//                       minimumSize: const Size(0, 40),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     child: const Text(
//                       'Message',
//                       style: TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   List<Widget> _buildRecommendationCards({
//     RecommendationCardStyle style = RecommendationCardStyle.large,
//   }) {
//     if (_isLoadingRecommendations) {
//       return [
//         _buildRecommendationStatusCard(
//           child: const CircularProgressIndicator(strokeWidth: 2),
//         ),
//       ];
//     }

//     if (_recommendationsError != null) {
//       return [
//         _buildRecommendationStatusCard(
//           message: 'Unable to load recommendations.\nTap to retry.',
//           onTap: _loadRecommendations,
//         ),
//       ];
//     }

//     if (_recommendedTutors.isEmpty) {
//       return [
//         _buildRecommendationStatusCard(
//           message: _userRole == 'tutor'
//               ? 'No personalized students yet.\nUpdate your profile to get matches.'
//               : 'No personalized tutors yet.\nUpdate your interests to get matches.',
//         ),
//       ];
//     }

//     return _recommendedTutors.map((rec) => _buildRecommendedTutorCard(rec)).toList();
//   }

//   Widget _buildRecommendationStatusCard({
//     String? message,
//     Widget? child,
//     VoidCallback? onTap,
//   }) {
//     final content = child ??
//         Text(
//           message ?? '',
//           textAlign: TextAlign.center,
//           style: const TextStyle(
//             fontSize: 14,
//             color: Color(0xFF617589),
//             fontWeight: FontWeight.w500,
//           ),
//         );

//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         width: 260,
//         margin: const EdgeInsets.only(right: 16),
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(16),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.05),
//               blurRadius: 10,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child: Center(child: content),
//       ),
//     );
//   }

//   Widget _buildRecommendedTutorCard(Map<String, dynamic> rec) {
//     final theme = Theme.of(context);
//     final name = (rec['name'] ?? 'Tutor').toString();
//     final tutorId = (rec['tutorId'] ?? '').toString();
//     final city = (rec['city'] ?? 'Location not set').toString();
//     final profileImage = rec['profileImage']?.toString();
//     final reasons = (rec['reasons'] as List<dynamic>? ?? []).cast<String>();
//     final reason = reasons.isNotEmpty ? reasons.first : 'Matches your learning goals';
//     final score = (rec['score'] as num?)?.toDouble() ?? 0.75;
//     final matchPercent = (score.clamp(0.0, 1.0) * 100).round();

//     final viewProfileBg = theme.colorScheme.background == AppTheme.backgroundLight
//         ? const Color(0xFFF4F7FB)
//         : Colors.white10;

//     return Container(
//       width: 300,
//       margin: const EdgeInsets.only(right: 12, bottom: 12),
//       decoration: BoxDecoration(
//         color: theme.cardColor,
//         borderRadius: BorderRadius.circular(18),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 12,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: Row(
//               children: [
//                 CircleAvatar(
//                   radius: 30,
//                   backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
//                   backgroundImage:
//                       profileImage != null ? NetworkImage(profileImage) : null,
//                   child: profileImage == null
//                       ? Text(
//                           name.substring(0, 1),
//                           style: const TextStyle(
//                             color: Color(0xFF2B8CEE),
//                             fontWeight: FontWeight.bold,
//                             fontSize: 22,
//                           ),
//                         )
//                       : null,
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         name,
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.w700,
//                           color: theme.colorScheme.onSurface,
//                         ),
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                       const SizedBox(height: 2),
//                       Text(
//                         city,
//                         style: TextStyle(
//                           fontSize: 13,
//                           color: theme.colorScheme.onSurfaceVariant,
//                         ),
//                       ),
//                       const SizedBox(height: 6),
//                       Row(
//                         children: [
//                           Expanded(
//                             child: ClipRRect(
//                               borderRadius: BorderRadius.circular(100),
//                               child: LinearProgressIndicator(
//                                 value: matchPercent / 100,
//                                 minHeight: 8,
//                                 backgroundColor: Colors.grey.shade200,
//                                 color: const Color(0xFFf6ac17),
//                               ),
//                             ),
//                           ),
//                           const SizedBox(width: 6),
//                           Text(
//                             '$matchPercent% Match',
//                             style: TextStyle(
//                               color: const Color(0xFFf6ac17),
//                               fontSize: 12,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             child: Text(
//               reason,
//               style: TextStyle(
//                 fontSize: 13,
//                 color: theme.colorScheme.onSurfaceVariant,
//               ),
//               maxLines: 2,
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//           const SizedBox(height: 12),
//           Padding(
//             padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: OutlinedButton(
//                     onPressed: () {
//                       _startChat(name, tutorId, isStudent: false);
//                     },
//                     style: OutlinedButton.styleFrom(
//                       backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
//                       foregroundColor: theme.colorScheme.primary,
//                       elevation: 0,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     child: const Text(
//                       'Message',
//                       style: TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: ElevatedButton(
//                     onPressed: () {
//                       _viewProfile(
//                         name,
//                         isStudent: false,
//                         userId: tutorId.isEmpty ? null : tutorId,
//                       );
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: theme.colorScheme.primary,
//                       foregroundColor: Colors.white,
//                       elevation: 0,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     child: const Text(
//                       'View Profile',
//                       style: TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ========== EXISTING METHODS (KEEPING YOUR ORIGINAL FUNCTIONALITY) ==========

//   Widget _buildSearchResults() {
//     Stream<QuerySnapshot> searchStream() async* {
//       if (_searchQuery.isEmpty) {
//         return;
//       }
//       try {
//         final targetRole = _getSearchTargetRole();
//         final collection = _getSearchTargetCollection();

//         final snapshot = await FirebaseFirestore.instance
//             .collection(collection)
//             .where('role', isEqualTo: targetRole)
//             .where('name', isGreaterThanOrEqualTo: _searchQuery)
//             .where('name', isLessThanOrEqualTo: _searchQuery + '\uf8ff')
//             .limit(20)
//             .get();

//         yield snapshot;
//       } catch (e) {
//         debugPrint('🔴 Stream Error: $e');
//         yield* Stream<QuerySnapshot>.empty();
//       }
//     }

//     return StreamBuilder<QuerySnapshot>(
//       stream: searchStream(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(
//             child: Column(
//               children: [
//                 CircularProgressIndicator(),
//                 SizedBox(height: 16),
//                 Text('Searching...', style: TextStyle(color: Colors.grey)),
//               ],
//             ),
//           );
//         }

//         if (snapshot.hasError) {
//           final error = snapshot.error.toString();
//           debugPrint('🔴 Search Error: $error');

//           if (error.contains('index') ||
//               error.contains('FAILED_PRECONDITION')) {
//             debugPrint('🔧 INDEX REQUIRED: $error');
//             return _buildIndexRequiredMessage();
//           }

//           return Center(
//             child: Column(
//               children: [
//                 Icon(Icons.error_outline, color: Colors.red, size: 48),
//                 const SizedBox(height: 16),
//                 Text(
//                   'Search Error',
//                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   'Please check your connection or try again',
//                   style: TextStyle(color: Colors.grey),
//                 ),
//                 const SizedBox(height: 16),
//                 ElevatedButton(
//                   onPressed: () => setState(() {}),
//                   child: const Text('Retry Search'),
//                 ),
//               ],
//             ),
//           );
//         }

//         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//           debugPrint('✅ No results found for "$_searchQuery"');
//           return const Center(
//             child: Column(
//               children: [
//                 Icon(Icons.search_off, size: 48, color: Colors.grey),
//                 SizedBox(height: 16),
//                 Text('No results found', style: TextStyle(fontSize: 16)),
//                 SizedBox(height: 8),
//                 Text(
//                   'Try searching with a different name',
//                   style: TextStyle(color: Colors.grey),
//                 ),
//               ],
//             ),
//           );
//         }

//         final results = snapshot.data!.docs;
//         debugPrint(
//             '✅ SERVER-SIDE SEARCH: Found ${results.length} results for "$_searchQuery"');

//         return Column(
//           children: [
//             Container(
//               padding: const EdgeInsets.all(12),
//               margin: const EdgeInsets.only(bottom: 16),
//               decoration: BoxDecoration(
//                 color: Colors.green.shade50,
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(color: Colors.green.shade200),
//               ),
//               child: Row(
//                 children: [
//                   Icon(Icons.bolt, color: Colors.green.shade700, size: 20),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'Fast Search Enabled',
//                           style: TextStyle(
//                             fontSize: 14,
//                             color: Colors.green.shade800,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                         Text(
//                           'Results from ${results.length} ${_userRole == 'tutor' ? 'students' : 'tutors'}',
//                           style: TextStyle(
//                             fontSize: 12,
//                             color: Colors.green.shade600,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             ...results.map((doc) => _buildSearchResultCard(doc)).toList(),
//           ],
//         );
//       },
//     );
//   }

//   Widget _buildIndexRequiredMessage() {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.build, size: 64, color: Colors.orange.shade600),
//             const SizedBox(height: 24),
//             Text(
//               'Search Optimization Required',
//               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 16),
//             Text(
//               'To enable fast search for 1000+ users, we need to create a search index.',
//               style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 24),
//             Card(
//               elevation: 2,
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   children: [
//                     Text(
//                       'Quick Fix:',
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     Text(
//                       '1. Check your console for a Firebase index link\n2. Click the link to create the index\n3. Wait 2-5 minutes for it to build\n4. Search will become instant!',
//                       style: TextStyle(fontSize: 14),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 24),
//             ElevatedButton.icon(
//               onPressed: () {
//                 setState(() {});
//               },
//               icon: Icon(Icons.search),
//               label: Text('Use Basic Search For Now'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.orange.shade600,
//                 foregroundColor: Colors.white,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSearchResultCard(DocumentSnapshot doc) {
//     final userData = doc.data() as Map<String, dynamic>;
//     final userId = doc.id;
//     final name = userData['name'] ?? 'Unknown';
//     final sex = userData['sex'] ?? '';
//     final age = userData['age'];
//     final city = userData['city'] ?? '';
//     final subjects =
//         (userData['subjects'] as List<dynamic>? ?? []).cast<String>();
//     final gradeLevels =
//         (userData['gradeLevels'] as List<dynamic>? ?? []).cast<String>();
//     final qualification = userData['qualification']?.toString();
//     final available = userData['available'] == true;
//     final profileImage = userData['profileImage'];
//     final isVerified = userData['verified'] ?? false;

//     final isStudent = _userRole == 'tutor';
//     final displayInfo = isStudent
//         ? userData['grade'] ?? 'Student'
//         : 'Birr${userData['minPricePerHour'] ?? 0}/hr';

//     return Container(
//       margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: ListTile(
//         leading: CircleAvatar(
//           backgroundColor: Colors.blue.shade100,
//           backgroundImage:
//               profileImage != null ? NetworkImage(profileImage) : null,
//           child: profileImage == null
//               ? Text(
//                   name.substring(0, 1),
//                   style: TextStyle(
//                     color: Colors.blue,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 )
//               : null,
//         ),
//         title: Row(
//           children: [
//             Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
//             if (isVerified && !isStudent) ...[
//               const SizedBox(width: 4),
//               Icon(Icons.verified, color: Colors.blue.shade700, size: 16),
//             ],
//             if (!isStudent) ...[
//               const SizedBox(width: 8),
//               RatingBadge(tutorId: userId),
//             ],
//           ],
//         ),
//         subtitle: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               [
//                 if (age is num) 'Age ${age.toInt()}',
//                 if (sex != '') sex,
//                 if (!isStudent && city.isNotEmpty) city,
//               ].join(' • '),
//             ),
//             if (!isStudent && subjects.isNotEmpty)
//               Text('Subjects: ${subjects.take(3).join(', ')}'),
//             if (!isStudent && gradeLevels.isNotEmpty)
//               Text('Grades: ${gradeLevels.take(3).join(', ')}'),
//             if (!isStudent && qualification != null && qualification.isNotEmpty)
//               Text('Qualification: $qualification'),
//             if (!isStudent)
//               Text(
//                 '${available ? 'Available' : 'Unavailable'} • $displayInfo',
//                 style: TextStyle(
//                   color:
//                       available ? Colors.green.shade700 : Colors.red.shade400,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             if (isStudent) Text('$sex • $displayInfo'),
//           ],
//         ),
//         trailing: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             IconButton(
//               icon: Icon(
//                 Icons.chat,
//                 color: Colors.green.shade600,
//               ),
//               onPressed: () {
//                 _startChat(name, userId, isStudent: isStudent);
//               },
//             ),
//             IconButton(
//               icon: Icon(
//                 Icons.visibility,
//                 color: Colors.blue.shade700,
//               ),
//               onPressed: () {
//                 _viewProfile(
//                   name,
//                   isStudent: isStudent,
//                   userId: userId,
//                   userData: userData,
//                 );
//               },
//             ),
//           ],
//         ),
//         onTap: () {
//           if (!isStudent) {
//             InteractionLogger.log(
//               event: 'search_card_click',
//               tutorId: userId,
//               data: {'query': _searchQuery},
//             );
//           }
//           _viewProfile(
//             name,
//             isStudent: isStudent,
//             userId: userId,
//             userData: userData,
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildTopRatedList() {
//     final targetRole = _userRole == 'tutor' ? 'student' : 'tutor';

//     final query = FirebaseFirestore.instance
//         .collection('users')
//         .where('role', isEqualTo: targetRole)
//         .limit(3);

//     return StreamBuilder<QuerySnapshot>(
//       stream: query.snapshots(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         }

//         if (snapshot.hasError) {
//           return Center(child: Text('Error: ${snapshot.error}'));
//         }

//         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//           return Center(
//             child: Text(
//               _userRole == 'tutor'
//                   ? 'No students available.'
//                   : 'No tutors available.',
//             ),
//           );
//         }

//         final users = snapshot.data!.docs;
//         return Column(
//           children: users
//               .map((doc) => _buildTopRatedCard(
//                     doc.id,
//                     doc.data() as Map<String, dynamic>,
//                   ))
//               .toList(),
//         );
//       },
//     );
//   }

//   Widget _buildTopRatedCard(String userId, Map<String, dynamic> user) {
//     final theme = Theme.of(context);
//     final name = user['name'] ?? 'Unknown';
//     final profileImage = user['profileImage'];
//     final rating = (user['rating'] as num?)?.toDouble() ?? 4.8;
//     final ratingText = rating.toStringAsFixed(1);

//     return Container(
//       margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: theme.cardColor,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.04),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           CircleAvatar(
//             radius: 30,
//             backgroundColor: Colors.grey.shade200,
//             backgroundImage:
//                 profileImage != null ? NetworkImage(profileImage) : null,
//             child: profileImage == null
//                 ? Text(
//                     name.substring(0, 1),
//                     style: TextStyle(
//                       color: theme.colorScheme.primary,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 22,
//                     ),
//                   )
//                 : null,
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   name,
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w700,
//                     color: theme.colorScheme.onSurface,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Row(
//                   children: [
//                     Icon(
//                       Icons.star,
//                       size: 18,
//                       color: const Color(0xFFF6AC17),
//                     ),
//                     const SizedBox(width: 4),
//                     Text(
//                       ratingText,
//                       style: TextStyle(
//                         fontSize: 12,
//                         fontWeight: FontWeight.w600,
//                         color: theme.colorScheme.onSurfaceVariant,
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//           ElevatedButton(
//             onPressed: () => _viewProfile(name, userId: userId, userData: user),
//             style: ElevatedButton.styleFrom(
//               padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
//               backgroundColor: theme.colorScheme.primary,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//             ),
//             child: const Text(
//               'View Profile',
//               style: TextStyle(
//                 fontSize: 12,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildUserListItem(
//     String name,
//     String sex,
//     String displayInfo,
//     String userId,
//     String? profileImage,
//     bool isVerified, {
//     bool isStudent = false,
//   }) {
//     return Container(
//       margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: ListTile(
//         leading: CircleAvatar(
//           backgroundColor: Colors.blue.shade100,
//           backgroundImage:
//               profileImage != null ? NetworkImage(profileImage) : null,
//           child: profileImage == null
//               ? Text(
//                   name.substring(0, 1),
//                   style: TextStyle(
//                     color: Colors.blue,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 )
//               : null,
//         ),
//         title: Row(
//           children: [
//             Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
//             if (isVerified && !isStudent) ...[
//               const SizedBox(width: 4),
//               Icon(Icons.verified, color: Colors.blue.shade700, size: 16),
//             ],
//           ],
//         ),
//         subtitle: Text('$sex • $displayInfo'),
//         trailing: IconButton(
//           icon: Icon(
//             Icons.chat,
//             color: Colors.green.shade600,
//             size: 20,
//           ),
//           onPressed: () {
//             _startChat(name, userId, isStudent: isStudent);
//           },
//         ),
//         onTap: () {
//           FirebaseFirestore.instance.collection('users').doc(userId).get().then(
//             (doc) {
//               if (doc.exists) {
//                 _viewProfile(
//                   name,
//                   isStudent: isStudent,
//                   userId: userId,
//                   userData: doc.data() as Map<String, dynamic>,
//                 );
//               }
//             },
//           );
//         },
//       ),
//     );
//   }

//   void _viewProfile(
//     String name, {
//     bool isStudent = false,
//     String? userId,
//     Map<String, dynamic>? userData,
//   }) {
//     if (!isStudent && userId != null) {
//       InteractionLogger.log(
//         event: 'view_tutor_profile',
//         tutorId: userId,
//         data: {'source': 'home_profile'},
//       );
//     }
//     final bool isTutorViewingStudent = _userRole == 'tutor' && isStudent;

//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Text('$name Profile'),
//                 if (userData?['verified'] == true && !isStudent) ...[
//                   const SizedBox(width: 8),
//                   Icon(Icons.verified, color: Colors.blue.shade700, size: 20),
//                 ],
//               ],
//             ),
//             if (!isStudent && userId != null) ...[
//               const SizedBox(height: 4),
//               RatingBadge(tutorId: userId!),
//             ],
//           ],
//         ),
//         content: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Center(
//                 child: CircleAvatar(
//                   radius: 40,
//                   backgroundColor: Colors.blue.shade100,
//                   backgroundImage: userData?['profileImage'] != null
//                       ? NetworkImage(userData!['profileImage'])
//                       : null,
//                   child: userData?['profileImage'] == null
//                       ? Text(
//                           name.substring(0, 1),
//                           style: TextStyle(
//                             fontSize: 24,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.blue,
//                           ),
//                         )
//                       : null,
//                 ),
//               ),
//               const SizedBox(height: 16),
//               Text(
//                 'Name: $name',
//                 style: const TextStyle(fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 8),
//               if (userData != null) ...[
//                 if (userData['age'] != null)
//                   Text('Age: ${userData['age']} years'),
//                 if (userData['age'] != null) const SizedBox(height: 8),
//                 if (userData['sex'] != null) Text('Gender: ${userData['sex']}'),
//                 if (userData['sex'] != null) const SizedBox(height: 8),
//                 if (userData['city'] != null) Text('City: ${userData['city']}'),
//                 if (userData['city'] != null) const SizedBox(height: 8),
//                 if (isStudent) ...[
//                   if (userData['grade'] != null)
//                     Text('Grade: ${userData['grade']}'),
//                   if (userData['grade'] != null) const SizedBox(height: 8),
//                   if (userData['subjects'] != null &&
//                       (userData['subjects'] as List).isNotEmpty)
//                     Text(
//                       'Interested in: ${(userData['subjects'] as List).join(', ')}',
//                     ),
//                   if (userData['subjects'] != null &&
//                       (userData['subjects'] as List).isNotEmpty)
//                     const SizedBox(height: 8),
//                   if (userData['learningGoals'] != null)
//                     Text('Learning Goals: ${userData['learningGoals']}'),
//                   if (userData['learningGoals'] != null)
//                     const SizedBox(height: 8),
//                 ] else ...[
//                   if (userData['qualification'] != null)
//                     Text('Qualification: ${userData['qualification']}'),
//                   if (userData['qualification'] != null)
//                     const SizedBox(height: 8),
//                   if (userData['subjects'] != null &&
//                       (userData['subjects'] as List).isNotEmpty)
//                     Text(
//                       'Subjects: ${(userData['subjects'] as List).join(', ')}',
//                     ),
//                   if (userData['subjects'] != null &&
//                       (userData['subjects'] as List).isNotEmpty)
//                     const SizedBox(height: 8),
//                   if (userData['gradeLevels'] != null &&
//                       (userData['gradeLevels'] as List).isNotEmpty)
//                     Text(
//                       'Grade Levels: ${(userData['gradeLevels'] as List).join(', ')}',
//                     ),
//                   if (userData['gradeLevels'] != null &&
//                       (userData['gradeLevels'] as List).isNotEmpty)
//                     const SizedBox(height: 8),
//                   if (userData['minPricePerHour'] != null)
//                     Text('Price: Birr${userData['minPricePerHour']}/hr'),
//                   if (userData['minPricePerHour'] != null)
//                     const SizedBox(height: 8),
//                   if (userData['hoursPerDay'] != null)
//                     Text('Hours per day: ${userData['hoursPerDay']}'),
//                   if (userData['hoursPerDay'] != null)
//                     const SizedBox(height: 8),
//                   if (userData['daysPerWeek'] != null)
//                     Text('Days per week: ${userData['daysPerWeek']}'),
//                   if (userData['daysPerWeek'] != null)
//                     const SizedBox(height: 8),
//                   if (userData['available'] != null)
//                     Text(
//                       'Available: ${userData['available']! ? 'Yes' : 'No'}',
//                       style: TextStyle(
//                         color:
//                             userData['available']! ? Colors.green : Colors.red,
//                       ),
//                     ),
//                   if (userData['available'] != null) const SizedBox(height: 8),
//                 ],
//               ],
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Close'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.pop(context);
//               _startChat(
//                 name,
//                 userId ?? '${isStudent ? 'student' : 'tutor'}_fake_id_$name',
//                 isStudent: isStudent,
//               );
//             },
//             child: const Text('Message'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _startChat(
//     String personName,
//     String personId, {
//     bool isStudent = false,
//   }) {
//     final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
//     if (currentUser == null) return;

//     final messageProvider = Provider.of<MessageProvider>(
//       context,
//       listen: false,
//     );

//     final initialMessage = _userRole == 'tutor'
//         ? "Hello! I'm interested in tutoring you."
//         : "Hello! I'm interested in your tutoring services.";

//     FirebaseFirestore.instance
//         .collection('users')
//         .doc(currentUser.uid)
//         .get()
//         .then((doc) {
//       final String senderName;
//       if (doc.exists && doc.data()?['name'] != null) {
//         senderName = doc.data()!['name'];
//       } else {
//         senderName = _userName ?? (_userRole == 'tutor' ? 'Tutor' : 'Student');
//       }

//       if (!isStudent) {
//         InteractionLogger.log(
//           event: 'start_chat',
//           tutorId: personId,
//           data: {'source': 'home'},
//         );
//       }

//       messageProvider
//           .sendMessage(
//         senderId: currentUser.uid,
//         senderName: senderName,
//         receiverId: personId,
//         receiverName: personName,
//         content: initialMessage,
//       )
//           .then((_) {
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => ChatScreen(
//               receiverId: personId,
//               receiverName: personName,
//             ),
//           ),
//         );
//       }).catchError((error) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to start chat: $error')),
//         );
//       });
//     }).catchError((error) {});
//   }

//   // ========== EXISTING TAB METHODS ==========

//   Widget _buildMessagesTab() {
//     final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;

//     if (currentUser == null) {
//       return const Center(child: Text('Please login to view messages'));
//     }

//     return StreamBuilder<List<Message>>(
//       stream: Provider.of<MessageProvider>(
//         context,
//       ).getConversations(currentUser.uid),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         }

//         if (snapshot.hasError) {
//           return Center(child: Text('Error: ${snapshot.error}'));
//         }

//         if (!snapshot.hasData || snapshot.data!.isEmpty) {
//           return Padding(
//             padding: const EdgeInsets.all(20),
//             child: Column(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: Colors.blue.shade50,
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   child: Row(
//                     children: [
//                       Icon(
//                         Icons.chat_bubble_outline,
//                         color: Colors.blue.shade700,
//                       ),
//                       const SizedBox(width: 12),
//                       const Expanded(
//                         child: Text(
//                           'Your conversations will appear here',
//                           style: TextStyle(fontSize: 16, color: Colors.black87),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           );
//         }

//         final conversations = snapshot.data!;

//         return ListView.builder(
//           padding: const EdgeInsets.all(16),
//           itemCount: conversations.length,
//           itemBuilder: (context, index) {
//             final conversation = conversations[index];

//             final isCurrentUserSender =
//                 conversation.senderId == currentUser.uid;
//             final otherPersonName = isCurrentUserSender
//                 ? conversation.receiverName
//                 : conversation.senderName;
//             final otherPersonId = isCurrentUserSender
//                 ? conversation.receiverId
//                 : conversation.senderId;

//             final isUnread = conversation.receiverId == currentUser.uid &&
//                 !conversation.isRead;

//             return Card(
//               margin: const EdgeInsets.only(bottom: 12),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: ListTile(
//                 leading: CircleAvatar(
//                   backgroundColor: Colors.blue.shade100,
//                   child: Text(
//                     otherPersonName.substring(0, 1).toUpperCase(),
//                     style: TextStyle(
//                       color: Colors.blue.shade700,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//                 title: Row(
//                   children: [
//                     Expanded(
//                       child: Text(
//                         otherPersonName,
//                         style: TextStyle(
//                           fontWeight:
//                               isUnread ? FontWeight.bold : FontWeight.w600,
//                         ),
//                       ),
//                     ),
//                     if (isUnread)
//                       Container(
//                         width: 8,
//                         height: 8,
//                         decoration: const BoxDecoration(
//                           color: Colors.blue,
//                           shape: BoxShape.circle,
//                         ),
//                       ),
//                   ],
//                 ),
//                 subtitle: Text(
//                   conversation.content,
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//                 trailing: Text(
//                   _formatTime(conversation.timestamp),
//                   style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
//                 ),
//                 onTap: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => ChatScreen(
//                         receiverId: otherPersonId,
//                         receiverName: otherPersonName,
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             );
//           },
//         );
//       },
//     );
//   }

//   String _formatTime(DateTime timestamp) {
//     final now = DateTime.now();
//     final difference = now.difference(timestamp);

//     if (difference.inDays > 0) {
//       return '${difference.inDays}d ago';
//     } else if (difference.inHours > 0) {
//       return '${difference.inHours}h ago';
//     } else if (difference.inMinutes > 0) {
//       return '${difference.inMinutes}m ago';
//     } else {
//       return 'Just now';
//     }
//   }

//   Widget _buildNotificationsTab() {
//     final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;

//     if (currentUser == null) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.error_outline, size: 64, color: Colors.red),
//             SizedBox(height: 16),
//             Text('Please login to view notifications'),
//           ],
//         ),
//       );
//     }

//     String currentUserId = currentUser.uid;

//     return Padding(
//       padding: const EdgeInsets.all(20),
//       child: Column(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Colors.green.shade50,
//               borderRadius: BorderRadius.circular(16),
//             ),
//             child: Row(
//               children: [
//                 Icon(Icons.notifications_none, color: Colors.green.shade700),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Text(
//                     _userRole == 'tutor'
//                         ? 'Stay updated with your teaching activities'
//                         : 'Stay updated with your learning journey',
//                     style: const TextStyle(fontSize: 16, color: Colors.black87),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 20),
//           Expanded(
//             child: StreamBuilder<List<NotificationModel>>(
//               stream: Provider.of<NotificationProvider>(
//                 context,
//                 listen: true,
//               ).getUserNotifications(currentUserId),
//               builder: (context, snapshot) {
//                 if (snapshot.hasError) {
//                   return Center(child: Text('Error: ${snapshot.error}'));
//                 }

//                 final notifications = snapshot.data ?? [];

//                 if (notifications.isEmpty) {
//                   return ui.EmptyState(
//                     icon: Icons.notifications_off,
//                     title: 'No notifications yet',
//                     message: 'Your notifications will appear here',
//                   );
//                 }

//                 return ListView.builder(
//                   itemCount: notifications.length,
//                   itemBuilder: (context, index) {
//                     final notification = notifications[index];
//                     return _buildNotificationItem(notification);
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildNotificationItem(NotificationModel notification) {
//     IconData icon;
//     Color iconColor;

//     switch (notification.type) {
//       case 'tutoring_request':
//         icon = Icons.school;
//         iconColor = Colors.orange.shade700;
//         break;
//       case 'tutoring_request_approved':
//         icon = Icons.check_circle;
//         iconColor = Colors.green.shade700;
//         break;
//       case 'tutoring_request_declined':
//         icon = Icons.cancel;
//         iconColor = Colors.red.shade700;
//         break;
//       default:
//         icon = Icons.notifications;
//         iconColor = Colors.grey.shade700;
//     }

//     return Card(
//       margin: const EdgeInsets.only(bottom: 12),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: ListTile(
//         leading: Container(
//           padding: const EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             color: iconColor.withOpacity(0.1),
//             shape: BoxShape.circle,
//           ),
//           child: Icon(icon, color: iconColor, size: 20),
//         ),
//         title: Text(
//           notification.title,
//           style: TextStyle(
//             fontWeight:
//                 notification.isRead ? FontWeight.normal : FontWeight.w600,
//             color: notification.isRead ? Colors.grey : Colors.black,
//           ),
//         ),
//         subtitle: Text(
//           notification.body,
//           style: TextStyle(
//             color: notification.isRead ? Colors.grey : Colors.black87,
//           ),
//         ),
//         trailing: notification.isRead
//             ? null
//             : Container(
//                 width: 8,
//                 height: 8,
//                 decoration: const BoxDecoration(
//                   color: Colors.red,
//                   shape: BoxShape.circle,
//                 ),
//               ),
//         onTap: () {
//           Provider.of<NotificationProvider>(
//             context,
//             listen: false,
//           ).markAsRead(notification.id);
//           _handleNotificationTap(notification);
//         },
//       ),
//     );
//   }

//   void _handleNotificationTap(NotificationModel notification) {
//     if (notification.type.startsWith('tutoring_request')) {
//       setState(() {
//         _selectedIndex = 3;
//       });
//     }
//   }

//   Widget _buildProfileTab() {
//     final authProvider = Provider.of<AuthProvider>(context, listen: false);

//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(20),
//       child: Column(
//         children: [
//           Card(
//             elevation: 4,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(20),
//             ),
//             child: Padding(
//               padding: const EdgeInsets.all(24),
//               child: Column(
//                 children: [
//                   CircleAvatar(
//                     radius: 50,
//                     backgroundColor: Colors.blue.shade100,
//                     backgroundImage: _profileImage != null
//                         ? NetworkImage(_profileImage!)
//                         : null,
//                     child: _profileImage == null
//                         ? Icon(
//                             Icons.person,
//                             size: 40,
//                             color: Colors.blue.shade700,
//                           )
//                         : null,
//                   ),
//                   const SizedBox(height: 16),
//                   Text(
//                     _userName ?? 'User Name',
//                     style: const TextStyle(
//                       fontSize: 22,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     _userRole?.toUpperCase() ?? 'STUDENT',
//                     style: TextStyle(
//                       fontSize: 14,
//                       color: Colors.blue.shade700,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceAround,
//                     children: [
//                       _buildProfileStat(
//                         _userRole == 'tutor' ? 'Students' : 'Tutors',
//                         '5',
//                       ),
//                       _buildProfileStat('Sessions', '12'),
//                       _buildProfileStat('Rating', '4.8'),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           const SizedBox(height: 24),
//           Card(
//             elevation: 4,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(16),
//             ),
//             child: Column(
//               children: [
//                 _buildProfileOption(
//                   'Edit Profile',
//                   Icons.edit_outlined,
//                   onTap: () {
//                     final role = _userRole ?? 'student';
//                     switch (role) {
//                       case 'tutor':
//                         Navigator.pushNamed(context, '/tutor-info');
//                         break;
//                       case 'parent':
//                         Navigator.pushNamed(context, '/parent-info');
//                         break;
//                       case 'student':
//                       default:
//                         Navigator.pushNamed(context, '/student-info');
//                     }
//                   },
//                 ),
//                 _buildProfileOption('Settings', Icons.settings_outlined),
//                 _buildProfileOption('Help & Support', Icons.help_outline),
//                 _buildProfileOption(
//                   'Logout',
//                   Icons.logout,
//                   isLogout: true,
//                   onTap: () async {
//                     await authProvider.logout();
//                     Navigator.pushReplacementNamed(context, '/');
//                   },
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildProfileStat(String label, String value) {
//     return Column(
//       children: [
//         Text(
//           value,
//           style: const TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//             color: Colors.blue,
//           ),
//         ),
//         const SizedBox(height: 4),
//         Text(
//           label,
//           style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
//         ),
//       ],
//     );
//   }

//   Widget _buildProfileOption(
//     String title,
//     IconData icon, {
//     bool isLogout = false,
//     VoidCallback? onTap,
//   }) {
//     return ListTile(
//       leading: Icon(icon, color: isLogout ? Colors.red : Colors.blue.shade700),
//       title: Text(
//         title,
//         style: TextStyle(
//           color: isLogout ? Colors.red : Colors.black87,
//           fontWeight: FontWeight.w500,
//         ),
//       ),
//       trailing: const Icon(Icons.arrow_forward_ios, size: 16),
//       onTap: onTap,
//     );
//   }

//   // ========== STREAM METHODS ==========

//   Stream<int> _getUnreadMessageCount() {
//     final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
//     if (currentUser == null) return Stream.value(0);

//     return FirebaseFirestore.instance
//         .collection('messages')
//         .where('receiverId', isEqualTo: currentUser.uid)
//         .where('isRead', isEqualTo: false)
//         .snapshots()
//         .map((snapshot) => snapshot.docs.length)
//         .handleError((error) {
//       return 0;
//     });
//   }

//   Stream<int> _getUnreadNotificationCount() {
//     final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
//     if (currentUser == null) return Stream.value(0);

//     return FirebaseFirestore.instance
//         .collection('notifications')
//         .where('userId', isEqualTo: currentUser.uid)
//         .where('isRead', isEqualTo: false)
//         .snapshots()
//         .map((snapshot) => snapshot.docs.length)
//         .handleError((error) {
//       return 0;
//     });
//   }

//   Stream<int> _getRelationshipAttentionCount() {
//     final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
//     if (currentUser == null) return Stream.value(0);

//     final uid = currentUser.uid;
//     final isTutor = _userRole == 'tutor';
//     final fieldName = isTutor ? 'tutorId' : 'studentId';

//     return FirebaseFirestore.instance
//         .collection('tutoringRequests')
//         .where(fieldName, isEqualTo: uid)
//         .where('status', isEqualTo: 'pending')
//         .snapshots()
//         .map((snapshot) => snapshot.docs.length)
//         .handleError((error) => 0);
//   }

//   @override
//   void dispose() {
//     _debounce?.cancel();
//     super.dispose();
//   }

//   // ========== BUILD METHOD ==========

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       theme: AppTheme.light,
//       darkTheme: AppTheme.dark,
//       themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
//       home: Builder(
//         builder: (context) {
//           final theme = Theme.of(context);
//           return Scaffold(
//             backgroundColor: theme.colorScheme.background,
//             appBar: null,
//             body: IndexedStack(
//               index: _selectedIndex,
//               children: [
//                 _buildHomeTab(),
//                 _buildMessagesTab(),
//                 _buildNotificationsTab(),
//                 _LazyRelationshipsTab(isActive: _selectedIndex == 3),
//                 _buildProfileTab(),
//               ],
//             ),
//             bottomNavigationBar: StreamBuilder<int>(
//               stream: _getUnreadMessageCount(),
//               builder: (context, msgSnapshot) {
//                 final unreadMsgCount = msgSnapshot.data ?? 0;

//                 return StreamBuilder<int>(
//                   stream: _getUnreadNotificationCount(),
//                   builder: (context, notifSnapshot) {
//                     final unreadNotifCount = notifSnapshot.data ?? 0;
//                     final effectiveNotifCount =
//                         _selectedIndex == 2 ? 0 : unreadNotifCount;

//                     return StreamBuilder<int>(
//                       stream: _getRelationshipAttentionCount(),
//                       builder: (context, relSnapshot) {
//                         final relCount = relSnapshot.data ?? 0;
//                         final effectiveRelCount =
//                             _selectedIndex == 3 ? 0 : relCount;

//                         return Container(
//                           height: 80,
//                           decoration: BoxDecoration(
//                             color: Colors.white,
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.black.withOpacity(0.1),
//                                 blurRadius: 8,
//                                 offset: const Offset(0, -2),
//                               ),
//                             ],
//                           ),
//                           child: Padding(
//                             padding: const EdgeInsets.only(bottom: 16),
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceAround,
//                               children: [
//                                 _buildNavItem(
//                                     0, Icons.home, 'Home', _selectedIndex == 0),
//                                 _buildNavItem(
//                                     1,
//                                     Icons.chat_bubble_outline,
//                                     'Messages',
//                                     _selectedIndex == 1,
//                                     unreadMsgCount),
//                                 _buildNavItem(
//                                     2,
//                                     Icons.notifications_outlined,
//                                     'Notifications',
//                                     _selectedIndex == 2,
//                                     effectiveNotifCount),
//                                 _buildNavItem(
//                                     3,
//                                     Icons.group_outlined,
//                                     'Relationships',
//                                     _selectedIndex == 3,
//                                     effectiveRelCount),
//                                 _buildNavItem(4, Icons.person_outline,
//                                     'Profile', _selectedIndex == 4),
//                               ],
//                             ),
//                           ),
//                         );
//                       },
//                     );
//                   },
//                 );
//               },
//             ),
//           );
//         },
//       ),
//       debugShowCheckedModeBanner: false,
//     );
//   }

//   Widget _buildNavItem(int index, IconData icon, String label, bool isSelected,
//       [int badgeCount = 0]) {
//     return GestureDetector(
//       onTap: () => setState(() => _selectedIndex = index),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Stack(
//             children: [
//               Icon(
//                 isSelected ? _getFilledIcon(icon) : icon,
//                 color: isSelected
//                     ? const Color(0xFF2B8CEE)
//                     : const Color(0xFF617589),
//                 size: 28,
//               ),
//               if (badgeCount > 0)
//                 Positioned(
//                   right: -4,
//                   top: -4,
//                   child: Container(
//                     padding: const EdgeInsets.all(2),
//                     decoration: const BoxDecoration(
//                       color: Colors.red,
//                       shape: BoxShape.circle,
//                     ),
//                     constraints: const BoxConstraints(
//                       minWidth: 18,
//                       minHeight: 18,
//                     ),
//                     child: Text(
//                       badgeCount > 99 ? '99+' : badgeCount.toString(),
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 10,
//                         fontWeight: FontWeight.bold,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//           const SizedBox(height: 4),
//           Text(
//             label,
//             style: TextStyle(
//               fontSize: 12,
//               fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
//               color: isSelected
//                   ? const Color(0xFF2B8CEE)
//                   : const Color(0xFF617589),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   IconData _getFilledIcon(IconData outlineIcon) {
//     switch (outlineIcon) {
//       case Icons.home_outlined:
//         return Icons.home;
//       case Icons.chat_bubble_outline:
//         return Icons.chat;
//       case Icons.notifications_outlined:
//         return Icons.notifications;
//       case Icons.group_outlined:
//         return Icons.group;
//       case Icons.person_outline:
//         return Icons.person;
//       default:
//         return outlineIcon;
//     }
//   }
// }

// class _LazyRelationshipsTab extends StatefulWidget {
//   final bool isActive;

//   const _LazyRelationshipsTab({super.key, required this.isActive});

//   @override
//   State<_LazyRelationshipsTab> createState() => _LazyRelationshipsTabState();
// }

// class _LazyRelationshipsTabState extends State<_LazyRelationshipsTab> {
//   bool _initialized = false;

//   @override
//   void initState() {
//     super.initState();
//     _initialized = widget.isActive;
//   }

//   @override
//   void didUpdateWidget(covariant _LazyRelationshipsTab oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (widget.isActive && !_initialized) {
//       setState(() {
//         _initialized = true;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (!_initialized) {
//       return const SizedBox.shrink();
//     }
//     return const RelationshipsScreen();
//   }
// }
