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
  bool _busy = false;

  @override
  void dispose() {
    _noteController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final data = widget.userData;
    final isVerified = data['verified'] == true;
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
                  backgroundColor:
                      isVerified ? Colors.green.shade50 : Colors.orange.shade50,
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
}
