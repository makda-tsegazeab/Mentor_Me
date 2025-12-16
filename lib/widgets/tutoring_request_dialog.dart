// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import '../models/tutoring_request.dart';

// class TutoringRequestDialog extends StatefulWidget {
//   final String fromUserId;
//   final String fromUserName;
//   final String toUserId;
//   final String toUserName;
//   final Future<void> Function(TutoringRequest request) onRequestSent;

//   const TutoringRequestDialog({
//     super.key,
//     required this.fromUserId,
//     required this.fromUserName,
//     required this.toUserId,
//     required this.toUserName,
//     required this.onRequestSent,
//   });

//   @override
//   State<TutoringRequestDialog> createState() => _TutoringRequestDialogState();
// }

// class _TutoringRequestDialogState extends State<TutoringRequestDialog> {
//   final _messageController = TextEditingController();
//   bool _isSending = false;
//   int _hoursPerWeek = 4;
//   final List<String> _subjects = [];
//   final Set<String> _preferredDays = {'Mon', 'Wed'};

//   final List<Map<String, String>> _dayLabels = const [
//     {'key': 'Sun', 'label': 'Su'},
//     {'key': 'Mon', 'label': 'M'},
//     {'key': 'Tue', 'label': 'Tu'},
//     {'key': 'Wed', 'label': 'W'},
//     {'key': 'Thu', 'label': 'Th'},
//     {'key': 'Fri', 'label': 'F'},
//     {'key': 'Sat', 'label': 'Sa'},
//   ];

//   // Subjects list from StudentInfoScreen
//   final List<String> subjects = [
//     'Mathematics',
//     'English',
//     'Amharic',
//     'Tigrigna',
//     'Physics',
//     'Chemistry',
//     'Biology',
//     'ICT',
//     'History',
//     'Geography',
//     'Civics',
//     'Art',
//     'Economics',
//     'Social Studies',
//     'Physical Education',
//     'Ethics',
//   ];

//   Future<void> _sendRequest() async {
//     if (_isSending) return;
//     final message = _messageController.text.trim();
//     if (_subjects.isEmpty) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please add at least one subject.')),
//       );
//       return;
//     }

//     setState(() => _isSending = true);
//     final request = TutoringRequest(
//       id: DateTime.now().millisecondsSinceEpoch.toString(),
//       studentId: widget.fromUserId,
//       studentName: widget.fromUserName,
//       tutorId: widget.toUserId,
//       tutorName: widget.toUserName,
//       message: message,
//       subjects: List<String>.from(_subjects),
//       preferredDays: _preferredDays.toList(),
//       hoursPerWeek: _hoursPerWeek,
//     );

//     try {
//       await widget.onRequestSent(request);
//       if (mounted) Navigator.of(context).pop();
//     } finally {
//       if (mounted) setState(() => _isSending = false);
//     }
//   }

//   @override
//   void dispose() {
//     _messageController.dispose();
//     super.dispose();
//   }

//   void _showSubjectPicker() {
//     final remaining = subjects.where((s) => !_subjects.contains(s)).toList();
//     showModalBottomSheet(
//       context: context,
//       builder: (ctx) {
//         return SafeArea(
//           child: ListView.separated(
//             itemCount: remaining.length,
//             separatorBuilder: (_, __) => const Divider(height: 1),
//             itemBuilder: (_, i) {
//               final subj = remaining[i];
//               return ListTile(
//                 title: Text(
//                   subj,
//                   style: GoogleFonts.lexend(
//                     fontSize: 16,
//                   ),
//                 ),
//                 onTap: () {
//                   setState(() => _subjects.add(subj));
//                   Navigator.pop(ctx);
//                 },
//               );
//             },
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildSubjectChips() {
//     return Wrap(
//       spacing: 8,
//       runSpacing: 8,
//       children: [
//         ..._subjects.map(
//           (s) => Container(
//             decoration: BoxDecoration(
//               color: const Color(0x332B8CEE),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Text(
//                     s,
//                     style: GoogleFonts.lexend(
//                       color: const Color(0xFF2B8CEE),
//                       fontWeight: FontWeight.w600,
//                       fontSize: 14,
//                     ),
//                   ),
//                   const SizedBox(width: 6),
//                   GestureDetector(
//                     onTap: () {
//                       setState(() => _subjects.remove(s));
//                     },
//                     child: const Icon(
//                       Icons.close,
//                       size: 16,
//                       color: Color(0xFF2B8CEE),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//         GestureDetector(
//           onTap: _showSubjectPicker,
//           child: Container(
//             decoration: BoxDecoration(
//               color: Colors.grey.shade100,
//               borderRadius: BorderRadius.circular(12),
//             ),
//             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//             child: Text(
//               '+ Add subject',
//               style: GoogleFonts.lexend(
//                 color: const Color(0xFF617589),
//                 fontWeight: FontWeight.w600,
//                 fontSize: 14,
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final isDark = theme.brightness == Brightness.dark;
//     final bg = isDark ? const Color(0xFF101922) : const Color(0xFFF9F9F9);
//     final textColor = isDark ? Colors.white : const Color(0xFF333333);
//     final primary = const Color(0xFF0A84FF);
//     final lightBorder = isDark ? Colors.grey.shade700 : const Color(0xFFE5E5EA);

//     return Scaffold(
//       backgroundColor: Colors.black.withOpacity(0.4),
//       body: SafeArea(
//         child: Container(
//           alignment: Alignment.bottomCenter,
//           child: Container(
//             decoration: BoxDecoration(
//               color: bg,
//               borderRadius:
//                   const BorderRadius.vertical(top: Radius.circular(16)),
//             ),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 const SizedBox(height: 6),
//                 Container(
//                   height: 4,
//                   width: 72,
//                   decoration: BoxDecoration(
//                     color:
//                         isDark ? Colors.grey.shade700 : const Color(0xFFE5E5EA),
//                     borderRadius: BorderRadius.circular(999),
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Padding(
//                   padding:
//                       const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                   child: Row(
//                     children: [
//                       TextButton(
//                         onPressed:
//                             _isSending ? null : () => Navigator.pop(context),
//                         child: Text(
//                           'Cancel',
//                           style: GoogleFonts.lexend(
//                             color: primary,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ),
//                       Expanded(
//                         child: Center(
//                           child: Text(
//                             'New Tutoring Request',
//                             style: GoogleFonts.lexend(
//                               color: textColor,
//                               fontSize: 18,
//                               fontWeight: FontWeight.w700,
//                             ),
//                           ),
//                         ),
//                       ),
//                       IconButton(
//                         onPressed:
//                             _isSending ? null : () => Navigator.pop(context),
//                         icon: Icon(Icons.close, color: primary),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const Divider(height: 1),
//                 Flexible(
//                   child: SingleChildScrollView(
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 16, vertical: 12),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'Subjects you need help with',
//                           style: GoogleFonts.lexend(
//                             fontWeight: FontWeight.w600,
//                             color: textColor,
//                             fontSize: 14,
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         // Container with border around subjects (same as StudentInfoScreen)
//                         Container(
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(12),
//                             border: Border.all(color: lightBorder),
//                           ),
//                           padding: const EdgeInsets.all(12),
//                           child: _buildSubjectChips(),
//                         ),
//                         const SizedBox(height: 12),
//                         const Divider(),
//                         const SizedBox(height: 8),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Text(
//                               'Hours per Week',
//                               style: GoogleFonts.lexend(
//                                   color: textColor,
//                                   fontSize: 15,
//                                   fontWeight: FontWeight.w600),
//                             ),
//                             Row(
//                               children: [
//                                 _counterButton(
//                                   label: '-',
//                                   onTap: () {
//                                     setState(() {
//                                       if (_hoursPerWeek > 1) _hoursPerWeek--;
//                                     });
//                                   },
//                                 ),
//                                 Padding(
//                                   padding: const EdgeInsets.symmetric(
//                                       horizontal: 10),
//                                   child: Text(
//                                     '$_hoursPerWeek',
//                                     style: GoogleFonts.lexend(
//                                       color: textColor,
//                                       fontWeight: FontWeight.w700,
//                                     ),
//                                   ),
//                                 ),
//                                 _counterButton(
//                                   label: '+',
//                                   onTap: () {
//                                     setState(() => _hoursPerWeek++);
//                                   },
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 12),
//                         const Divider(),
//                         const SizedBox(height: 8),
//                         Text(
//                           'Preferred Days',
//                           style: GoogleFonts.lexend(
//                               color: textColor,
//                               fontSize: 15,
//                               fontWeight: FontWeight.w600),
//                         ),
//                         const SizedBox(height: 8),
//                         GridView.builder(
//                           shrinkWrap: true,
//                           physics: const NeverScrollableScrollPhysics(),
//                           gridDelegate:
//                               const SliverGridDelegateWithFixedCrossAxisCount(
//                             crossAxisCount: 7,
//                             mainAxisSpacing: 8,
//                             crossAxisSpacing: 8,
//                           ),
//                           itemCount: _dayLabels.length,
//                           itemBuilder: (context, i) {
//                             final key = _dayLabels[i]['key']!;
//                             final label = _dayLabels[i]['label']!;
//                             final selected = _preferredDays.contains(key);
//                             return GestureDetector(
//                               onTap: () {
//                                 setState(() {
//                                   if (selected) {
//                                     _preferredDays.remove(key);
//                                   } else {
//                                     _preferredDays.add(key);
//                                   }
//                                 });
//                               },
//                               child: Container(
//                                 height: 36,
//                                 width: 36,
//                                 alignment: Alignment.center,
//                                 decoration: BoxDecoration(
//                                   color:
//                                       selected ? primary : Colors.transparent,
//                                   border: Border.all(
//                                     color: selected ? primary : lightBorder,
//                                   ),
//                                   shape: BoxShape.circle,
//                                 ),
//                                 child: Text(
//                                   label,
//                                   style: GoogleFonts.lexend(
//                                     color: selected ? Colors.white : textColor,
//                                     fontWeight: FontWeight.w700,
//                                   ),
//                                 ),
//                               ),
//                             );
//                           },
//                         ),
//                         const SizedBox(height: 12),
//                         const Divider(),
//                         const SizedBox(height: 8),
//                         Text(
//                           'Short Message (optional)',
//                           style: GoogleFonts.lexend(
//                               color: textColor,
//                               fontSize: 15,
//                               fontWeight: FontWeight.w600),
//                         ),
//                         const SizedBox(height: 6),
//                         TextField(
//                           controller: _messageController,
//                           minLines: 3,
//                           maxLines: 5,
//                           decoration: InputDecoration(
//                             hintText:
//                                 "e.g., 'Focus on exam preparation for the final quarter.'",
//                             hintStyle: GoogleFonts.lexend(
//                                 color: isDark
//                                     ? Colors.grey.shade500
//                                     : Colors.grey.shade400),
//                             filled: true,
//                             fillColor:
//                                 isDark ? Colors.grey.shade800 : Colors.white,
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                               borderSide: BorderSide(color: lightBorder),
//                             ),
//                             enabledBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                               borderSide: BorderSide(color: lightBorder),
//                             ),
//                             focusedBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                               borderSide:
//                                   BorderSide(color: primary, width: 1.2),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 Container(
//                   padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
//                   decoration: BoxDecoration(
//                     color: bg,
//                     borderRadius: const BorderRadius.vertical(
//                         bottom: Radius.circular(16)),
//                   ),
//                   child: SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: primary,
//                         minimumSize: const Size.fromHeight(48),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                       onPressed: _isSending ? null : _sendRequest,
//                       child: _isSending
//                           ? const SizedBox(
//                               width: 20,
//                               height: 20,
//                               child: CircularProgressIndicator(
//                                   strokeWidth: 2, color: Colors.white),
//                             )
//                           : Text(
//                               'Send Request',
//                               style: GoogleFonts.lexend(
//                                 fontWeight: FontWeight.w700,
//                                 color: Colors.white,
//                               ),
//                             ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _counterButton({required String label, required VoidCallback onTap}) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         height: 32,
//         width: 32,
//         decoration: BoxDecoration(
//           color: const Color(0xFFE5E5EA),
//           borderRadius: BorderRadius.circular(16),
//         ),
//         alignment: Alignment.center,
//         child: Text(
//           label,
//           style: GoogleFonts.lexend(
//               fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/tutoring_request.dart';

class TutoringRequestDialog extends StatefulWidget {
  final String fromUserId;
  final String fromUserName;
  final String toUserId;
  final String toUserName;
  final List<String> availableSubjects;
  final Future<void> Function(TutoringRequest request) onRequestSent;

  const TutoringRequestDialog({
    super.key,
    required this.fromUserId,
    required this.fromUserName,
    required this.toUserId,
    required this.toUserName,
    required this.availableSubjects,
    required this.onRequestSent,
  });

  @override
  State<TutoringRequestDialog> createState() => _TutoringRequestDialogState();
}

class _TutoringRequestDialogState extends State<TutoringRequestDialog> {
  final _messageController = TextEditingController();
  bool _isSending = false;
  int _hoursPerWeek = 4;
  final List<String> _subjects = [];
  final Set<String> _preferredDays = {'Mon', 'Wed'};

  final List<Map<String, String>> _dayLabels = const [
    {'key': 'Sun', 'label': 'Su'},
    {'key': 'Mon', 'label': 'M'},
    {'key': 'Tue', 'label': 'Tu'},
    {'key': 'Wed', 'label': 'W'},
    {'key': 'Thu', 'label': 'Th'},
    {'key': 'Fri', 'label': 'F'},
    {'key': 'Sat', 'label': 'Sa'},
  ];

  Future<void> _sendRequest() async {
    if (_isSending) return;
    final message = _messageController.text.trim();
    if (_subjects.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one subject.')),
      );
      return;
    }

    setState(() => _isSending = true);
    final request = TutoringRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      studentId: widget.fromUserId,
      studentName: widget.fromUserName,
      tutorId: widget.toUserId,
      tutorName: widget.toUserName,
      message: message,
      subjects: List<String>.from(_subjects),
      preferredDays: _preferredDays.toList(),
      hoursPerWeek: _hoursPerWeek,
    );

    try {
      await widget.onRequestSent(request);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _showSubjectPicker() {
    final remaining = widget.availableSubjects
        .where((s) => !_subjects.contains(s))
        .toList();
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: remaining.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No subjects available for this tutor.',
                    style: GoogleFonts.lexend(),
                  ),
                )
              : ListView.separated(
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
                        setState(() => _subjects.add(subj));
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildSubjectChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ..._subjects.map(
          (s) => Container(
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
                      setState(() => _subjects.remove(s));
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF101922) : const Color(0xFFF9F9F9);
    final textColor = isDark ? Colors.white : const Color(0xFF333333);
    final primary = const Color(0xFF0A84FF);
    final lightBorder = isDark ? Colors.grey.shade700 : const Color(0xFFE5E5EA);

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.4),
      body: SafeArea(
        child: Container(
          alignment: Alignment.bottomCenter,
          child: Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 6),
                Container(
                  height: 4,
                  width: 72,
                  decoration: BoxDecoration(
                    color:
                        isDark ? Colors.grey.shade700 : const Color(0xFFE5E5EA),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      TextButton(
                        onPressed:
                            _isSending ? null : () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.lexend(
                            color: primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            'New Tutoring Request',
                            style: GoogleFonts.lexend(
                              color: textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed:
                            _isSending ? null : () => Navigator.pop(context),
                        icon: Icon(Icons.close, color: primary),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: lightBorder),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Subjects you need help with',
                          style: GoogleFonts.lexend(
                            fontWeight: FontWeight.w600,
                            color: textColor,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color:
                                isDark ? Colors.transparent : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: lightBorder),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: _buildSubjectChips(),
                        ),
                        const SizedBox(height: 12),
                        Divider(color: lightBorder),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Hours per Week',
                              style: GoogleFonts.lexend(
                                color: textColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Row(
                              children: [
                                _counterButton(
                                  label: '-',
                                  onTap: () {
                                    setState(() {
                                      if (_hoursPerWeek > 1) _hoursPerWeek--;
                                    });
                                  },
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  child: Text(
                                    '$_hoursPerWeek',
                                    style: GoogleFonts.lexend(
                                      color: textColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                _counterButton(
                                  label: '+',
                                  onTap: () {
                                    setState(() => _hoursPerWeek++);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Divider(color: lightBorder),
                        const SizedBox(height: 8),
                        Text(
                          'Preferred Days',
                          style: GoogleFonts.lexend(
                            color: textColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                          ),
                          itemCount: _dayLabels.length,
                          itemBuilder: (context, i) {
                            final key = _dayLabels[i]['key']!;
                            final label = _dayLabels[i]['label']!;
                            final selected = _preferredDays.contains(key);
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (selected) {
                                    _preferredDays.remove(key);
                                  } else {
                                    _preferredDays.add(key);
                                  }
                                });
                              },
                              child: Container(
                                height: 36,
                                width: 36,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color:
                                      selected ? primary : Colors.transparent,
                                  border: Border.all(
                                    color: selected
                                        ? primary
                                        : (isDark
                                            ? Colors.grey.shade700
                                            : const Color(0xFFE5E5EA)),
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  label,
                                  style: GoogleFonts.lexend(
                                    color: selected ? Colors.white : textColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        Divider(color: lightBorder),
                        const SizedBox(height: 8),
                        Text(
                          'Short Message (optional)',
                          style: GoogleFonts.lexend(
                            color: textColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _messageController,
                          minLines: 3,
                          maxLines: 5,
                          decoration: InputDecoration(
                            hintText:
                                "e.g., 'Focus on exam preparation for the final quarter.'",
                            hintStyle: GoogleFonts.lexend(
                              color: isDark
                                  ? Colors.grey.shade500
                                  : Colors.grey.shade400,
                            ),
                            filled: true,
                            fillColor:
                                isDark ? Colors.grey.shade800 : Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: primary, width: 1.2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(16),
                    ),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isSending ? null : _sendRequest,
                      child: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Send Request',
                              style: GoogleFonts.lexend(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
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

  Widget _counterButton({required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        width: 32,
        decoration: BoxDecoration(
          color: const Color(0xFFE5E5EA),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.lexend(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}
