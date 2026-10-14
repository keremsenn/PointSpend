import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/activity.dart';
import '../models/app_notification.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling a background message: ${message.messageId}');
}

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  factory NotificationService() => instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _notifCollection(String userId) =>
      _db.collection('users').doc(userId).collection('notifications');

  Future<void> initialize() async {
    // 1. Request notification permission (Firebase Messaging)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('Notification permission granted.');
    }

    // 2. Enable foreground notification options for FCM
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 3. Initialize timezone and local notifications
    try {
      tz.initializeTimeZones();
      final offsetMs = DateTime.now().timeZoneOffset.inMilliseconds;
      for (final loc in tz.timeZoneDatabase.locations.values) {
        if (loc.currentTimeZone.offset == offsetMs) {
          tz.setLocalLocation(loc);
          break;
        }
      }
    } catch (e) {
      debugPrint('Timezone initialization error: $e');
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(settings: initSettings);

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();

    // Clean up previous channel to ensure channel settings (Importance.max) are applied
    try {
      await androidPlugin?.deleteNotificationChannel(channelId: 'activity_reminders');
    } catch (_) {}

    // Create max-importance reminder channel on Android for heads-up top banners
    const androidChannel = AndroidNotificationChannel(
      'activity_reminders_v2',
      'Aktivite Hatırlatıcıları',
      description: 'Günlük aktivite ve alışkanlık hatırlatıcı bildirimleri',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );
    await androidPlugin?.createNotificationChannel(androidChannel);

    // 4. Set FCM background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 5. Handle FCM foreground notifications & save to Firestore in-app list
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null && !kIsWeb) {
        _localNotifications.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'PointSpend Bildirimleri',
              channelDescription: 'Seri ve ödül bildirimleri',
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );

        // Save incoming Firebase Messaging notification to Firestore for the logged-in user
        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
        if (currentUserId != null && currentUserId.isNotEmpty) {
          addNotification(
            userId: currentUserId,
            title: notification.title ?? 'Yeni Bildirim',
            body: notification.body ?? '',
            type: 'general',
          );
        }
      }
    });

    // 6. Log FCM Token for Firebase Messaging console push testing
    try {
      final token = await _fcm.getToken();
      debugPrint('\n==================================================');
      debugPrint('🔥 FCM TEST TOKEN: $token');
      debugPrint('==================================================\n');
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }
  }

  // --- Firestore In-App Notifications Management ---

  /// Adds a new notification for the user in Firestore
  Future<void> addNotification({
    required String userId,
    required String title,
    required String body,
    String type = 'general',
  }) async {
    final docRef = _notifCollection(userId).doc();
    final notif = AppNotification(
      id: docRef.id,
      userId: userId,
      title: title,
      body: body,
      createdAt: DateTime.now(),
      isRead: false,
      type: type,
    );
    await docRef.set(notif.toMap());
  }

  /// Stream of all notifications for the user, newest first
  Stream<List<AppNotification>> watchNotifications(String userId) {
    return _notifCollection(userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => AppNotification.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Stream of unread count for badge display
  Stream<int> watchUnreadCount(String userId) {
    return _notifCollection(userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  /// Mark a single notification as read
  Future<void> markAsRead(String userId, String notificationId) async {
    await _notifCollection(userId).doc(notificationId).update({'isRead': true});
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    final unread = await _notifCollection(userId)
        .where('isRead', isEqualTo: false)
        .get();
    final batch = _db.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  /// Delete a notification
  Future<void> deleteNotification(String userId, String notificationId) async {
    await _notifCollection(userId).doc(notificationId).delete();
  }

  // --- Activity Reminders (Local Notifications) ---

  int _notificationIdForActivity(String activityId) {
    return activityId.hashCode.abs() % 2147483647;
  }

  /// Schedule or update a daily reminder for an activity.
  /// If [isCompletedToday] is true, the reminder is cancelled completely.
  Future<void> scheduleActivityReminder(
    Activity activity, {
    bool isCompletedToday = false,
  }) async {
    final notifId = _notificationIdForActivity(activity.id);

    // If completed today, cancel reminder completely so it will NOT ring!
    if (isCompletedToday) {
      await cancelActivityReminder(activity.id);
      return;
    }

    final rawTime = activity.reminderTime.trim();
    if (rawTime.isEmpty || !rawTime.contains(':')) {
      await cancelActivityReminder(activity.id);
      return;
    }

    final parts = rawTime.split(':');
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) {
      await cancelActivityReminder(activity.id);
      return;
    }

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduled.isBefore(now)) {
      // Time has already passed today: schedule for tomorrow
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'activity_reminders_v2',
        'Aktivite Hatırlatıcıları',
        channelDescription: 'Günlük aktivite ve alışkanlık hatırlatıcı bildirimleri',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
        visibility: NotificationVisibility.public,
        category: AndroidNotificationCategory.reminder,
        icon: '@mipmap/ic_launcher',
      ),
    );

    try {
      await _localNotifications.zonedSchedule(
        id: notifId,
        title: '🔔 ${activity.title}',
        body: '"${activity.title}" vaktin geldi! Tamamla ve +${activity.pointValue} Puan kazan. 🔥',
        scheduledDate: scheduled,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      if (kDebugMode) {
        print('Scheduled exact reminder for "${activity.title}" at $scheduled (ID: $notifId)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Exact alarm failed ($e), falling back to inexactAllowWhileIdle...');
      }
      try {
        await _localNotifications.zonedSchedule(
          id: notifId,
          title: '🔔 ${activity.title}',
          body: '"${activity.title}" vaktin geldi! Tamamla ve +${activity.pointValue} Puan kazan. 🔥',
          scheduledDate: scheduled,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } catch (err) {
        if (kDebugMode) print('Error scheduling reminder for ${activity.title}: $err');
      }
    }
  }

  /// Cancels an activity's scheduled reminder completely
  Future<void> cancelActivityReminder(String activityId) async {
    final notifId = _notificationIdForActivity(activityId);
    await _localNotifications.cancel(id: notifId);
    if (kDebugMode) print('Cancelled reminder for activity $activityId (ID: $notifId)');
  }

  /// Called immediately when an activity is completed:
  /// Cancels the reminder so completed activities do not notify!
  Future<void> onActivityCompleted(Activity activity) async {
    await cancelActivityReminder(activity.id);
  }

  /// Syncs reminders for all user activities given the set of today's completed IDs
  Future<void> syncAllActivityReminders(
    List<Activity> activities,
    Set<String> completedTodayIds,
  ) async {
    for (final act in activities) {
      final isCompleted = completedTodayIds.contains(act.id);
      if (isCompleted) {
        await cancelActivityReminder(act.id);
      } else {
        await scheduleActivityReminder(act, isCompletedToday: false);
      }
    }
  }
}
