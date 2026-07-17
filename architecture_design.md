# ALU Launchpad — Architecture & Firebase Design
*(Working name — internship/opportunity matching platform for ALU startups & students)*

---

## 1. Product Framing

**Core problem this solves:** ALU has two disconnected populations — students who need real internship/project experience, and student-led startups who need cheap, motivated talent but have no formal HR pipeline to find it. Generic job boards don't work here because (a) trust matters — students won't apply to a "startup" that might just be one guy with an idea, and (b) the granularity of work is different: it's often part-time, skill-specific, unpaid-or-equity, and short-term.

**Two-sided workflow, three roles:**
- **Student** — discovers opportunities, applies, tracks status, builds a skill profile.
- **Startup Admin/Founder** — creates a verified org profile, posts opportunities, reviews applicants, manages pipeline.
- **Platform Admin (you)** — verifies startups before they're allowed to post (this is the differentiator vs. a generic CRUD board — it's what makes the platform trustworthy).

This verification gate is the single most important design decision to call out in your report — it's the thing a generic "Internships App" tutorial wouldn't have, and directly satisfies the rubric's "Product Thinking & Originality" criterion.

---

## 2. State Management Decision

**Recommendation: Riverpod (with code-gen / `riverpod_annotation`)**

Why (for your report's justification section):
- Compile-time safety over Provider (no `context.watch` typos, no runtime "ProviderNotFound" crashes).
- Testable in isolation — you can unit test notifiers without a widget tree, which matters for the "Code Quality" rubric line.
- `StreamProvider` maps directly onto Firestore's real-time snapshots — you get real-time UI updates almost for free, which hits the "real-time/dynamic updates" requirement cleanly.
- `AsyncValue` gives you loading/error/data states for free everywhere, satisfying the "properly handles loading states, invalid input, failures" rubric line without boilerplate.

Alternative if your group is more comfortable elsewhere: **BLoC** is the safer "textbook" choice if you want very explicit event→state transitions to narrate in the demo (graders love watching a BLoC diagram map to live app behavior). Either is fully justifiable — pick based on what your group can *actually explain confidently live*, since that's graded separately from the implementation itself.

---

## 3. Firestore Schema

```
users/{uid}
  ├─ role: "student" | "startup_admin" | "platform_admin"
  ├─ name, email, photoUrl
  ├─ createdAt
  ├─ (if student) skills: [string], bio, portfolioLinks: [string]
  └─ (if startup_admin) startupId: reference

startups/{startupId}
  ├─ name, logoUrl, description, sector
  ├─ verificationStatus: "pending" | "verified" | "rejected"
  ├─ verifiedBy: uid (platform_admin), verifiedAt
  ├─ ownerUid, adminUids: [uid]
  ├─ contactEmail
  └─ createdAt

opportunities/{opportunityId}
  ├─ startupId (ref), startupName, startupLogoUrl  // denormalized for list performance
  ├─ title, description, category: "dev"|"design"|"marketing"|"ops"|"research"|"content"|...
  ├─ skillsRequired: [string]
  ├─ commitment: "part-time" | "full-time" | "project-based"
  ├─ location: "remote" | "on-campus" | "hybrid"
  ├─ status: "open" | "closed" | "draft"
  ├─ postedAt, deadline
  └─ applicantCount  // denormalized counter, updated via Cloud Function or transaction

applications/{applicationId}
  ├─ opportunityId (ref), studentUid (ref)
  ├─ startupId (ref)  // denormalized, lets startup query "all applications to my org" in one query
  ├─ status: "applied" | "under_review" | "shortlisted" | "interview" | "accepted" | "rejected"
  ├─ coverNote
  ├─ appliedAt, statusUpdatedAt
  └─ statusHistory: [{status, timestamp}]  // for the timeline UI in "My Applications"

bookmarks/{uid}/items/{opportunityId}
  └─ savedAt

notifications/{uid}/items/{notificationId}
  ├─ type: "status_change" | "new_opportunity_match" | "verification_result"
  ├─ message, relatedId, read: bool, createdAt
```

**Why denormalize `startupId`/`startupName` onto `opportunities` and `applications`:** Firestore has no joins. Without denormalization, rendering a list of 20 opportunities means 20 extra reads just to show the startup name/logo. This is a scalability point worth putting directly in your report.

**Indexes you'll need:** composite index on `opportunities` (`status`, `category`, `postedAt`) for filtered discovery; composite index on `applications` (`studentUid`, `status`) for the "My Applications" tabs shown in your mockup.

---

## 4. Security Rules (sketch — put the real version in your repo)

```
match /startups/{startupId} {
  allow read: if true; // public discovery, but only show verified ones client-side/query-side
  allow create: if request.auth != null;
  allow update: if request.auth.uid in resource.data.adminUids
                 || get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == "platform_admin";
}

match /opportunities/{oppId} {
  allow read: if resource.data.status == "open" || <requester is startup owner>;
  allow write: if <requester's startupId matches, AND their startup.verificationStatus == "verified">;
}

match /applications/{appId} {
  allow create: if request.auth.uid == request.resource.data.studentUid;
  allow read, update: if request.auth.uid == resource.data.studentUid
                        || request.auth.uid in <startup's adminUids for resource.data.startupId>;
}
```

The "only verified startups can post" rule enforced **server-side in Security Rules** (not just hidden in the UI) is a strong talking point for the demo — show a Firestore write getting rejected for an unverified startup.

---

## 5. App Structure (screens, matches your sample UI)

**Student flow:** Onboarding/Auth → Home (search + recommended + categories + recent) → Opportunity Detail → Apply → My Applications (tabbed: Applied/Interview/Accepted/All) → Profile (skills, saved, notifications).

**Startup flow (not in your mockup — you'll want to design this):** Startup registration/verification request → pending-review screen → Startup Dashboard → Post Opportunity → Applicant list per opportunity → Applicant detail → status update.

**Platform admin flow:** Verification queue → approve/reject startup.

---

## 6. Suggested Flutter Folder Structure

```
lib/
  core/
    theme/           // colors, text styles — matches your purple/gradient mockup
    router/           // go_router config, route guards by role
    widgets/           // shared buttons, cards, chips (OpportunityCard, StatusPill, etc.)
    utils/
  data/
    models/            // freezed models: Opportunity, Startup, Application, AppUser
    repositories/       // FirestoreOpportunityRepository, FirestoreAuthRepository, etc.
      (interfaces here so Firebase is swappable/testable)
  features/
    auth/
      presentation/  providers/
    onboarding/
    student_home/
    opportunity_detail/
    applications/
    startup_dashboard/
    startup_verification/
    profile/
    notifications/
  main.dart
```

Repository pattern (abstract interface + Firestore implementation) is worth calling out in the report under "maintainability" — it means you could swap Firestore for another backend without touching UI/state-management code, and it makes unit testing state notifiers possible via fake repositories.

---

## 7. Beyond-minimum features worth adding (pick 2–3, don't try all)

Given your rubric rewards originality but penalizes scope creep that isn't finished:
1. **Skill-match scoring** — client-side sort of opportunities by overlap between `student.skills` and `opportunity.skillsRequired`. Cheap to build, high "product thinking" payoff.
2. **Startup verification badge + queue** — you basically need this anyway; make it visible and demo-able.
3. **Lightweight in-app notifications** (Firestore-backed, not FCM push — much less setup risk) for application status changes.

Avoid: full chat/messaging (scope risk), recommendation ML (over-engineering for a formative), analytics dashboards (unless one group member wants to own it specifically).

---

## 8. Next steps

Tell me which of these you want next and I'll build it out in full:
- Flutter model classes (freezed) + repository interfaces matching this schema
- Riverpod providers wired to Firestore streams
- The actual screen widgets from your mockup (Home, Opportunity Detail, Applications, Profile)
- The technical report outline/draft sections
