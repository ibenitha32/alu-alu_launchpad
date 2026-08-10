# ALU Launchpad

Internship & opportunity matching platform connecting ALU students with verified student-led startups. Built with Flutter, Firebase (Auth + Firestore), and Riverpod.


## Getting started

1. **Clone the repo**. The Android platform folder (`android/`) is checked in, generated via `flutter create --platforms=android --org com.alu .`, so there's no need to scaffold a project shell yourself — just clone and go. (An `ios/` folder isn't included; run `flutter create --platforms=ios .` first if you need to build for iOS.)

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

## Seeding demo data

The Firestore schema is defined entirely by `lib/data/models/` and `lib/data/repositories/`,
so `scripts/seed_firestore.js` generates a large, internally-consistent, fictional dataset
directly from that schema — 200 users, 50 startups, 300 opportunities, 300 applications,
500 notifications, and 500 bookmarks — plus matching Firebase Auth accounts.

```
GOOGLE_APPLICATION_CREDENTIALS=/path/to/serviceAccountKey.json npm install
GOOGLE_APPLICATION_CREDENTIALS=/path/to/serviceAccountKey.json npm run seed:firestore
```

Get the service account key from Firebase Console → Project Settings → Service Accounts →
"Generate new private key"; save it **outside** this repo (it's gitignored as an extra
safety net, but don't rely on that). All generated IDs live under a `demo-` prefix and the
script upserts deterministically, so it's safe to re-run — it never touches, overwrites, or
deletes anything outside that namespace, and it never modifies `firebase/firestore.rules`.
Run with `DRY_RUN=1` to generate and validate the dataset in memory without touching Firebase
at all — useful for sanity-checking the generator itself. See the header comment in
`scripts/seed_firestore.js` for full details (demo password override, batching, etc).

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

## Provisioning a platform admin

`UserRole.platformAdmin` is fully supported by the router, `firebase/firestore.rules`,
and the verification-queue screen (`/admin/verification-queue`) — but there is
deliberately no in-app sign-up path for it. The security rule for `users/{uid}`
blocks a signed-in user from changing their own `role` field:

```
allow update: if isOwner(uid) &&
  request.resource.data.role == resource.data.role;
```

That's intentional: role escalation to a platform-trust role must never be a
client-side write. The only way to create a platform admin is a deliberate,
out-of-band step by whoever owns the Firebase project:

1. Have the target user sign up normally as a Student (or use an existing account) so a `users/{uid}` document exists.
2. In the [Firebase Console](https://console.firebase.google.com) → your project → **Firestore Database** → **Data**, open the `users` collection and find the document whose ID matches that user's Auth UID (visible under **Authentication** → **Users**).
3. Edit the document's `role` field from `student` to `platform_admin` and save.

This edit is made by a project Owner/Editor authenticated via the Console's own
Google-account IAM permissions, not through the client SDK — so it isn't
subject to (and doesn't need to satisfy) the client-facing security rule above.
Once saved, signing that user back into the app routes them straight to the
verification queue via the router's role-based redirect (`_homeForRole` in
`lib/core/router/app_router.dart`).

## Testing

```
flutter test
```

Two example suites are included to demonstrate the testing strategy for the report:
- `test/data/opportunity_match_score_test.dart` — pure logic, no mocking needed.
- `test/providers/application_controller_test.dart` — exercises the Riverpod controller layer against `FakeApplicationRepository`, proving the repository-pattern abstraction is genuinely swappable, not just architectural decoration.

`test/providers/opportunity_controller_test.dart` and `test/providers/startup_controller_test.dart` extend this pattern to those two controllers, and `test/providers/bookmark_controller_test.dart` covers the bookmark toggle flow — all against the same in-memory fakes.

## Feature checklist (maps to rubric criteria)

- [x] Authentication & onboarding (email/password, role selection at sign-up, student skill onboarding at `/onboarding`)
- [x] Startup profiles with admin-gated verification
- [x] Opportunity posting (startup admins, once verified), using a single shared category taxonomy (`OpportunityCategory`) for both the post form and the discovery filter
- [x] Discovery & search (category filter + text search + skill-match "Recommended" sort — skills are set during onboarding or from Profile → Skills & Interests)
- [x] Application submission with optional cover note; applicant name/skills/portfolio link are denormalized onto the application so startup admins can actually evaluate a candidate
- [x] Real-time updates (Firestore `StreamProvider`s throughout — application status, applicant lists, verification queue, notifications, bookmarks)
- [x] Firebase backend (Firestore + Auth, Security Rules enforcing the verification gate)
- [x] State management across screens (Riverpod)
- [x] Beyond-minimum: skill-match scoring, in-app notifications (status changes + verification results), bookmarking/"Saved Opportunities", application status timeline, startup verification queue

## Known limitations / suggested future work

*(Use this section as a starting point for the report's "Limitations and Future Improvements" — expand with anything your group changes.)*

- No push notifications (FCM) — in-app Firestore-backed notifications only, to keep setup risk low for a formative timeline.
- No chat/messaging between students and startups — flagged as scope risk in the architecture doc; a natural v2 feature.
- Skill matching is exact-string overlap, not semantic — a v2 could stem/normalize skill names or use a small taxonomy.
- No automated CI — `flutter test` is run manually; adding GitHub Actions would strengthen the "maintainability" story.

## Submission

Final Canvas submission: the GitHub repo link, a 7–10 minute demo video, and the technical report, named `BenithaIradukunda_FinalFlutterProject`.
