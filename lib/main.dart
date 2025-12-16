import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/message_provider.dart';
import 'screens/auth_selection_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/student_info_screen.dart';
import 'screens/parent_info_screen.dart';
import 'screens/tutor_info_screen.dart';
import 'firebase_options.dart';
import 'providers/notification_provider.dart';
import 'providers/rating_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Keep Firestore stable on web by disabling persistence/cache sharing.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  final projectId = FirebaseFirestore.instance.app.options.projectId;
  debugPrint('🔥 Flutter is using Firebase project: $projectId');

  runApp(const MentorMeApp());
}

class MentorMeApp extends StatelessWidget {
  const MentorMeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MessageProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => RatingProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        title: 'MentorMe',
        theme: ThemeData(
          primaryColor: const Color(0xFF2F4B8A),
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF2F4B8A),
            secondary: Color(0xFFFF6B6B),
            background: Color(0xFFF7F9FB),
          ),
          scaffoldBackgroundColor: const Color(0xFFF7F9FB),
          fontFamily: 'Poppins',
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Color(0xFF1F2937)),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2F4B8A),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthSelectionScreen(),
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
          '/home': (context) => const HomeScreen(),
          '/student-info': (context) => const StudentInfoScreen(),
          '/parent-info': (context) => const ParentInfoScreen(),
          '/tutor-info': (context) => const TutorInfoScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/home') {
            final authProvider = Provider.of<AuthProvider>(
              navigatorKey.currentContext!,
              listen: false,
            );
            final user = authProvider.currentUser;

            if (user == null) {
              return MaterialPageRoute(
                builder: (_) => const AuthSelectionScreen(),
              );
            }

            return MaterialPageRoute(builder: (_) {
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const AuthSelectionScreen();
                  }

                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  final role =
                      (data['role'] ?? '').toString().trim().toLowerCase();
                  final completedProfile = data['completedProfile'] == true;

                  // If profile not completed, send user to their respective info screen
                  if (!completedProfile) {
                    switch (role) {
                      case 'student':
                        return const StudentInfoScreen();
                      case 'parent':
                        return const ParentInfoScreen();
                      case 'tutor':
                        return const TutorInfoScreen();
                      default:
                        return const AuthSelectionScreen();
                    }
                  }

                  // If profile is completed, ALL users go to the unified HomeScreen
                  return const HomeScreen();
                },
              );
            });
          }
          return null;
        },
      ),
    );
  }
}
