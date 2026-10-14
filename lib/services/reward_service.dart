import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/firestore_collections.dart';
import '../models/reward.dart';
import '../models/reward_claim.dart';
import './server_time_service.dart';

class RewardService {
  final FirebaseFirestore _firestore;

  RewardService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _rewardsCollection =>
      _firestore.collection(FirestoreCollections.rewards);

  CollectionReference<Map<String, dynamic>> get _rewardClaimsCollection =>
      _firestore.collection(FirestoreCollections.rewardClaims);

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection(FirestoreCollections.users);

  Future<void> addReward(Reward reward) async {
    await _rewardsCollection.doc(reward.id).set(reward.toMap());
  }

  Future<void> updateReward(Reward reward) async {
    await _rewardsCollection.doc(reward.id).update(reward.toMap());
  }

  Future<void> deleteReward(String rewardId) async {
    await _rewardsCollection.doc(rewardId).delete();
  }

  Future<List<Reward>> getRewardsByUser(String userId) async {
    final snapshot = await _rewardsCollection
        .where('userId', isEqualTo: userId)
        .get();

    return snapshot.docs.map((doc) => Reward.fromMap(doc.data())).toList();
  }

  Stream<List<Reward>> streamRewardsByUser(String userId) {
    return _rewardsCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Reward.fromMap(doc.data())).toList());
  }

  /// Claim an unlocked reward: deduct points from user totalPoints and log claim history
  Future<void> claimReward(String userId, Reward reward) async {
    final userDocRef = _usersCollection.doc(userId);

    return _firestore.runTransaction((transaction) async {
      final userSnapshot = await transaction.get(userDocRef);

      int currentPoints = 1250;
      if (userSnapshot.exists && userSnapshot.data() != null) {
        currentPoints = userSnapshot.data()?['totalPoints'] as int? ?? 1250;
      } else {
        transaction.set(userDocRef, {
          'id': userId,
          'name': 'Kullanıcı',
          'email': 'kullanici@pointspend.app',
          'totalPoints': 1250,
          'proStatus': false,
          'tier': 'Free',
          'profileStatus': 'active',
          'createdAt': ServerTimeService.now.toIso8601String(),
        });
      }

      if (currentPoints < reward.requiredPoints) {
        throw Exception('Yetersiz puan! Gereken: ${reward.requiredPoints}, Mevcut: $currentPoints');
      }

      final claimId = _rewardClaimsCollection.doc().id;
      final claim = RewardClaim(
        id: claimId,
        rewardId: reward.id,
        claimDate: ServerTimeService.now,
        spentPoints: reward.requiredPoints,
      );

      final newBalance = currentPoints - reward.requiredPoints;

      // 1. Deduct points from user
      transaction.set(userDocRef, {'totalPoints': newBalance}, SetOptions(merge: true));

      // 2. Mark reward claimed
      transaction.set(_rewardsCollection.doc(reward.id), {
        'id': reward.id,
        'userId': userId,
        'title': reward.title,
        'requiredPoints': reward.requiredPoints,
        'imageUrl': reward.imageUrl,
        'optionalPrice': reward.optionalPrice,
        'claimed': true,
        'claimedAt': ServerTimeService.now.toIso8601String(),
      }, SetOptions(merge: true));

      // 3. Record claim log
      transaction.set(_rewardClaimsCollection.doc(claimId), {
        ...claim.toMap(),
        'userId': userId,
        'rewardTitle': reward.title,
      });
    });
  }

  /// Stream total claimed rewards count for a user
  Stream<int> streamTotalClaimsCount(String userId) {
    return _rewardClaimsCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  /// Seed initial default rewards for a user as specified in doc
  Future<void> seedDefaultRewards(String userId) async {
    final defaults = [
      Reward(
        id: 'kahve_$userId',
        userId: userId,
        title: 'Kahve',
        requiredPoints: 100,
        imageUrl: 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=500',
        optionalPrice: 85.0,
      ),
      Reward(
        id: 'sinema_$userId',
        userId: userId,
        title: 'Sinema Bileti',
        requiredPoints: 300,
        imageUrl: 'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=500',
        optionalPrice: 220.0,
      ),
      Reward(
        id: 'oyun_$userId',
        userId: userId,
        title: 'Yeni Oyun',
        requiredPoints: 1000,
        imageUrl: 'https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=500',
        optionalPrice: 1200.0,
      ),
    ];

    final batch = _firestore.batch();
    for (final rwd in defaults) {
      batch.set(_rewardsCollection.doc(rwd.id), rwd.toMap());
    }
    await batch.commit();
  }
}
