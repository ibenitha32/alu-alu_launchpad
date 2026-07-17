import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/opportunity.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class OpportunityCard extends StatelessWidget {
  const OpportunityCard({
    super.key,
    required this.opportunity,
    required this.onTap,
    this.isBookmarked = false,
    this.onBookmarkToggle,
    this.featured = false,
  });

  final Opportunity opportunity;
  final VoidCallback onTap;
  final bool isBookmarked;
  final VoidCallback? onBookmarkToggle;

  /// Featured cards use the gradient background seen in the "Recommended"
  /// section of the mockup; regular list items use a plain white card.
  final bool featured;

  @override
  Widget build(BuildContext context) {
    final textColor = featured ? Colors.white : AppColors.textPrimary;
    final subTextColor =
        featured ? Colors.white.withOpacity(0.85) : AppColors.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: featured ? AppColors.recommendedGradient : null,
          color: featured ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: featured
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _StartupLogo(opportunity: opportunity),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(opportunity.title,
                          style: AppTextStyles.cardTitle
                              .copyWith(color: textColor)),
                      const SizedBox(height: 2),
                      Text(opportunity.startupName,
                          style: AppTextStyles.caption
                              .copyWith(color: subTextColor)),
                    ],
                  ),
                ),
                InkWell(
                  onTap: onBookmarkToggle,
                  child: Icon(
                    isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...opportunity.skillsRequired.take(3).map(
                      (skill) => _Chip(label: skill, featured: featured),
                    ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _commitmentLabel(opportunity),
                  style: AppTextStyles.caption.copyWith(color: subTextColor),
                ),
                Text(
                  'Posted ${_relativeDate(opportunity.postedAt)}',
                  style: AppTextStyles.caption.copyWith(color: subTextColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StartupLogo extends StatelessWidget {
  const _StartupLogo({required this.opportunity});
  final Opportunity opportunity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: opportunity.startupLogoUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(opportunity.startupLogoUrl!,
                  fit: BoxFit.cover),
            )
          : Text(
              opportunity.startupName.isNotEmpty
                  ? opportunity.startupName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.w700),
            ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.featured});
  final String label;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: featured ? Colors.white.withOpacity(0.2) : AppColors.chipBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: featured ? Colors.white : AppColors.textPrimary,
        ),
      ),
    );
  }
}

String _commitmentLabel(Opportunity o) {
  switch (o.commitment) {
    case Commitment.partTime:
      return 'Part-time';
    case Commitment.fullTime:
      return 'Full-time';
    case Commitment.projectBased:
      return 'Project-based';
  }
}

String _relativeDate(DateTime date) {
  final days = DateTime.now().difference(date).inDays;
  if (days <= 0) return 'today';
  if (days == 1) return '1d ago';
  if (days < 7) return '${days}d ago';
  final weeks = (days / 7).floor();
  if (weeks < 4) return '${weeks}w ago';
  return DateFormat.yMMMd().format(date);
}
