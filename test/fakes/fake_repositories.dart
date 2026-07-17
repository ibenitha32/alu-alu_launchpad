import 'dart:async';

import 'package:alu_launchpad/data/models/job_application.dart';
import 'package:alu_launchpad/data/models/opportunity.dart';
import 'package:alu_launchpad/data/models/startup.dart';
import 'package:alu_launchpad/data/repositories/application_repository.dart';
import 'package:alu_launchpad/data/repositories/opportunity_repository.dart';
import 'package:alu_launchpad/data/repositories/startup_repository.dart';

/// Broadcast stream that replays its latest value to any new listener —
/// mimics how a Firestore snapshot stream immediately emits current state.
class _ValueStream<T> {
  _ValueStream(this._value) {
    _controller.onListen = () => _controller.add(_value);
  }

  T _value;
  final _controller = StreamController<T>.broadcast();

  Stream<T> get stream => _controller.stream;

  void update(T value) {
    _value = value;
    _controller.add(value);
  }
}

/// In-memory stand-in for FirestoreOpportunityRepository. Because the state
/// layer only ever depends on the abstract OpportunityRepository, this can
/// be swapped in via ProviderContainer overrides with zero changes to
/// providers or screens — that's the whole point of the repository pattern.
class FakeOpportunityRepository implements OpportunityRepository {
  final Map<String, Opportunity> _store = {};
  late final _ValueStream<List<Opportunity>> _allStream =
      _ValueStream(_store.values.toList());
  int _idCounter = 0;

  void seed(Opportunity opportunity) {
    _store[opportunity.id] = opportunity;
    _allStream.update(_store.values.toList());
  }

  @override
  Stream<List<Opportunity>> watchOpenOpportunities({String? category}) {
    return _allStream.stream.map((list) => list
        .where((o) =>
            o.status == OpportunityStatus.open &&
            (category == null || o.category == category))
        .toList());
  }

  @override
  Stream<Opportunity?> watchOpportunity(String id) {
    return _allStream.stream.map((list) {
      for (final o in list) {
        if (o.id == id) return o;
      }
      return null;
    });
  }

  @override
  Stream<List<Opportunity>> watchStartupOpportunities(String startupId) {
    return _allStream.stream
        .map((list) => list.where((o) => o.startupId == startupId).toList());
  }

  @override
  Future<String> createOpportunity(Opportunity opportunity) async {
    final id = 'opp-${_idCounter++}';
    _store[id] = Opportunity(
      id: id,
      startupId: opportunity.startupId,
      startupName: opportunity.startupName,
      startupLogoUrl: opportunity.startupLogoUrl,
      title: opportunity.title,
      description: opportunity.description,
      category: opportunity.category,
      skillsRequired: opportunity.skillsRequired,
      commitment: opportunity.commitment,
      location: opportunity.location,
      status: opportunity.status,
      postedAt: opportunity.postedAt,
      deadline: opportunity.deadline,
    );
    _allStream.update(_store.values.toList());
    return id;
  }

  @override
  Future<void> updateOpportunity(String id, Map<String, dynamic> changes) async {
    // Not needed by current tests — extend if a test requires partial updates.
  }

  @override
  Future<void> closeOpportunity(String id) async {
    final existing = _store[id];
    if (existing == null) return;
    _store[id] = Opportunity(
      id: existing.id,
      startupId: existing.startupId,
      startupName: existing.startupName,
      title: existing.title,
      description: existing.description,
      category: existing.category,
      skillsRequired: existing.skillsRequired,
      postedAt: existing.postedAt,
      status: OpportunityStatus.closed,
    );
    _allStream.update(_store.values.toList());
  }
}

/// In-memory stand-in for FirestoreApplicationRepository. Tracks every
/// submitted application so tests can assert on exactly what was sent,
/// without touching a real (or emulated) Firestore instance.
class FakeApplicationRepository implements ApplicationRepository {
  final List<JobApplication> submittedApplications = [];
  final Map<String, JobApplication> _store = {};
  late final _ValueStream<List<JobApplication>> _allStream =
      _ValueStream(_store.values.toList());
  int _idCounter = 0;

  @override
  Stream<List<JobApplication>> watchStudentApplications(String studentUid) {
    return _allStream.stream
        .map((list) => list.where((a) => a.studentUid == studentUid).toList());
  }

  @override
  Stream<List<JobApplication>> watchOpportunityApplications(
      String opportunityId) {
    return _allStream.stream.map(
        (list) => list.where((a) => a.opportunityId == opportunityId).toList());
  }

  @override
  Future<void> submitApplication({
    required String opportunityId,
    required String studentUid,
    required String startupId,
    required String coverNote,
  }) async {
    final now = DateTime.now();
    final application = JobApplication(
      id: 'app-${_idCounter++}',
      opportunityId: opportunityId,
      studentUid: studentUid,
      startupId: startupId,
      coverNote: coverNote,
      appliedAt: now,
      statusUpdatedAt: now,
      statusHistory: [StatusEvent(status: ApplicationStatus.applied, timestamp: now)],
    );
    submittedApplications.add(application);
    _store[application.id] = application;
    _allStream.update(_store.values.toList());
  }

  @override
  Future<void> updateStatus(
      String applicationId, ApplicationStatus status) async {
    final existing = _store[applicationId];
    if (existing == null) return;
    _store[applicationId] = JobApplication(
      id: existing.id,
      opportunityId: existing.opportunityId,
      studentUid: existing.studentUid,
      startupId: existing.startupId,
      status: status,
      coverNote: existing.coverNote,
      appliedAt: existing.appliedAt,
      statusUpdatedAt: DateTime.now(),
      statusHistory: existing.statusHistory,
    );
    _allStream.update(_store.values.toList());
  }
}

/// In-memory stand-in for FirestoreStartupRepository.
class FakeStartupRepository implements StartupRepository {
  final Map<String, Startup> _store = {};
  late final _ValueStream<List<Startup>> _allStream =
      _ValueStream(_store.values.toList());
  int _idCounter = 0;

  void seed(Startup startup) {
    _store[startup.id] = startup;
    _allStream.update(_store.values.toList());
  }

  @override
  Stream<Startup?> watchStartup(String id) {
    return _allStream.stream.map((list) {
      for (final s in list) {
        if (s.id == id) return s;
      }
      return null;
    });
  }

  @override
  Stream<List<Startup>> watchPendingStartups() {
    return _allStream.stream.map((list) =>
        list.where((s) => s.verificationStatus == VerificationStatus.pending).toList());
  }

  @override
  Future<String> registerStartup(Startup startup) async {
    final id = 'startup-${_idCounter++}';
    _store[id] = Startup(
      id: id,
      name: startup.name,
      description: startup.description,
      sector: startup.sector,
      ownerUid: startup.ownerUid,
      adminUids: startup.adminUids,
      contactEmail: startup.contactEmail,
      createdAt: startup.createdAt,
    );
    _allStream.update(_store.values.toList());
    return id;
  }

  @override
  Future<void> setVerificationStatus({
    required String startupId,
    required VerificationStatus status,
    required String verifiedByUid,
  }) async {
    final existing = _store[startupId];
    if (existing == null) return;
    _store[startupId] = Startup(
      id: existing.id,
      name: existing.name,
      description: existing.description,
      sector: existing.sector,
      verificationStatus: status,
      verifiedBy: verifiedByUid,
      verifiedAt: DateTime.now(),
      ownerUid: existing.ownerUid,
      adminUids: existing.adminUids,
      contactEmail: existing.contactEmail,
      createdAt: existing.createdAt,
    );
    _allStream.update(_store.values.toList());
  }
}
