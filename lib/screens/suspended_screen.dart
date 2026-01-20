import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SuspendedScreen extends StatelessWidget {
  const SuspendedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF101922) : const Color(0xFFF6F7F8);
    final titleColor = isDark ? Colors.white : const Color(0xFF111418);
    final bodyColor = isDark ? Colors.grey.shade300 : const Color(0xFF617589);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 64,
                  width: 64,
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.block,
                    color: Colors.red.shade600,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Account suspended',
                  style: GoogleFonts.lexend(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your account has been suspended by an administrator. '
                  'If you believe this is a mistake, please contact support.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lexend(
                    fontSize: 14,
                    color: bodyColor,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, '/login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2B8CEE),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Back to login',
                    style: GoogleFonts.lexend(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
