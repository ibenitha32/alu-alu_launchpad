# ALU Launchpad

Internship & opportunity matching platform connecting ALU students with verified student-led startups. Built with Flutter, Firebase (Auth + Firestore), and Riverpod.


## Getting started

1. **Create the Flutter project shell**:
   ```
   flutter create --org com.alu alu_launchpad
   ```
   Then copy this repo's `lib/`, `pubspec.yaml`, `test/`, `firebase/`, and `firebase.json` into it, overwriting the generated `lib/main.dart` and `pubspec.yaml`.

2. **Install dependencies**:
   ```
   flutter pub get
   ```

3. **Create the Firebase project** at console.firebase.google.com. Enable:
   - Authentication → Email/Password
   - Firestore Database → start in production mode (this repo ships real Security Rules, not test-mode open rules)

4. **Connect Flutter to Firebase**:
   ```
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   This generates `lib/firebase_options.dart` — required by `main.dart` and not included here since it's project-specific.

5. **Deploy Firestore rules and indexes**:
   ```
   firebase deploy --only firestore:rules,firestore:indexes
   ```

6. **Run the app** on an emulator or physical device (per the assignment brief, browser-only runs aren't graded):
   ```
   flutter run
   ```

## Architecture at a glance

- **State management**: Riverpod, with `StreamProvider`s wrapping Firestore snapshots for real-time UI updates, and `AsyncNotifier`s for write actions (apply, post opportunity, verify startup) so loading/error states are handled uniformly.
- **Data layer**: abstract repository interfaces (`lib/data/repositories/`) with Firestore implementations. Every provider depends on the interface, not the Firestore class directly — see `test/fakes/fake_repositories.dart` for the payoff (unit tests with zero network calls).
- **Routing**: `go_router` with a redirect guard that sends signed-out users to `/sign-in` and routes signed-in users to the right home screen for their role (student / startup admin / platform admin).
- **The verification gate**: startups can't post opportunities until a platform admin approves them — enforced both in the UI (`dashboard_screen.dart`) and, non-negotiably, in `firebase/firestore.rules`. This is the platform's core trust mechanism and the strongest "originality" talking point for the rubric.

## Folder structure

```
lib/
  core/       theme, router, shared widgets
  data/       models + repository interfaces/implementations
  providers/  Riverpod providers wiring repositories to UI
  features/   one folder per screen area (auth, student_home, startup_dashboard, ...)
test/
  fakes/      in-memory fake repositories for testing
  data/       pure model/logic unit tests (e.g. skill-match scoring)
  providers/  controller tests using fake repositories via provider overrides
```

## Testing

```
flutter test
```

Two example suites are included to demonstrate the testing strategy for the report:
- `test/data/opportunity_match_score_test.dart` — pure logic, no mocking needed.
- `test/providers/application_controller_test.dart` — exercises the Riverpod controller layer against `FakeApplicationRepository`, proving the repository-pattern abstraction is genuinely swappable, not just architectural decoration.

Extend this pattern to `OpportunityController` and `StartupController` using the same fakes for fuller coverage before submission.

## Feature checklist (maps to rubric criteria)

- [x] Authentication & onboarding (email/password, role selection at sign-up)
- [x] Startup profiles with admin-gated verification
- [x] Opportunity posting (startup admins, once verified)
- [x] Discovery & search (category filter + text search + skill-match "Recommended" sort)
- [x] Application submission with optional cover note
- [x] Real-time updates (Firestore `StreamProvider`s throughout — application status, applicant lists, verification queue)
- [x] Firebase backend (Firestore + Auth, Security Rules enforcing the verification gate)
- [x] State management across screens (Riverpod)
- [x] Beyond-minimum: skill-match scoring, in-app notifications, application status timeline, startup verification queue

## Known limitations / suggested future work

*(Use this section as a starting point for the report's "Limitations and Future Improvements" — expand with anything your group changes.)*

- No push notifications (FCM) — in-app Firestore-backed notifications only, to keep setup risk low for a formative timeline.
- No chat/messaging between students and startups — flagged as scope risk in the architecture doc; a natural v2 feature.
- Skill matching is exact-string overlap, not semantic — a v2 could stem/normalize skill names or use a small taxonomy.
- No automated CI — `flutter test` is run manually; adding GitHub Actions would strengthen the "maintainability" story.

## Submission

Final Canvas submission: the GitHub repo link, a 7–10 minute demo video, and the technical report, named `BenithaIradukunda_FinalFlutterProject`.
