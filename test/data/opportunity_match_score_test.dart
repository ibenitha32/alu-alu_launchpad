import 'package:flutter_test/flutter_test.dart';
import 'package:alu_launchpad/data/models/opportunity.dart';

Opportunity _opportunity({required List<String> skills}) {
  return Opportunity(
    id: 'opp-1',
    startupId: 'startup-1',
    startupName: 'Learnify',
    title: 'Flutter Developer',
    description: 'Build the mobile app.',
    category: 'dev',
    skillsRequired: skills,
    postedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  group('Opportunity.matchScore', () {
    test('counts case-insensitive overlap between required and student skills', () {
      final opportunity = _opportunity(skills: ['Flutter', 'Dart', 'Firebase']);
      final score = opportunity.matchScore(['flutter', 'FIREBASE', 'Figma']);
      expect(score, 2); // Flutter + Firebase match, Figma doesn't
    });

    test('returns 0 when there is no overlap', () {
      final opportunity = _opportunity(skills: ['Flutter', 'Dart']);
      final score = opportunity.matchScore(['Photoshop', 'SEO']);
      expect(score, 0);
    });

    test('returns 0 for a student with no listed skills', () {
      final opportunity = _opportunity(skills: ['Flutter', 'Dart']);
      expect(opportunity.matchScore([]), 0);
    });

    test('does not double count duplicate required skills', () {
      final opportunity = _opportunity(skills: ['Flutter', 'flutter', 'Dart']);
      final score = opportunity.matchScore(['Flutter']);
      expect(score, 1);
    });
  });
}
