import 'package:flutter/material.dart';

import '../../data/models/job_application.dart';
import '../theme/app_colors.dart';

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status});

  final ApplicationStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, label) = _styleFor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  (Color, String) _styleFor(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.applied:
        return (AppColors.info, 'Applied');
      case ApplicationStatus.underReview:
        return (AppColors.warning, 'Under Review');
      case ApplicationStatus.shortlisted:
        return (AppColors.warning, 'Shortlisted');
      case ApplicationStatus.interview:
        return (AppColors.accentOrange, 'Interview');
      case ApplicationStatus.accepted:
        return (AppColors.success, 'Accepted');
      case ApplicationStatus.rejected:
        return (AppColors.neutral, 'Closed');
    }
  }
}
