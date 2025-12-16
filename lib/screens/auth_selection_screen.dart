// import 'package:flutter/material.dart';

// class AuthSelectionScreen extends StatelessWidget {
//   const AuthSelectionScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final cs = theme.colorScheme;

//     return Scaffold(
//       body: Stack(
//         children: [
//           // Background gradient + soft blobs
//           Container(
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [
//                   cs.primary.withOpacity(0.10),
//                   cs.primaryContainer.withOpacity(0.06),
//                   cs.surfaceVariant.withOpacity(0.04),
//                 ],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//             ),
//           ),
//           Positioned(
//             top: -80,
//             left: -60,
//             child: _Blob(color: cs.primary.withOpacity(0.18), size: 220),
//           ),
//           Positioned(
//             bottom: -100,
//             right: -80,
//             child: _Blob(
//                 color: cs.secondaryContainer.withOpacity(0.22), size: 260),
//           ),

//           SafeArea(
//             child: LayoutBuilder(
//               builder: (context, constraints) {
//                 final wide = constraints.maxWidth >= 900;
//                 return Center(
//                   child: Padding(
//                     padding: const EdgeInsets.all(20),
//                     child: ConstrainedBox(
//                       constraints: const BoxConstraints(maxWidth: 1000),
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         crossAxisAlignment: CrossAxisAlignment.stretch,
//                         children: [
//                           const _HeroPane(),
//                           const SizedBox(height: 20),
//                           _AuthContent(wide: wide),
//                         ],
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _HeroPane extends StatelessWidget {
//   const _HeroPane();

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final cs = theme.colorScheme;
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               width: 56,
//               height: 56,
//               decoration: BoxDecoration(
//                 color: cs.primary,
//                 borderRadius: BorderRadius.circular(14),
//                 boxShadow: [
//                   BoxShadow(
//                     color: cs.primary.withOpacity(0.25),
//                     blurRadius: 18,
//                     offset: const Offset(0, 10),
//                   )
//                 ],
//               ),
//               child: const Icon(Icons.auto_awesome, color: Colors.white),
//             ),
//             const SizedBox(width: 12),
//             Text('MentorMe',
//                 style: theme.textTheme.headlineSmall?.copyWith(
//                   fontWeight: FontWeight.w700,
//                 )),
//           ],
//         ),
//         const SizedBox(height: 16),
//         Text(
//           'Learn better. Teach smarter.',
//           style: theme.textTheme.headlineMedium
//               ?.copyWith(fontWeight: FontWeight.w700),
//         ),
//         const SizedBox(height: 8),
//         Text(
//           'A trusted place for students, parents and tutors to connect, meet, and succeed.',
//           style:
//               theme.textTheme.titleMedium?.copyWith(color: cs.onSurfaceVariant),
//         ),
//         const SizedBox(height: 20),
//         Wrap(
//           runSpacing: 8,
//           spacing: 8,
//           children: const [
//             _FeatureChip(icon: Icons.verified_user, label: 'Verified Profiles'),
//             _FeatureChip(icon: Icons.calendar_month, label: 'Smart Scheduling'),
//             _FeatureChip(icon: Icons.lock, label: 'Safe & Private'),
//           ],
//         )
//       ],
//     );
//   }
// }

// class _AuthContent extends StatelessWidget {
//   final bool wide;
//   const _AuthContent({required this.wide});

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final cs = theme.colorScheme;
//     return Card(
//       elevation: 2,
//       child: Padding(
//         padding: EdgeInsets.symmetric(
//             horizontal: wide ? 28 : 20, vertical: wide ? 28 : 20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Row(
//               children: [
//                 Icon(Icons.person_outline, color: cs.primary),
//                 const SizedBox(width: 8),
//                 Text('Welcome',
//                     style: theme.textTheme.titleLarge?.copyWith(
//                       fontWeight: FontWeight.w600,
//                     )),
//               ],
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'Choose how you want to continue',
//               style: theme.textTheme.bodyMedium
//                   ?.copyWith(color: cs.onSurfaceVariant),
//             ),
//             const SizedBox(height: 20),
//             SizedBox(
//               width: double.infinity,
//               child: FilledButton.icon(
//                 onPressed: () => Navigator.pushNamed(context, '/login'),
//                 icon: const Icon(Icons.login),
//                 label: const Padding(
//                   padding: EdgeInsets.symmetric(vertical: 2),
//                   child: Text('Log In'),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 12),
//             SizedBox(
//               width: double.infinity,
//               child: OutlinedButton.icon(
//                 onPressed: () => Navigator.pushNamed(context, '/signup'),
//                 icon: const Icon(Icons.person_add),
//                 label: const Padding(
//                   padding: EdgeInsets.symmetric(vertical: 2),
//                   child: Text('Sign Up'),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // Legacy role cards removed per request — unified auth entry only.

// class _RoleCardsGrid extends StatelessWidget {
//   final bool wide;
//   const _RoleCardsGrid({required this.wide});

//   @override
//   Widget build(BuildContext context) {
//     final cards = [
//       _RoleCard(
//         icon: Icons.school,
//         title: 'Student',
//         description: 'Find expert tutors and start learning smart.',
//         onLogin: () =>
//             Navigator.pushNamed(context, '/login', arguments: 'student'),
//         onSignup: () =>
//             Navigator.pushNamed(context, '/signup', arguments: 'student'),
//       ),
//       _RoleCard(
//         icon: Icons.family_restroom,
//         title: 'Parent',
//         description: 'Discover vetted tutors for your child’s success.',
//         onLogin: () =>
//             Navigator.pushNamed(context, '/login', arguments: 'parent'),
//         onSignup: () =>
//             Navigator.pushNamed(context, '/signup', arguments: 'parent'),
//       ),
//       _RoleCard(
//         icon: Icons.workspace_premium,
//         title: 'Tutor',
//         description: 'Share your expertise and grow your impact.',
//         onLogin: () =>
//             Navigator.pushNamed(context, '/login', arguments: 'tutor'),
//         onSignup: () =>
//             Navigator.pushNamed(context, '/signup', arguments: 'tutor'),
//       ),
//     ];

//     if (wide) {
//       return Row(
//         children: [
//           Expanded(child: cards[0]),
//           const SizedBox(width: 16),
//           Expanded(child: cards[1]),
//           const SizedBox(width: 16),
//           Expanded(child: cards[2]),
//         ],
//       );
//     }

//     return Column(
//       children: [
//         cards[0],
//         const SizedBox(height: 12),
//         cards[1],
//         const SizedBox(height: 12),
//         cards[2],
//       ],
//     );
//   }
// }

// class _RoleCard extends StatelessWidget {
//   final IconData icon;
//   final String title;
//   final String description;
//   final VoidCallback onLogin;
//   final VoidCallback onSignup;

//   const _RoleCard({
//     required this.icon,
//     required this.title,
//     required this.description,
//     required this.onLogin,
//     required this.onSignup,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final cs = theme.colorScheme;
//     return Card(
//       elevation: 1,
//       child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Container(
//                   width: 44,
//                   height: 44,
//                   decoration: BoxDecoration(
//                     color: cs.primary.withOpacity(0.12),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Icon(icon, color: cs.primary),
//                 ),
//                 const SizedBox(width: 10),
//                 Text(title,
//                     style: theme.textTheme.titleLarge
//                         ?.copyWith(fontWeight: FontWeight.w700)),
//               ],
//             ),
//             const SizedBox(height: 8),
//             Text(description,
//                 style: theme.textTheme.bodyMedium?.copyWith(
//                     color: Theme.of(context).colorScheme.onSurfaceVariant)),
//             const SizedBox(height: 16),
//             Row(
//               children: [
//                 Expanded(
//                   child: FilledButton(
//                     onPressed: onLogin,
//                     child: const Text('Log In'),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: OutlinedButton(
//                     onPressed: onSignup,
//                     child: const Text('Sign Up'),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _FeatureChip extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   const _FeatureChip({required this.icon, required this.label});

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final cs = theme.colorScheme;
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//       decoration: BoxDecoration(
//         color: cs.primaryContainer.withOpacity(0.35),
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, size: 16, color: cs.onPrimaryContainer),
//           const SizedBox(width: 6),
//           Text(label,
//               style: TextStyle(
//                   color: cs.onPrimaryContainer, fontWeight: FontWeight.w600)),
//         ],
//       ),
//     );
//   }
// }

// class _Blob extends StatelessWidget {
//   final Color color;
//   final double size;
//   const _Blob({required this.color, required this.size});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: size,
//       height: size,
//       decoration: BoxDecoration(
//         color: color,
//         shape: BoxShape.circle,
//         boxShadow: [
//           BoxShadow(
//               color: color.withOpacity(0.5), blurRadius: 50, spreadRadius: 10),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthSelectionScreen extends StatelessWidget {
  const AuthSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF2B8CEE);
    const bgLight = Color(0xFFF6F7F8);
    final lexend = GoogleFonts.lexend().fontFamily;
    final textTheme = Theme.of(context).textTheme.apply(fontFamily: lexend);

    return Scaffold(
      backgroundColor: bgLight,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              const SizedBox(height: 28),
              // Logo + Tagline
              Column(
                children: [
                  Container(
                    height: 64,
                    width: 64,
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.school_rounded,
                        color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'MentorMe',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your Personal Learning Partner',
                    textAlign: TextAlign.center,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 28,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Illustration
              Expanded(
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 320),
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(
                          'https://lh3.googleusercontent.com/aida-public/AB6AXuCSFRhUiDfzPfq-FSL0auQGFMkiAto1FQlbM_SgnL52-UlvxduALrp1UK4LheqVOTN9kJHxb1Lg-wlMKpgZH66qVSCusBwpim6NUBPc_lDyUS0duNaZRxxkjlHXr0140pZPnIM_vBhbuzzwz3KJ3eXoFAk3HyMakbWBhXtjR1XP6e0FGITcLYetT9vvjOQCGWtDwh-kMq4pmmygsYC4lvaHEWUKuQgjiCsRbaos5W6KijOpelIiZuxkzhUwF45BIqLMDU0q07tnrxZ7',
                        ),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
              // CTA
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/signup'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Create Account',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  child: RichText(
                    text: TextSpan(
                      style: textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600], fontFamily: lexend),
                      children: [
                        const TextSpan(text: 'Already have an account? '),
                        TextSpan(
                          text: 'Log In',
                          style: TextStyle(
                            color: primary,
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
    );
  }
}
