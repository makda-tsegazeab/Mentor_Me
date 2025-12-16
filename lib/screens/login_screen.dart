import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final List<String> _roles = ['student', 'tutor', 'parent'];
  final _formKey = GlobalKey<FormState>();

  String _role = 'student';
  String? _errorMessage;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _didInitArgs = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitArgs) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && _roles.contains(args)) {
      setState(() {
        _role = args;
      });
    }
    _didInitArgs = true;
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      final user = await authProvider.login(
        email: email,
        password: password,
        role: _role,
      );
      if (user == null) {
        setState(() => _errorMessage = 'Login failed. Try again.');
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data()?['completedProfile'] == true) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        switch (_role) {
          case 'student':
            Navigator.pushReplacementNamed(context, '/student-info');
            break;
          case 'tutor':
            Navigator.pushReplacementNamed(context, '/tutor-info');
            break;
          case 'parent':
            Navigator.pushReplacementNamed(context, '/parent-info');
            break;
          default:
            Navigator.pushReplacementNamed(context, '/student-info');
        }
      }
    } catch (e) {
      setState(() => _errorMessage = authProvider.error ?? e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _capitalize(String s) =>
      s.isNotEmpty ? '${s[0].toUpperCase()}${s.substring(1)}' : s;

  @override
  Widget build(BuildContext context) {
    // Palette inspired by the provided design
    const primaryAlt = Color(0xFF4A90E2);
    const bgLight = Color(0xFFF6F7F8);
    const textLight = Color(0xFF333333);
    const subtle = Color(0xFF617589);
    const borderLight = Color(0xFFD1D1D1);

    final textTheme = GoogleFonts.lexendTextTheme(Theme.of(context).textTheme);

    InputDecoration _input({
      required String label,
      required String hint,
      required IconData icon,
      Widget? suffix,
      bool obscure = false,
    }) {
      return InputDecoration(
        floatingLabelBehavior: FloatingLabelBehavior.never,
        hintText: hint,
        hintStyle: GoogleFonts.lexend(color: subtle),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Container(
          width: 48,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              right: BorderSide(color: borderLight),
            ),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: subtle),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 0),
        suffixIcon: suffix,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryAlt, width: 1.2),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 12),
                  // Logo
                  Container(
                    height: 64,
                    width: 64,
                    decoration: const BoxDecoration(
                      color: primaryAlt,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.school,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Welcome Back',
                    textAlign: TextAlign.center,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: textLight,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Log in to continue your learning journey.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(color: subtle),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Email',
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: textLight,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            style: GoogleFonts.lexend(color: textLight),
                            decoration: _input(
                              label: 'Email',
                              hint: 'you@example.com',
                              icon: Icons.mail,
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Email is required'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Password',
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: textLight,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: GoogleFonts.lexend(color: textLight),
                            decoration: _input(
                              label: 'Password',
                              hint: 'Enter your password',
                              icon: Icons.lock,
                              suffix: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: subtle,
                                ),
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Password is required'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {},
                              child: const Text(
                                'Forgot Password?',
                                style: TextStyle(color: primaryAlt),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Role selection (kept for functionality)
                          Text(
                            'Role',
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: textLight,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _role,
                            style: GoogleFonts.lexend(
                                color: textLight, fontSize: 16),
                            items: _roles
                                .map(
                                  (r) => DropdownMenuItem(
                                    value: r,
                                    child: Text(
                                      _capitalize(r),
                                      style: GoogleFonts.lexend(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: textLight,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _role = v ?? _role),
                            decoration: _input(
                              label: 'Role',
                              hint: 'Select your role',
                              icon: Icons.person_outline,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryAlt,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                _isLoading ? 'Logging in...' : 'Log In',
                                style: textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              const Expanded(
                                child: Divider(
                                  color: borderLight,
                                  thickness: 1,
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'OR',
                                  style: textTheme.bodyMedium
                                      ?.copyWith(color: subtle),
                                ),
                              ),
                              const Expanded(
                                child: Divider(
                                  color: borderLight,
                                  thickness: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 56,
                            child: OutlinedButton.icon(
                              onPressed: _isLoading ? null : () {},
                              icon: Image.network(
                                'https://lh3.googleusercontent.com/aida-public/AB6AXuACQhTmPO-ZyOMnXSFM3l7xSKaM195s1LX47xnwFmwBdthJXXmlZ9jobytRgolm5vD_uLRTtxsKu9bQoaKOjGD3JA9LPKXC8YzWrUHc6VR50ACKXVN3mkpDA6nvL1ehqWhAghpA7viGWkU22j49fEX-HwtxdBwttDtJkuuj0_ERljKv7cz6yjRQM30s3FAGbnt1U_NCqI4E0DaD96x6EcrjMzW3eMsn8rCp9F1gFIh99U5P0XlDn8ndnyFm2oC7vNFza-gG3CV0jteJ',
                                height: 24,
                                width: 24,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.g_mobiledata,
                                  color: Color(0xFF4285F4),
                                  size: 24,
                                ),
                              ),
                              label: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2),
                                child: Text(
                                  'Continue with Google',
                                  style: GoogleFonts.lexend(
                                    fontWeight: FontWeight.w700,
                                    color: textLight,
                                  ),
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                    color: borderLight, width: 1),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => Navigator.pushReplacementNamed(
                                        context,
                                        '/signup',
                                      ),
                              child: RichText(
                                text: TextSpan(
                                  text: "Don't have an account? ",
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: subtle,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  children: const [
                                    TextSpan(
                                      text: 'Sign Up',
                                      style: TextStyle(
                                        color: primaryAlt,
                                        fontWeight: FontWeight.w800,
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
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
