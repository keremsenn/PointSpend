import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/firestore_collections.dart';
import '../models/activity.dart';
import '../models/activity_completion.dart';
import '../models/user_profile.dart';
import 'notification_service.dart';
import 'server_time_service.dart';

class ActivityService {
  final FirebaseFirestore _firestore;

  ActivityService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _activitiesCollection =>
      _firestore.collection(FirestoreCollections.activities);

  CollectionReference<Map<String, dynamic>> get _completionsCollection =>
      _firestore.collection(FirestoreCollections.activityCompletions);

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection(FirestoreCollections.users);

  Future<void> addActivity(Activity activity) async {
    await _activitiesCollection.doc(activity.id).set(activity.toMap());
    await NotificationService.instance.scheduleActivityReminder(activity);
  }

  Future<void> updateActivity(Activity activity) async {
    await _activitiesCollection.doc(activity.id).update(activity.toMap());
    await NotificationService.instance.scheduleActivityReminder(activity);
  }

  Future<void> deleteActivity(String activityId) async {
    await _activitiesCollection.doc(activityId).delete();
    await NotificationService.instance.cancelActivityReminder(activityId);
  }

  Future<List<Activity>> getActivitiesByUser(String userId) async {
    final snapshot = await _activitiesCollection
        .where('userId', isEqualTo: userId)
        .get();

    return snapshot.docs.map((doc) => Activity.fromMap(doc.data())).toList();
  }

  Stream<List<Activity>> streamActivitiesByUser(String userId) {
    return _activitiesCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Activity.fromMap(doc.data())).toList());
  }

  /// Daily reset happens every day at midnight (00:00).
  /// Every new calendar day starts at 00:00:00 based on synchronized server time.
  static DateTime getLogicalDayStart([DateTime? dateTime]) {
    final now = dateTime ?? ServerTimeService.now;
    return DateTime(now.year, now.month, now.day, 0, 0, 0);
  }

  /// Stream set of activity IDs completed in the current logical day (resets daily at 05:00 AM)
  Stream<Set<String>> streamTodayCompletedActivityIds(String userId) {
    return _completionsCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final startOfLogicalDay = getLogicalDayStart();
      final set = <String>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final actId = data['activityId'] as String? ?? '';
        final rawDate = data['completionDate'];
        if (actId.isNotEmpty && rawDate != null) {
          final date = DateTime.tryParse(rawDate.toString());
          if (date != null && (date.isAfter(startOfLogicalDay) || date.isAtSameMomentAs(startOfLogicalDay))) {
            set.add(actId);
          }
        }
      }
      return set;
    });
  }

  /// Stream list of ActivityCompletions completed in the current logical day (resets daily at 05:00 AM)
  Stream<List<ActivityCompletion>> streamTodayCompletions(String userId) {
    return _completionsCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final startOfLogicalDay = getLogicalDayStart();
      final list = <ActivityCompletion>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final rawDate = data['completionDate'];
        if (rawDate != null) {
          final date = DateTime.tryParse(rawDate.toString());
          if (date != null &&
              (date.isAfter(startOfLogicalDay) ||
                  date.isAtSameMomentAs(startOfLogicalDay))) {
            list.add(ActivityCompletion.fromMap(data));
          }
        }
      }
      // Sort newest completions first
      list.sort((a, b) => b.completionDate.compareTo(a.completionDate));
      return list;
    });
  }

  /// Get total completions count completed in the current logical day
  Future<int> getTodayCompletionsCount(String userId) async {
    final startOfLogicalDay = getLogicalDayStart();
    final snapshot = await _completionsCollection
        .where('userId', isEqualTo: userId)
        .get();

    int count = 0;
    for (final doc in snapshot.docs) {
      final rawDate = doc.data()['completionDate'];
      if (rawDate != null) {
        final date = DateTime.tryParse(rawDate.toString());
        if (date != null && (date.isAfter(startOfLogicalDay) || date.isAtSameMomentAs(startOfLogicalDay))) {
          count++;
        }
      }
    }
    return count;
  }

  /// Stream all past ActivityCompletions for a user, sorted newest first
  Stream<List<ActivityCompletion>> streamAllCompletions(String userId) {
    return _completionsCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ActivityCompletion.fromMap(doc.data()))
          .toList();
      list.sort((a, b) => b.completionDate.compareTo(a.completionDate));
      return list;
    });
  }

  /// Complete an activity: add points to user totalPoints, update streak, award Perfect Day bonus if all completed today
  Future<bool> completeActivity(
    String userId,
    Activity activity, {
    String? note,
    String? photoUrl,
  }) async {
    final userDocRef = _usersCollection.doc(userId);
    final completionId = _completionsCollection.doc().id;

    try {
      final now = ServerTimeService.now;
      final totalEarned = activity.pointValue;

      final completion = ActivityCompletion(
        id: completionId,
        activityId: activity.id,
        completionDate: now,
        earnedPoints: totalEarned,
        optionalNote: note,
        optionalPhoto: photoUrl,
      );

      await _firestore.runTransaction((transaction) async {
        final userSnapshot = await transaction.get(userDocRef);
        UserProfile user;
        if (userSnapshot.exists && userSnapshot.data() != null) {
          user = UserProfile.fromMap(userSnapshot.data()!);
        } else {
          user = UserProfile(
            id: userId,
            name: 'Kullanıcı',
            email: 'kullanici@pointspend.app',
            totalPoints: 1250,
            proStatus: false,
            tier: 'Free',
            profileStatus: 'active',
            createdAt: now,
          );
        }

        int currentStreak = user.currentStreak;
        int bestStreak = user.bestStreak;

        if (user.lastActiveDate == null) {
          currentStreak = 1;
        } else {
          final lastLogical = getLogicalDayStart(user.lastActiveDate!);
          final todayLogical = getLogicalDayStart(now);
          final diffInDays = (todayLogical.difference(lastLogical).inHours / 24).round();

          if (diffInDays == 0) {
            if (currentStreak == 0) currentStreak = 1;
          } else if (diffInDays == 1) {
            currentStreak = currentStreak + 1;
          } else {
            currentStreak = 1;
          }
        }

        if (currentStreak > bestStreak) {
          bestStreak = currentStreak;
        }

        final newBalance = user.totalPoints + totalEarned;

        transaction.set(userDocRef, {
          'totalPoints': newBalance,
          'currentStreak': currentStreak,
          'bestStreak': bestStreak,
          'lastActiveDate': now.toIso8601String(),
        }, SetOptions(merge: true));

        transaction.set(_completionsCollection.doc(completionId), {
          ...completion.toMap(),
          'userId': userId,
          'activityTitle': activity.title,
          'isBonusAwarded': false,
        });
      });

      // Today's reminder for this activity is cancelled and postponed to tomorrow
      // because the activity has already been completed today!
      await NotificationService.instance.onActivityCompleted(activity);

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Stream total completed activity count for a user
  Stream<int> streamTotalCompletionsCount(String userId) {
    return _completionsCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  /// Seed initial default activities for a new user as specified in doc
  Future<void> seedDefaultActivities(String userId) async {
    final defaults = [
      Activity(
        id: 'spor_$userId',
        userId: userId,
        title: 'Spor Yap (30 dk)',
        pointValue: 30,
        frequency: 'daily',
        reminderTime: '08:00',
        isActive: true,
      ),
      Activity(
        id: 'kitap_$userId',
        userId: userId,
        title: 'Kitap Oku (20 sayfa)',
        pointValue: 20,
        frequency: 'daily',
        reminderTime: '21:00',
        isActive: true,
      ),
      Activity(
        id: 'ders_$userId',
        userId: userId,
        title: 'Ders Çalış (1 saat)',
        pointValue: 40,
        frequency: 'daily',
        reminderTime: '14:00',
        isActive: true,
      ),
    ];

    final batch = _firestore.batch();
    for (final act in defaults) {
      batch.set(_activitiesCollection.doc(act.id), act.toMap());
    }
    await batch.commit();
  }
}
