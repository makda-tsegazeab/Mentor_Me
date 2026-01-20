import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/admin_service.dart';
import '../theme/app_theme.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);
    final adminId = authProvider.currentUser?.uid;

    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Admin Console',
          style: GoogleFonts.lexend(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onBackground,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: StreamBuilder<List<QueryDocumentSnapshot>>(
          stream: AdminService.watchUsers(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: GoogleFonts.lexend(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade700,
                  ),
                ),
              );
            }

            final users = snapshot.data ?? [];
            if (users.isEmpty) {
              return Center(
                child: Text(
                  'No users found yet',
                  style: GoogleFonts.lexend(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onBackground,
                  ),
                ),
              );
            }

            return ListView.separated(
              itemCount: users.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final doc = users[index];
                final data = doc.data() as Map<String, dynamic>;
                return AdminUserCard(
                  userId: doc.id,
                  userData: data,
                  adminId: adminId,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class AdminUserCard extends StatefulWidget {
  const AdminUserCard({
    super.key,
    required this.userId,
    required this.userData,
    required this.adminId,
  });

  final String userId;
  final Map<String, dynamic> userData;
  final String? adminId;

  @override
  State<AdminUserCard> createState() => _AdminUserCardState();
}

class _AdminUserCardState extends State<AdminUserCard> {
  final _noteController = TextEditingController();
  final _suspensionNoteController = TextEditingController();
  bool _busy = false;
  static const List<Map<String, String>> _suspensionCodes = [
    {
      'code': 'SAFETY_HARASSMENT',
      'label': 'Safety or harassment',
      'desc': 'Threats, harassment, stalking',
    },
    {
      'code': 'FRAUD_IMPERSONATION',
      'label': 'Fraud or impersonation',
      'desc': 'Identity misuse, fake profiles',
    },
    {
      'code': 'PAYMENT_ABUSE',
      'label': 'Payment abuse',
      'desc': 'Chargebacks or fee evasion',
    },
    {
      'code': 'SPAM_BOT',
      'label': 'Spam or automation',
      'desc': 'Spam, bots, scraping',
    },
    {
      'code': 'NO_SHOWS',
      'label': 'Repeated no-shows',
      'desc': 'Missed sessions without notice',
    },
    {
      'code': 'POLICY_MINOR',
      'label': 'Minor policy violation',
      'desc': 'Low-impact policy issues',
    },
  ];

  String _selectedSuspensionCode = _suspensionCodes.first['code']!;
  int _harmScore = 0;
  int _intentScore = 0;
  int _frequencyScore = 0;
  int _evidenceScore = 0;

  @override
  void initState() {
    super.initState();
    final code = widget.userData['suspensionCode'];
    if (code is String &&
        _suspensionCodes.any((item) => item['code'] == code)) {
      _selectedSuspensionCode = code;
    }
    final rubric = widget.userData['suspensionRubric'];
    if (rubric is Map) {
      _harmScore = _parseRubricValue(rubric['harm']);
      _intentScore = _parseRubricValue(rubric['intent']);
      _frequencyScore = _parseRubricValue(rubric['frequency']);
      _evidenceScore = _parseRubricValue(rubric['evidence']);
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _suspensionNoteController.dispose();
    super.dispose();
  }

  Future<void> _updateVerification(bool nextValue) async {
    if (widget.adminId == null) return;
    setState(() => _busy = true);
    try {
      await AdminService.updateVerification(
        userId: widget.userId,
        adminId: widget.adminId!,
        verified: nextValue,
        note: _noteController.text.trim(),
      );
      _noteController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              nextValue ? 'User verified' : 'User unverified',
              style: GoogleFonts.lexend(),
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update verification: $error',
              style: GoogleFonts.lexend(),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _updateSuspension(bool nextValue) async {
    if (widget.adminId == null) return;
    if (nextValue && _selectedSuspensionCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Select a suspension code before suspending.',
            style: GoogleFonts.lexend(),
          ),
        ),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await AdminService.updateSuspension(
        userId: widget.userId,
        adminId: widget.adminId!,
        suspended: nextValue,
        note: _suspensionNoteController.text.trim(),
        code: _selectedSuspensionCode,
        score: _rubricScore,
        level: _severityLevelValue,
        rubric: {
          'harm': _harmScore,
          'intent': _intentScore,
          'frequency': _frequencyScore,
          'evidence': _evidenceScore,
        },
      );
      _suspensionNoteController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              nextValue ? 'User suspended' : 'User reinstated',
              style: GoogleFonts.lexend(),
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update suspension: $error',
              style: GoogleFonts.lexend(),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.userData;
    final isVerified = data['verified'] == true;
    final isSuspended = data['suspended'] == true;
    final role = (data['role'] ?? 'student').toString();
    final createdAt = data['createdAt'] as Timestamp?;
    final formattedDate = createdAt != null
        ? DateFormat('MMM d, yyyy • h:mm a').format(createdAt.toDate())
        : 'Unknown signup date';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Theme.of(context).cardColor,
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.shade50,
                  child: Text(
                    data['name']?.toString().substring(0, 1).toUpperCase() ??
                        '',
                    style: GoogleFonts.lexend(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['name'] ?? 'Unnamed user',
                        style: GoogleFonts.lexend(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        data['email'] ?? 'No email',
                        style: GoogleFonts.lexend(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    Chip(
                      label: Text(
                        isVerified ? 'Verified' : 'Unverified',
                        style: GoogleFonts.lexend(
                          fontWeight: FontWeight.w600,
                          color: isVerified
                              ? Colors.green.shade700
                              : Colors.orange.shade800,
                        ),
                      ),
                      backgroundColor: isVerified
                          ? Colors.green.shade50
                          : Colors.orange.shade50,
                    ),
                    Chip(
                      label: Text(
                        isSuspended ? 'Suspended' : 'Active',
                        style: GoogleFonts.lexend(
                          fontWeight: FontWeight.w600,
                          color: isSuspended
                              ? Colors.red.shade700
                              : Colors.blue.shade700,
                        ),
                      ),
                      backgroundColor: isSuspended
                          ? Colors.red.shade50
                          : Colors.blue.shade50,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Role: ${role[0].toUpperCase()}${role.substring(1)} • $formattedDate',
              style: GoogleFonts.lexend(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              maxLines: 1,
              decoration: InputDecoration(
                hintText: 'Optional verification note',
                hintStyle: GoogleFonts.lexend(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _suspensionNoteController,
              maxLines: 1,
              decoration: InputDecoration(
                hintText: 'Optional suspension note',
                hintStyle: GoogleFonts.lexend(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Suspension rubric',
              style: GoogleFonts.lexend(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedSuspensionCode,
              decoration: InputDecoration(
                hintText: 'Select suspension code',
                hintStyle: GoogleFonts.lexend(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
              items: _suspensionCodes
                  .map(
                    (code) => DropdownMenuItem(
                      value: code['code'],
                      child: Text(
                        '${code['label']}',
                        style: GoogleFonts.lexend(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _selectedSuspensionCode = value);
              },
            ),
            const SizedBox(height: 6),
            Text(
              _selectedCodeDescription,
              style: GoogleFonts.lexend(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _scoreDropdown(
                  label: 'Harm risk',
                  value: _harmScore,
                  onChanged: (v) => setState(() => _harmScore = v),
                ),
                _scoreDropdown(
                  label: 'Intent',
                  value: _intentScore,
                  onChanged: (v) => setState(() => _intentScore = v),
                ),
                _scoreDropdown(
                  label: 'Frequency',
                  value: _frequencyScore,
                  onChanged: (v) => setState(() => _frequencyScore = v),
                ),
                _scoreDropdown(
                  label: 'Evidence',
                  value: _evidenceScore,
                  onChanged: (v) => setState(() => _evidenceScore = v),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Score: $_rubricScore (0-8)',
                    style: GoogleFonts.lexend(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                Text(
                  _severityLabel,
                  style: GoogleFonts.lexend(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _severityColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _busy || widget.adminId == null
                        ? null
                        : () => _updateVerification(!isVerified),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isVerified
                          ? Colors.grey.shade600
                          : Colors.blue.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isVerified ? 'Revoke verification' : 'Verify user',
                      style: GoogleFonts.lexend(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                if (widget.adminId == null)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(Icons.lock_outline, size: 20),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _busy || widget.adminId == null
                        ? null
                        : () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(
                                  isSuspended
                                      ? 'Reinstate user?'
                                      : 'Suspend user?',
                                ),
                                content: Text(
                                  isSuspended
                                      ? 'This will restore access to the app.'
                                      : 'This will block the user from logging in.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(ctx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: Text(
                                      isSuspended ? 'Reinstate' : 'Suspend',
                                    ),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await _updateSuspension(!isSuspended);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSuspended
                          ? Colors.green.shade700
                          : Colors.red.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isSuspended ? 'Reinstate user' : 'Suspend user',
                      style: GoogleFonts.lexend(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                if (widget.adminId == null)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(Icons.lock_outline, size: 20),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<QueryDocumentSnapshot>>(
              stream: AdminService.watchVerificationHistory(widget.userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LinearProgressIndicator();
                }
                final history = snapshot.data ?? [];
                if (history.isEmpty) {
                  return Text(
                    'No verification history yet',
                    style: GoogleFonts.lexend(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade500,
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: history.map((doc) {
                    final item = doc.data() as Map<String, dynamic>;
                    final verifiedEntry = item['verified'] == true;
                    final timestamp = item['createdAt'] as Timestamp?;
                    final timeLabel = timestamp != null
                        ? DateFormat('MMM d, yyyy h:mm a')
                            .format(timestamp.toDate())
                        : 'Unknown time';
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        verifiedEntry ? Icons.verified : Icons.cancel,
                        color: verifiedEntry ? Colors.green : Colors.orange,
                        size: 20,
                      ),
                      title: Text(
                        verifiedEntry ? 'Marked verified' : 'Marked unverified',
                        style: GoogleFonts.lexend(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        '${item['adminId'] ?? 'Admin'} • $timeLabel',
                        style: GoogleFonts.lexend(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      trailing: Text(
                        item['note']?.toString() ?? '',
                        style: GoogleFonts.lexend(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  int get _rubricScore =>
      _harmScore + _intentScore + _frequencyScore + _evidenceScore;

  String get _severityLabel {
    if (_rubricScore <= 2) return 'Warning';
    if (_rubricScore <= 5) return 'Temporary (24-72h)';
    if (_rubricScore <= 7) return 'Extended (7-30d)';
    return 'Permanent or review hold';
  }

  String get _severityLevelValue {
    if (_rubricScore <= 2) return 'warning';
    if (_rubricScore <= 5) return 'temporary';
    if (_rubricScore <= 7) return 'extended';
    return 'permanent';
  }

  Color get _severityColor {
    if (_rubricScore <= 2) return Colors.green.shade700;
    if (_rubricScore <= 5) return Colors.orange.shade700;
    if (_rubricScore <= 7) return Colors.deepOrange.shade700;
    return Colors.red.shade700;
  }

  String get _selectedCodeDescription {
    final match = _suspensionCodes.firstWhere(
      (item) => item['code'] == _selectedSuspensionCode,
      orElse: () => _suspensionCodes.first,
    );
    return match['desc'] ?? '';
  }

  Widget _scoreDropdown({
    required String label,
    required int value,
    required void Function(int) onChanged,
  }) {
    return SizedBox(
      width: 160,
      child: DropdownButtonFormField<int>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.lexend(fontSize: 12),
          isDense: true,
        ),
        items: const [
          DropdownMenuItem(value: 0, child: Text('0')),
          DropdownMenuItem(value: 1, child: Text('1')),
          DropdownMenuItem(value: 2, child: Text('2')),
        ],
        onChanged: (v) {
          if (v == null) return;
          onChanged(v);
        },
      ),
    );
  }

  int _parseRubricValue(dynamic value) {
    if (value is int) return value.clamp(0, 2).toInt();
    if (value is num) return value.toInt().clamp(0, 2).toInt();
    return 0;
  }
}
