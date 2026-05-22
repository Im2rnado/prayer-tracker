import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../models/rules_model.dart';
import '../models/reward_model.dart';
import '../models/prayer_log_model.dart';

final databaseProvider = Provider((ref) => DatabaseService());

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Users ──────────────────────────────────────────────────────────────────

  Future<void> createUser(UserModel user) async {
    await _db.collection('users').doc(user.uid).set(user.toJson());
    if (user.role == UserRole.guardian) {
      await setRules(RulesModel(guardianId: user.uid));
    }
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromJson({...doc.data()!, 'uid': doc.id});
  }

  Stream<UserModel?> streamUser(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromJson({...doc.data()!, 'uid': doc.id});
    });
  }

  // ── Account Linking ────────────────────────────────────────────────────────

  Future<void> linkChildToGuardian(String childId, String inviteCode) async {
    // Find the guardian with this invite code
    final query = await _db
        .collection('users')
        .where('inviteCode', isEqualTo: inviteCode.toUpperCase().trim())
        .where('role', isEqualTo: 'guardian')
        .limit(1)
        .get();

    if (query.docs.isEmpty) throw Exception('Invalid invite code. Please check and try again.');

    final guardianId = query.docs.first.id;

    if (guardianId == childId) throw Exception('You cannot link to your own account.');

    final batch = _db.batch();

    // Add guardianId to child's linked list
    batch.update(_db.collection('users').doc(childId), {
      'linkedGuardianIds': FieldValue.arrayUnion([guardianId]),
    });

    // Add childId to guardian's linked list
    batch.update(_db.collection('users').doc(guardianId), {
      'linkedChildIds': FieldValue.arrayUnion([childId]),
    });

    await batch.commit();
  }

  // ── Rules ──────────────────────────────────────────────────────────────────

  Future<void> setRules(RulesModel rules) async {
    await _db
        .collection('users')
        .doc(rules.guardianId)
        .collection('rules')
        .doc('config')
        .set(rules.toJson());
  }

  Future<RulesModel> getRules(String guardianId) async {
    final doc = await _db
        .collection('users')
        .doc(guardianId)
        .collection('rules')
        .doc('config')
        .get();
    if (!doc.exists) return RulesModel(guardianId: guardianId);
    return RulesModel.fromJson(doc.data()!);
  }

  Stream<RulesModel> streamRules(String guardianId) {
    return _db
        .collection('users')
        .doc(guardianId)
        .collection('rules')
        .doc('config')
        .snapshots()
        .map((doc) {
      if (!doc.exists) return RulesModel(guardianId: guardianId);
      return RulesModel.fromJson(doc.data()!);
    });
  }

  // ── Rewards ────────────────────────────────────────────────────────────────

  Future<void> addReward(RewardModel reward) async {
    await _db
        .collection('users')
        .doc(reward.guardianId)
        .collection('rewards')
        .doc(reward.id)
        .set(reward.toJson());
  }

  Future<void> updateReward(RewardModel reward) async {
    await _db
        .collection('users')
        .doc(reward.guardianId)
        .collection('rewards')
        .doc(reward.id)
        .update(reward.toJson());
  }

  Future<void> deleteReward(String guardianId, String rewardId) async {
    await _db
        .collection('users')
        .doc(guardianId)
        .collection('rewards')
        .doc(rewardId)
        .delete();
  }

  Stream<List<RewardModel>> getGuardianRewards(String guardianId) {
    return _db
        .collection('users')
        .doc(guardianId)
        .collection('rewards')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => RewardModel.fromJson(d.data())).toList());
  }

  // ── Prayer Logs ────────────────────────────────────────────────────────────

  /// Atomically saves a prayer log AND increments the child's total points.
  Future<void> addPrayerLog(PrayerLogModel log) async {
    final batch = _db.batch();

    final logRef = _db
        .collection('users')
        .doc(log.childId)
        .collection('prayerLogs')
        .doc(log.id);
    batch.set(logRef, log.toJson());

    final userRef = _db.collection('users').doc(log.childId);
    batch.update(userRef, {
      'totalPoints': FieldValue.increment(log.pointsEarned),
    });

    await batch.commit();
  }

  Stream<List<PrayerLogModel>> getChildLogs(String childId) {
    return _db
        .collection('users')
        .doc(childId)
        .collection('prayerLogs')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => PrayerLogModel.fromJson(d.data())).toList());
  }

  // ── Leaderboard ────────────────────────────────────────────────────────────

  /// Streams all children linked to [guardianId], sorted by total points descending.
  /// Sorting is done client-side to avoid requiring a composite Firestore index.
  Stream<List<UserModel>> getLinkedChildren(String guardianId) {
    return _db
        .collection('users')
        .where('linkedGuardianIds', arrayContains: guardianId)
        .snapshots()
        .map((snap) {
      final users = snap.docs
          .map((d) => UserModel.fromJson({...d.data(), 'uid': d.id}))
          .toList();
      users.sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
      return users;
    });
  }

  // ── Rewards for Child (across all linked guardians) ────────────────────────

  /// Fetches rewards from all of the child's linked guardians.
  Future<List<RewardModel>> getChildRewards(List<String> guardianIds) async {
    if (guardianIds.isEmpty) return [];
    final futures = guardianIds.map(
      (gId) => _db.collection('users').doc(gId).collection('rewards').get(),
    );
    final results = await Future.wait(futures);
    return results
        .expand((snap) => snap.docs.map((d) => RewardModel.fromJson(d.data())))
        .toList();
  }
}
