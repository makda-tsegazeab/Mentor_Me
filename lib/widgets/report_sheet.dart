import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/report_service.dart';

class ReportSheet extends StatefulWidget {
  final String reportedUserId;
  final String reportedName;
  final String contextType;
  final String? reporterRole;
  final String? reportedRole;
  final String? relationshipId;
  final String? conversationId;

  const ReportSheet({
    super.key,
    required this.reportedUserId,
    required this.reportedName,
    required this.contextType,
    this.reporterRole,
    this.reportedRole,
    this.relationshipId,
    this.conversationId,
  });

  @override
  State<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<ReportSheet> {
  static const List<String> _reasons = [
    'Harassment',
    'Spam',
    'Inappropriate content',
    'Other',
  ];

  final _detailsController = TextEditingController();
  String? _selectedReason;
  bool _submitting = false;

  bool get _needsDetails => _selectedReason == 'Other';

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    final reporter = firebase_auth.FirebaseAuth.instance.currentUser;
    if (reporter == null) return;

    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Select a reason before submitting.')),
      );
      return;
    }

    final details = _detailsController.text.trim();
    if (_needsDetails && details.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please add a bit more detail.')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Submit report?'),
        content: Text(
          'This report will be sent to our review team.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Submit'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _submitting = true);
    try {
      final canReport =
          await ReportService.canReport(reporter.uid, widget.reportedUserId);
      if (!canReport) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'You recently reported this user. Please try again later.',
            ),
          ),
        );
        return;
      }

      await ReportService.submitReport(
        reporterId: reporter.uid,
        reportedId: widget.reportedUserId,
        reason: _selectedReason!,
        details: details,
        contextType: widget.contextType,
        reporterRole: widget.reporterRole,
        reportedRole: widget.reportedRole,
        relationshipId: widget.relationshipId,
        conversationId: widget.conversationId,
      );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Report submitted. Our team will review it.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit report: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF101922) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF111418);
    final muted =
        isDark ? Colors.grey.shade400 : const Color(0xFF617589);

    return SafeArea(
      child: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
              'Report ${widget.reportedName}',
              style: GoogleFonts.lexend(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Reports are reviewed by our team. False reports may result in account action.',
              style: GoogleFonts.lexend(
                fontSize: 13,
                color: muted,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Reason',
              style: GoogleFonts.lexend(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _reasons.map((reason) {
                final selected = reason == _selectedReason;
                return ChoiceChip(
                  label: Text(reason),
                  selected: selected,
                  onSelected: _submitting
                      ? null
                      : (value) {
                          if (!value) return;
                          setState(() => _selectedReason = reason);
                        },
                  labelStyle: GoogleFonts.lexend(
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : titleColor,
                  ),
                  selectedColor: const Color(0xFF2B8CEE),
                  backgroundColor:
                      isDark ? Colors.grey.shade800 : const Color(0xFFF0F4F8),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _detailsController,
              maxLines: 3,
              style: GoogleFonts.lexend(color: titleColor),
              decoration: InputDecoration(
                hintText: _needsDetails
                    ? 'Tell us what happened (min 10 chars)...'
                    : 'Optional details',
                hintStyle: GoogleFonts.lexend(color: muted),
                filled: true,
                fillColor: isDark
                    ? Colors.grey.shade900
                    : const Color(0xFFF6F7F8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2B8CEE),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _submitting ? 'Submitting...' : 'Submit report',
                  style: GoogleFonts.lexend(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: TextButton(
                onPressed: _submitting ? null : () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.lexend(color: muted),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
