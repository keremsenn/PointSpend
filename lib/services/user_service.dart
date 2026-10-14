import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/firestore_collections.dart';
import '../models/user_profile.dart';

class UserService {
  final FirebaseFirestore _firestore;

  UserService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection(FirestoreCollections.users);

  Future<void> createUser(UserProfile user) async {
    await _usersCollection.doc(user.id).set(user.toMap());
  }

  Future<UserProfile?> getUser(String userId) async {
    try {
      final snapshot = await _usersCollection.doc(userId).get();
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return UserProfile.fromMap(snapshot.data()!);
    } catch (_) {
      return null;
    }
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    await _usersCollection.doc(userId).update(data);
  }

  Stream<UserProfile> watchUser(String userId) {
    return _usersCollection.doc(userId).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return UserProfile(
          id: userId,
          name: 'Kullanıcı',
          email: 'kullanici@pointspend.app',
          totalPoints: 1250,
          proStatus: false,
          tier: 'Free',
          profileStatus: 'active',
          createdAt: DateTime.now(),
        );
      }
      return UserProfile.fromMap(snapshot.data()!);
    });
  }
}
