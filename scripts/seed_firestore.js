#!/usr/bin/env node
/**
 * ALU Launchpad — Firestore + Firebase Auth demo/dev seed script.
 *
 * Populates a large, internally-consistent, fictional dataset that mirrors
 * the exact schema the Flutter app reads and writes (see lib/data/models/,
 * lib/data/repositories/, and firebase/firestore.rules). This is a dev/demo
 * data generator, not a migration — it never touches Security Rules.
 *
 * Usage:
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/to/serviceAccountKey.json \
 *   npm run seed:firestore
 *
 * Targets the "alu-launchpad-2026" Firebase project (hardcoded below) via
 * Application Default Credentials — nothing here is committed to the repo:
 *   1. In the Firebase Console for that project, go to Project Settings →
 *      Service Accounts → "Generate new private key". Save the JSON
 *      somewhere OUTSIDE this repo. (Alternatively, run
 *      `gcloud auth application-default login` once instead of a key file.)
 *   2. Set GOOGLE_APPLICATION_CREDENTIALS to that file's path.
 *   3. Optionally set SEED_DEMO_PASSWORD to the password every generated
 *      demo Auth account should share. If unset, a clearly-labelled
 *      placeholder is used — DEMO ACCOUNTS ONLY, never reuse it for a real
 *      account, and treat it as public once you've printed/shared it.
 *
 * Design notes:
 *   - All IDs are deterministic ("demo-user-0001", "demo-startup-0007", …)
 *     and generated from a fixed PRNG seed, so re-running the script
 *     upserts the exact same documents instead of creating duplicates.
 *     Nothing outside the "demo-" ID namespace is ever read, written, or
 *     deleted, so unrelated data is never touched.
 *   - Firebase Auth accounts are created with the SAME uid as the
 *     corresponding users/{uid} Firestore document (via getAuth(app)
 *     .createUser({ uid, ... })), matching how FirebaseAuthRepository
 *     expects auth uid and Firestore doc id to be the same value. Re-runs
 *     skip auth users that already exist instead of resetting them.
 *   - Firestore writes go through chunked batched writes stayed comfortably
 *     under the 500-operation batch limit.
 *   - Business invariants the app itself enforces are respected even though
 *     the Admin SDK bypasses Security Rules: opportunities are only
 *     generated under verified startups, applications reference real
 *     students/opportunities, applicantCount matches the actual generated
 *     applications, bookmark doc IDs equal the opportunity ID (matching
 *     FirestoreBookmarkRepository.toggleBookmark), and notification types
 *     match the two the app actually emits ('status_change',
 *     'verification_result').
 *
 * Run with DRY_RUN=1 to generate + validate the dataset in memory and print
 * the totals WITHOUT touching Firebase Auth or Firestore — useful to sanity
 * check the generator itself.
 */

"use strict";

// ---------------------------------------------------------------------
// Config
// ---------------------------------------------------------------------

const SEED = 20260810; // fixed PRNG seed -> deterministic, reproducible dataset
const NOW = new Date();

const USERS_TOTAL = 200;
const STARTUPS_TOTAL = 50;
const OPPORTUNITIES_TOTAL = 300;
const APPLICATIONS_TOTAL = 300;
const NOTIFICATIONS_TOTAL = 500;
const BOOKMARKS_TOTAL = 500;

const PLATFORM_ADMIN_COUNT = 3;

const BATCH_SIZE = 400; // comfortably under Firestore's 500-op batch limit
const AUTH_CONCURRENCY = 10; // parallel getAuth(app).createUser() calls

const DEMO_PASSWORD = process.env.SEED_DEMO_PASSWORD || "DemoPass!2026";
const DRY_RUN = process.env.DRY_RUN === "1";

// ---------------------------------------------------------------------
// Deterministic PRNG (mulberry32) — same seed -> same dataset every run.
// ---------------------------------------------------------------------

function mulberry32(seed) {
  let a = seed >>> 0;
  return function rand() {
    a |= 0;
    a = (a + 0x6d2b79f5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}
const rng = mulberry32(SEED);

function randInt(min, max) {
  return Math.floor(rng() * (max - min + 1)) + min;
}
function pick(arr) {
  return arr[randInt(0, arr.length - 1)];
}
function pickMany(arr, n) {
  const copy = arr.slice();
  const out = [];
  const count = Math.min(n, copy.length);
  for (let i = 0; i < count; i++) {
    out.push(copy.splice(randInt(0, copy.length - 1), 1)[0]);
  }
  return out;
}
function chance(p) {
  return rng() < p;
}
function pad(n, width) {
  return String(n).padStart(width, "0");
}
function daysAgo(d) {
  return new Date(NOW.getTime() - d * 24 * 3600 * 1000);
}
function addDays(date, d) {
  const t = new Date(date.getTime() + d * 24 * 3600 * 1000);
  return t > NOW ? new Date(NOW) : t;
}

// ---------------------------------------------------------------------
// Fictional data pools (demo identities only — no real people).
// ---------------------------------------------------------------------

const FIRST_NAMES = [
  "Aline", "Eric", "Grace", "Kevin", "Diane", "Patrick", "Yvonne", "Emmanuel",
  "Claudine", "Alain", "Josiane", "Olivier", "Sandrine", "Fabrice", "Nadia",
  "Christian", "Vanessa", "Herve", "Solange", "Desire", "Aisha", "Junior",
  "Divine", "Blaise", "Chantal", "Yves", "Marie", "Elias", "Pauline", "Samuel",
  "Fiona", "Daniel", "Rita", "Moses", "Grace-Ella", "Thierry", "Belinda",
  "Innocent", "Karen", "Leon", "Mariam", "Nathan", "Odette", "Prosper",
  "Queenta", "Robert", "Stella", "Tobias", "Ursula", "Victor",
];
const LAST_NAMES = [
  "Uwimana", "Mugisha", "Niyonzima", "Habimana", "Iradukunda", "Ndayisenga",
  "Mukamana", "Nkurunziza", "Byiringiro", "Ishimwe", "Kayitesi", "Munyaneza",
  "Uwase", "Bizimana", "Nsengimana", "Twizeyimana", "Mahoro", "Ntwari",
  "Kwizera", "Rukundo", "Abatoni", "Adeyemi", "Achieng", "Wanjiru", "Okoye",
  "Mensah", "Diallo", "Osei", "Banda", "Chukwu", "Owusu", "Tesfaye",
  "Abebe", "Karenzi", "Musoni", "Rwema", "Gatete", "Mbabazi", "Nyirahabimana",
  "Sibomana",
];

const SECTORS = [
  "Fintech", "EdTech", "HealthTech", "AgriTech", "Logistics", "Climate Tech",
  "Media & Entertainment", "E-commerce", "Gaming", "SaaS / Productivity",
  "Clean Energy", "Mobility", "InsurTech", "PropTech", "Social Impact",
];
const STARTUP_PREFIXES = [
  "Nova", "Terra", "Vertex", "Bright", "Zenith", "Kado", "Loop", "Amara",
  "Umoja", "Kito", "Savanna", "Ridge", "Delta", "Solstice", "Harbor",
  "Impala", "Ubora", "Nexus", "Waza", "Fable",
];
const STARTUP_SUFFIXES = [
  "Labs", "Works", "Hub", "Collective", "Technologies", "Ventures",
  "Studio", "Systems", "Group", "Networks",
];

const SKILLS = [
  "Flutter", "Dart", "React", "Node.js", "Python", "UI/UX Design", "Figma",
  "Copywriting", "SEO", "Digital Marketing", "Data Analysis",
  "Product Management", "Graphic Design", "Video Editing", "Public Speaking",
  "Sales", "Customer Support", "Firebase", "SQL", "Machine Learning",
  "Illustration", "Social Media Management", "Business Development",
  "Financial Modeling", "Market Research", "Agile", "Excel", "Photography",
  "Kotlin", "Swift", "Community Management",
];

const CATEGORY_TITLES = {
  dev: [
    "Flutter Developer Intern", "Backend Engineering Intern",
    "Full-Stack Developer", "QA / Test Engineer Intern",
    "Mobile App Developer",
  ],
  design: [
    "UI/UX Design Intern", "Brand Designer", "Product Designer Intern",
    "Graphic Design Intern",
  ],
  marketing: [
    "Growth Marketing Intern", "Social Media Manager",
    "Content Marketing Associate", "Digital Marketing Intern",
  ],
  ops: [
    "Operations Associate", "Supply Chain Intern",
    "Business Operations Analyst", "Logistics Coordinator Intern",
  ],
  research: [
    "Research Assistant", "Market Research Analyst",
    "Data Research Intern", "Impact Research Fellow",
  ],
  content: [
    "Content Writer Intern", "Copywriter", "Video Content Creator",
    "Newsletter Editor",
  ],
};
const CATEGORIES = Object.keys(CATEGORY_TITLES);
const COMMITMENTS = ["part-time", "full-time", "project-based"];
const LOCATIONS = ["remote", "on-campus", "hybrid"];

const COVER_NOTE_TEMPLATES = [
  "I'm excited about this opportunity because it lines up directly with what I've been building in my coursework.",
  "I've been following your startup's progress and would love to contribute, especially on the technical side.",
  "This role matches my skill set closely and I'm confident I can add value from day one.",
  "I'm looking for hands-on experience in this space and think this would be a great fit for both of us.",
  "I have relevant project experience I'd love to walk you through in an interview.",
];

// ---------------------------------------------------------------------
// Users
// ---------------------------------------------------------------------

function slugify(text) {
  return text
    .toLowerCase()
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "")
    .replace(/[^a-z0-9]+/g, "");
}

function uniqueEmailFor(name, usedEmails) {
  const [first, ...rest] = name.split(" ");
  const last = rest.join("");
  const base = `${slugify(first)}.${slugify(last)}`;
  let email = `${base}@alustudent.example`;
  let n = 1;
  while (usedEmails.has(email)) {
    n += 1;
    email = `${base}${n}@alustudent.example`;
  }
  usedEmails.add(email);
  return email;
}

function makeUser({ index, role, startupId, usedEmails }) {
  const name = `${pick(FIRST_NAMES)} ${pick(LAST_NAMES)}`;
  const uid = `demo-user-${pad(index, 4)}`;
  const isStudent = role === "student";
  const skills = isStudent ? pickMany(SKILLS, randInt(2, 6)) : [];
  const portfolioLinks = isStudent
    ? pickMany(
        [
          `https://github.com/${slugify(name)}`,
          `https://behance.net/${slugify(name)}`,
          `https://${slugify(name)}.dev`,
        ],
        randInt(0, 2)
      )
    : [];
  return {
    id: uid,
    data: {
      name,
      email: uniqueEmailFor(name, usedEmails),
      photoUrl: null,
      role,
      createdAt: daysAgo(randInt(5, 240)),
      skills,
      bio: isStudent
        ? `ALU student interested in ${pick(skills.length ? skills : SKILLS).toLowerCase()} and campus opportunities.`
        : null,
      portfolioLinks,
      startupId: startupId || null,
    },
  };
}

/** Generates all users/{uid} records: platform admins, one admin per startup, and students. */
function generateUsers(startupIds) {
  const usedEmails = new Set();
  const users = [];
  let idx = 1;

  const platformAdmins = [];
  for (let i = 0; i < PLATFORM_ADMIN_COUNT; i++) {
    const u = makeUser({ index: idx++, role: "platform_admin", startupId: null, usedEmails });
    users.push(u);
    platformAdmins.push(u);
  }

  const startupAdmins = [];
  for (const startupId of startupIds) {
    const u = makeUser({ index: idx++, role: "startup_admin", startupId, usedEmails });
    users.push(u);
    startupAdmins.push(u);
  }

  const students = [];
  const remaining = USERS_TOTAL - users.length;
  for (let i = 0; i < remaining; i++) {
    const u = makeUser({ index: idx++, role: "student", startupId: null, usedEmails });
    users.push(u);
    students.push(u);
  }

  return { users, platformAdmins, startupAdmins, students };
}

// ---------------------------------------------------------------------
// Startups
// ---------------------------------------------------------------------

/** Generates bare startups/{id} records (ownerUid/adminUids/verifiedBy backfilled later). */
function generateStartups() {
  const startups = [];
  const usedNames = new Set();
  // 76% verified, 16% pending, 8% rejected -> plenty of open opportunities
  // and a non-empty verification queue for the platform-admin demo.
  const verifiedCount = Math.round(STARTUPS_TOTAL * 0.76);
  const pendingCount = Math.round(STARTUPS_TOTAL * 0.16);
  const statuses = [
    ...Array(verifiedCount).fill("verified"),
    ...Array(pendingCount).fill("pending"),
    ...Array(STARTUPS_TOTAL - verifiedCount - pendingCount).fill("rejected"),
  ];

  for (let i = 1; i <= STARTUPS_TOTAL; i++) {
    let name;
    do {
      name = `${pick(STARTUP_PREFIXES)}${pick(STARTUP_SUFFIXES)}`;
    } while (usedNames.has(name));
    usedNames.add(name);

    const sector = pick(SECTORS);
    const createdAt = daysAgo(randInt(30, 300));
    const status = statuses[i - 1];

    startups.push({
      id: `demo-startup-${pad(i, 4)}`,
      data: {
        name,
        logoUrl: null,
        description: `${name} is a student-led ${sector.toLowerCase()} startup building for the ALU community and beyond.`,
        sector,
        verificationStatus: status,
        verifiedBy: null, // backfilled
        verifiedAt: status === "pending" ? null : addDays(createdAt, randInt(2, 20)),
        ownerUid: null, // backfilled
        adminUids: [], // backfilled
        contactEmail: `hello@${slugify(name)}.example`,
        createdAt,
      },
    });
  }
  return startups;
}

// ---------------------------------------------------------------------
// Opportunities
// ---------------------------------------------------------------------

function generateOpportunities(verifiedStartups) {
  const opportunities = [];
  // status mix: 75% open (populates the student feed), 15% closed, 10% draft
  const statusPool = [
    ...Array(Math.round(OPPORTUNITIES_TOTAL * 0.75)).fill("open"),
    ...Array(Math.round(OPPORTUNITIES_TOTAL * 0.15)).fill("closed"),
  ];
  while (statusPool.length < OPPORTUNITIES_TOTAL) statusPool.push("draft");
  // pickMany without replacement over a pool already sized to TOTAL is a shuffle.
  const shuffledStatuses = pickMany(statusPool, statusPool.length);

  for (let i = 1; i <= OPPORTUNITIES_TOTAL; i++) {
    const startup = pick(verifiedStartups);
    const category = pick(CATEGORIES);
    const title = pick(CATEGORY_TITLES[category]);
    const postedAt = daysAgo(randInt(0, 90));
    const hasDeadline = chance(0.6);

    opportunities.push({
      id: `demo-opp-${pad(i, 4)}`,
      data: {
        startupId: startup.id,
        startupName: startup.data.name,
        startupLogoUrl: null,
        title,
        description: `${startup.data.name} is looking for a ${title.toLowerCase()} to join the team and help us grow in ${startup.data.sector.toLowerCase()}.`,
        category,
        skillsRequired: pickMany(SKILLS, randInt(2, 5)),
        commitment: pick(COMMITMENTS),
        location: pick(LOCATIONS),
        status: shuffledStatuses[i - 1],
        postedAt,
        deadline: hasDeadline ? addDays(postedAt, randInt(14, 60)) : null,
        applicantCount: 0, // backfilled after applications are generated
      },
    });
  }
  return opportunities;
}

// ---------------------------------------------------------------------
// Applications
// ---------------------------------------------------------------------

const STATUS_STAGES = ["applied", "under_review", "shortlisted", "interview", "accepted"];

function buildStatusHistory(finalStatus, appliedAt) {
  let stages;
  if (finalStatus === "rejected") {
    const branchPoint = randInt(1, 3); // reject after 1-3 forward stages
    stages = STATUS_STAGES.slice(0, branchPoint).concat(["rejected"]);
  } else {
    const endIdx = STATUS_STAGES.indexOf(finalStatus);
    stages = STATUS_STAGES.slice(0, endIdx + 1);
  }
  let t = new Date(appliedAt);
  const history = [];
  for (const status of stages) {
    history.push({ status, timestamp: new Date(t) });
    t = addDays(t, randInt(1, 5));
  }
  return history;
}

/** Applied -> 35%, under_review -> 25%, shortlisted -> 15%, interview -> 10%, accepted -> 8%, rejected -> 7%. */
function pickApplicationStatus() {
  const r = rng();
  if (r < 0.35) return "applied";
  if (r < 0.6) return "under_review";
  if (r < 0.75) return "shortlisted";
  if (r < 0.85) return "interview";
  if (r < 0.93) return "accepted";
  return "rejected";
}

function generateApplications(students, opportunities) {
  const eligible = opportunities.filter((o) => o.data.status !== "draft");
  const applications = [];
  const usedPairs = new Set();
  let attempts = 0;
  const maxAttempts = APPLICATIONS_TOTAL * 20;

  while (applications.length < APPLICATIONS_TOTAL && attempts < maxAttempts) {
    attempts += 1;
    const student = pick(students);
    const opportunity = pick(eligible);
    const key = `${student.id}::${opportunity.id}`;
    if (usedPairs.has(key)) continue;
    usedPairs.add(key);

    const appliedAt = addDays(opportunity.data.postedAt, randInt(0, 20));
    const status = pickApplicationStatus();
    const history = buildStatusHistory(status, appliedAt);
    const studentSkills = student.data.skills;

    applications.push({
      id: `demo-app-${pad(applications.length + 1, 4)}`,
      data: {
        opportunityId: opportunity.id,
        studentUid: student.id,
        startupId: opportunity.data.startupId,
        status,
        coverNote: pick(COVER_NOTE_TEMPLATES),
        appliedAt,
        statusUpdatedAt: history[history.length - 1].timestamp,
        statusHistory: history,
        studentName: student.data.name,
        studentSkills,
        studentPortfolioLink: student.data.portfolioLinks[0] || null,
      },
    });
  }

  if (applications.length < APPLICATIONS_TOTAL) {
    throw new Error(
      `Could only generate ${applications.length}/${APPLICATIONS_TOTAL} unique applications — ` +
        "increase the student or eligible-opportunity pool."
    );
  }
  return applications;
}

// ---------------------------------------------------------------------
// applicantCount backfill
// ---------------------------------------------------------------------

function backfillApplicantCounts(opportunities, applications) {
  const counts = new Map();
  for (const app of applications) {
    counts.set(app.data.opportunityId, (counts.get(app.data.opportunityId) || 0) + 1);
  }
  for (const opp of opportunities) {
    opp.data.applicantCount = counts.get(opp.id) || 0;
  }
}

// ---------------------------------------------------------------------
// Notifications (notifications/{uid}/items/{id})
// ---------------------------------------------------------------------

function statusLabel(status) {
  switch (status) {
    case "under_review":
      return "Under Review";
    case "shortlisted":
      return "Shortlisted";
    case "interview":
      return "Interview";
    case "accepted":
      return "Accepted";
    case "rejected":
      return "Rejected";
    default:
      return "Applied";
  }
}

function generateNotifications(applications, startups, opportunitiesById) {
  const items = []; // { uid, id, data }
  let counter = 1;
  const nextId = () => `demo-notif-${pad(counter++, 4)}`;

  // 1. status_change — one per status transition beyond the initial "applied" entry.
  for (const app of applications) {
    const history = app.data.statusHistory;
    for (let i = 1; i < history.length; i++) {
      const event = history[i];
      const opportunity = opportunitiesById.get(app.data.opportunityId);
      items.push({
        uid: app.data.studentUid,
        id: nextId(),
        data: {
          type: "status_change",
          message: `Your application for "${opportunity ? opportunity.data.title : "an opportunity"}" is now ${statusLabel(event.status)}.`,
          read: chance(0.5),
          createdAt: event.timestamp,
        },
      });
    }
  }

  // 2. verification_result — one per resolved (verified/rejected) startup, to its admin.
  for (const startup of startups) {
    if (startup.data.verificationStatus === "pending") continue;
    if (!startup.data.adminUids.length) continue;
    const label = startup.data.verificationStatus === "verified" ? "verified" : "rejected";
    items.push({
      uid: startup.data.adminUids[0],
      id: nextId(),
      data: {
        type: "verification_result",
        message: `${startup.data.name} was ${label}.`,
        read: chance(0.5),
        createdAt: startup.data.verifiedAt || startup.data.createdAt,
      },
    });
  }

  // 3. Top up (or trim) to hit NOTIFICATIONS_TOTAL exactly with plausible
  // extra activity, so the notification feed looks lived-in either way.
  const allUsers = [...new Set(applications.map((a) => a.data.studentUid))];
  const adminUids = startups.filter((s) => s.data.adminUids.length).map((s) => s.data.adminUids[0]);
  const fillerPool = [...allUsers, ...adminUids];

  while (items.length < NOTIFICATIONS_TOTAL && fillerPool.length) {
    const uid = pick(fillerPool);
    const isStudentNotif = allUsers.includes(uid);
    items.push({
      uid,
      id: nextId(),
      data: {
        type: isStudentNotif ? "status_change" : "verification_result",
        message: isStudentNotif
          ? "Your application status was updated — check My Applications for details."
          : "A verification-queue update is available for your startup.",
        read: chance(0.5),
        createdAt: daysAgo(randInt(0, 30)),
      },
    });
  }
  while (items.length > NOTIFICATIONS_TOTAL) items.pop();

  return items;
}

// ---------------------------------------------------------------------
// Bookmarks (bookmarks/{uid}/items/{opportunityId} — doc ID == opportunity ID,
// matching FirestoreBookmarkRepository.toggleBookmark exactly)
// ---------------------------------------------------------------------

function generateBookmarks(students, opportunities) {
  const eligible = opportunities.filter((o) => o.data.status !== "draft");
  const items = []; // { uid, id (=opportunityId), data }
  const usedPairs = new Set();
  let attempts = 0;
  const maxAttempts = BOOKMARKS_TOTAL * 20;

  while (items.length < BOOKMARKS_TOTAL && attempts < maxAttempts) {
    attempts += 1;
    const student = pick(students);
    const opportunity = pick(eligible);
    const key = `${student.id}::${opportunity.id}`;
    if (usedPairs.has(key)) continue;
    usedPairs.add(key);

    items.push({
      uid: student.id,
      id: opportunity.id,
      data: { bookmarkedAt: daysAgo(randInt(0, 45)) },
    });
  }
  return items;
}

// ---------------------------------------------------------------------
// Referential-integrity self-check (cheap, runs before any network call)
// ---------------------------------------------------------------------

function assertReferentialIntegrity({ users, startups, opportunities, applications, notifications, bookmarks }) {
  const userIds = new Set(users.map((u) => u.id));
  const startupIds = new Set(startups.map((s) => s.id));
  const oppIds = new Set(opportunities.map((o) => o.id));

  for (const s of startups) {
    if (s.data.ownerUid && !userIds.has(s.data.ownerUid)) throw new Error(`startup ${s.id} has unknown ownerUid`);
    for (const uid of s.data.adminUids) {
      if (!userIds.has(uid)) throw new Error(`startup ${s.id} has unknown adminUid ${uid}`);
    }
  }
  for (const o of opportunities) {
    if (!startupIds.has(o.data.startupId)) throw new Error(`opportunity ${o.id} has unknown startupId`);
  }
  for (const a of applications) {
    if (!userIds.has(a.data.studentUid)) throw new Error(`application ${a.id} has unknown studentUid`);
    if (!oppIds.has(a.data.opportunityId)) throw new Error(`application ${a.id} has unknown opportunityId`);
    if (!startupIds.has(a.data.startupId)) throw new Error(`application ${a.id} has unknown startupId`);
  }
  for (const n of notifications) {
    if (!userIds.has(n.uid)) throw new Error(`notification ${n.id} has unknown recipient uid`);
  }
  for (const b of bookmarks) {
    if (!userIds.has(b.uid)) throw new Error(`bookmark for ${b.uid}/${b.id} has unknown uid`);
    if (!oppIds.has(b.id)) throw new Error(`bookmark ${b.uid}/${b.id} references unknown opportunity`);
  }
}

// ---------------------------------------------------------------------
// Dataset assembly
// ---------------------------------------------------------------------

function buildDataset() {
  const startups = generateStartups();
  const { users, platformAdmins, startupAdmins, students } = generateUsers(startups.map((s) => s.id));

  // Backfill startup <-> admin relationships now that user uids exist.
  const startupById = new Map(startups.map((s) => [s.id, s]));
  for (const admin of startupAdmins) {
    const startup = startupById.get(admin.data.startupId);
    startup.data.ownerUid = admin.id;
    startup.data.adminUids = [admin.id];
    if (startup.data.verificationStatus !== "pending") {
      startup.data.verifiedBy = pick(platformAdmins).id;
    }
  }

  const verifiedStartups = startups.filter((s) => s.data.verificationStatus === "verified");
  const opportunities = generateOpportunities(verifiedStartups);
  const opportunitiesById = new Map(opportunities.map((o) => [o.id, o]));

  const applications = generateApplications(students, opportunities);
  backfillApplicantCounts(opportunities, applications);

  const notifications = generateNotifications(applications, startups, opportunitiesById);
  const bookmarks = generateBookmarks(students, opportunities);

  const dataset = { users, startups, opportunities, applications, notifications, bookmarks };
  assertReferentialIntegrity(dataset);
  return dataset;
}

// ---------------------------------------------------------------------
// Firebase Admin wiring (only touched outside DRY_RUN)
// ---------------------------------------------------------------------

function initAdmin() {
  // firebase-admin v12+ dropped the old admin.credential.* / admin.firestore() /
  // admin.auth() namespaced API in favor of the modular style (mirrors the JS SDK
  // v9+ split): admin.applicationDefault()/admin.cert() live on the top-level
  // module, and per-service handles come from getFirestore()/getAuth() below.
  const admin = require("firebase-admin");

  const app = admin.initializeApp({
    credential: admin.applicationDefault(),
    projectId: "alu-launchpad-2026",
  });
  return app;
}

async function ensureAuthUsers(auth, users) {
  let created = 0;
  let existing = 0;
  let failed = 0;

  for (let i = 0; i < users.length; i += AUTH_CONCURRENCY) {
    const chunk = users.slice(i, i + AUTH_CONCURRENCY);
    const results = await Promise.allSettled(
      chunk.map((u) =>
        auth.createUser({
          uid: u.id,
          email: u.data.email,
          password: DEMO_PASSWORD,
          displayName: u.data.name,
        })
      )
    );
    for (const r of results) {
      if (r.status === "fulfilled") {
        created += 1;
      } else if (r.reason && r.reason.code === "auth/uid-already-exists") {
        existing += 1;
      } else {
        failed += 1;
        console.error("  ! failed to create auth user:", r.reason && r.reason.message);
      }
    }
    console.log(`  auth users: ${Math.min(i + AUTH_CONCURRENCY, users.length)}/${users.length}`);
  }
  return { created, existing, failed };
}

async function commitInBatches(db, ops, label) {
  let written = 0;
  for (let i = 0; i < ops.length; i += BATCH_SIZE) {
    const chunk = ops.slice(i, i + BATCH_SIZE);
    const batch = db.batch();
    for (const op of chunk) batch.set(op.ref, op.data);
    await batch.commit();
    written += chunk.length;
    console.log(`  ${label}: ${written}/${ops.length}`);
  }
  return written;
}

async function writeDataset(app, dataset) {
  const { getFirestore } = require("firebase-admin/firestore");
  const { getAuth } = require("firebase-admin/auth");
  const db = getFirestore(app);
  const auth = getAuth(app);

  console.log("\nCreating Firebase Auth accounts...");
  const authResult = await ensureAuthUsers(auth, dataset.users);
  console.log(`  auth: ${authResult.created} created, ${authResult.existing} already existed, ${authResult.failed} failed`);

  console.log("\nWriting Firestore documents...");
  await commitInBatches(
    db,
    dataset.users.map((u) => ({ ref: db.collection("users").doc(u.id), data: u.data })),
    "users"
  );
  await commitInBatches(
    db,
    dataset.startups.map((s) => ({ ref: db.collection("startups").doc(s.id), data: s.data })),
    "startups"
  );
  await commitInBatches(
    db,
    dataset.opportunities.map((o) => ({ ref: db.collection("opportunities").doc(o.id), data: o.data })),
    "opportunities"
  );
  await commitInBatches(
    db,
    dataset.applications.map((a) => ({ ref: db.collection("applications").doc(a.id), data: a.data })),
    "applications"
  );
  await commitInBatches(
    db,
    dataset.notifications.map((n) => ({
      ref: db.collection("notifications").doc(n.uid).collection("items").doc(n.id),
      data: n.data,
    })),
    "notifications"
  );
  await commitInBatches(
    db,
    dataset.bookmarks.map((b) => ({
      ref: db.collection("bookmarks").doc(b.uid).collection("items").doc(b.id),
      data: b.data,
    })),
    "bookmarks"
  );
}

async function verifyCounts(app, dataset) {
  const { getFirestore, FieldPath } = require("firebase-admin/firestore");
  const db = getFirestore(app);
  console.log("\nVerifying with count() aggregation queries...");

  async function countDemo(collectionPath, idPrefix) {
    const snap = await db
      .collection(collectionPath)
      .where(FieldPath.documentId(), ">=", idPrefix)
      .where(FieldPath.documentId(), "<", idPrefix + "")
      .count()
      .get();
    return snap.data().count;
  }

  const results = {
    users: await countDemo("users", "demo-user-"),
    startups: await countDemo("startups", "demo-startup-"),
    opportunities: await countDemo("opportunities", "demo-opp-"),
    applications: await countDemo("applications", "demo-app-"),
  };

  // Subcollections are per-parent-doc, so sum a sample rather than one query;
  // spot-check a handful of recipients instead of iterating all 200 users.
  const sampleUsers = dataset.users.slice(0, 10);
  let notifSample = 0;
  let bookmarkSample = 0;
  for (const u of sampleUsers) {
    const n = await db.collection("notifications").doc(u.id).collection("items").count().get();
    const b = await db.collection("bookmarks").doc(u.id).collection("items").count().get();
    notifSample += n.data().count;
    bookmarkSample += b.data().count;
  }

  console.log("  users:", results.users, "/", USERS_TOTAL);
  console.log("  startups:", results.startups, "/", STARTUPS_TOTAL);
  console.log("  opportunities:", results.opportunities, "/", OPPORTUNITIES_TOTAL);
  console.log("  applications:", results.applications, "/", APPLICATIONS_TOTAL);
  console.log(`  notifications (sample of first 10 users): ${notifSample} docs found`);
  console.log(`  bookmarks (sample of first 10 users): ${bookmarkSample} docs found`);

  return results;
}

// ---------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------

async function main() {
  console.log("Generating in-memory dataset (deterministic, seed=" + SEED + ")...");
  const dataset = buildDataset();

  const openCount = dataset.opportunities.filter((o) => o.data.status === "open").length;
  const unreadCount = dataset.notifications.filter((n) => !n.data.read).length;

  console.log("Dataset generated:");
  console.log("  users:", dataset.users.length, `(platform_admin=${PLATFORM_ADMIN_COUNT}, startup_admin=${dataset.startups.length}, student=${dataset.users.length - PLATFORM_ADMIN_COUNT - dataset.startups.length})`);
  console.log("  startups:", dataset.startups.length, `(verified=${dataset.startups.filter((s) => s.data.verificationStatus === "verified").length}, pending=${dataset.startups.filter((s) => s.data.verificationStatus === "pending").length}, rejected=${dataset.startups.filter((s) => s.data.verificationStatus === "rejected").length})`);
  console.log("  opportunities:", dataset.opportunities.length, `(open=${openCount})`);
  console.log("  applications:", dataset.applications.length);
  console.log("  notifications:", dataset.notifications.length, `(unread=${unreadCount})`);
  console.log("  bookmarks:", dataset.bookmarks.length);

  if (DRY_RUN) {
    console.log("\nDRY_RUN=1 set — skipping Firebase Auth and Firestore writes.");
    return;
  }

  const app = initAdmin();
  await writeDataset(app, dataset);
  await verifyCounts(app, dataset);

  console.log("\nDone. Demo Auth accounts share the password set via SEED_DEMO_PASSWORD");
  console.log("(or the \"DemoPass!2026\" placeholder if that wasn't set) — for local/demo use only.");
}

main().catch((err) => {
  console.error("\nSeed failed:", err && err.stack ? err.stack : err);
  process.exitCode = 1;
});
