import '../services/activity_service.dart';
import '../services/server_time_service.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.totalPoints,
    this.proStatus = false,
    this.tier = 'Free',
    this.profileStatus = 'active',
    required this.createdAt,
    this.proStartDate,
    this.proEndDate,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.perfectDaysCount = 0,
    this.lastActiveDate,
    this.photoUrl,
    this.hasSeenOnboarding = true,
  });

  final String id;
  final String name;
  final String email;
  final int totalPoints;
  final bool proStatus;
  final String tier;
  final String profileStatus;
  final DateTime createdAt;
  final DateTime? proStartDate;
  final DateTime? proEndDate;
  final int currentStreak;
  final int bestStreak;
  final int perfectDaysCount;
  final DateTime? lastActiveDate;
  final String? photoUrl;
  final bool hasSeenOnboarding;

  int get displayStreak {
    if (lastActiveDate == null) return 0;
    final now = ServerTimeService.now;
    final lastLogical = ActivityService.getLogicalDayStart(lastActiveDate!);
    final todayLogical = ActivityService.getLogicalDayStart(now);
    final diffInDays = (todayLogical.difference(lastLogical).inHours / 24).round();

    if (diffInDays > 1) {
      return 0; // Streak broken if more than 1 logical day missed
    }
    return currentStreak;
  }

  bool get isPro {
    if (!proStatus) return false;
    if (proEndDate != null && proEndDate!.isBefore(ServerTimeService.now)) {
      return false;
    }
    return true;
  }

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    int? totalPoints,
    bool? proStatus,
    String? tier,
    String? profileStatus,
    DateTime? createdAt,
    DateTime? proStartDate,
    DateTime? proEndDate,
    int? currentStreak,
    int? bestStreak,
    int? perfectDaysCount,
    DateTime? lastActiveDate,
    String? photoUrl,
    bool? hasSeenOnboarding,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      totalPoints: totalPoints ?? this.totalPoints,
      proStatus: proStatus ?? this.proStatus,
      tier: tier ?? this.tier,
      profileStatus: profileStatus ?? this.profileStatus,
      createdAt: createdAt ?? this.createdAt,
      proStartDate: proStartDate ?? this.proStartDate,
      proEndDate: proEndDate ?? this.proEndDate,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      perfectDaysCount: perfectDaysCount ?? this.perfectDaysCount,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      photoUrl: photoUrl ?? this.photoUrl,
      hasSeenOnboarding: hasSeenOnboarding ?? this.hasSeenOnboarding,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'totalPoints': totalPoints,
      'proStatus': proStatus,
      'tier': tier,
      'profileStatus': profileStatus,
      'createdAt': createdAt.toIso8601String(),
      'proStartDate': proStartDate?.toIso8601String(),
      'proEndDate': proEndDate?.toIso8601String(),
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
      'perfectDaysCount': perfectDaysCount,
      'lastActiveDate': lastActiveDate?.toIso8601String(),
      'photoUrl': photoUrl,
      'hasSeenOnboarding': hasSeenOnboarding,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    int parsedPoints = 0;
    if (map['totalPoints'] != null) {
      if (map['totalPoints'] is num) {
        parsedPoints = (map['totalPoints'] as num).toInt();
      } else {
        parsedPoints = int.tryParse(map['totalPoints'].toString()) ?? 0;
      }
    }

    int parsedCurrentStreak = 0;
    if (map['currentStreak'] != null) {
      if (map['currentStreak'] is num) {
        parsedCurrentStreak = (map['currentStreak'] as num).toInt();
      } else {
        parsedCurrentStreak = int.tryParse(map['currentStreak'].toString()) ?? 0;
      }
    }

    int parsedBestStreak = 0;
    if (map['bestStreak'] != null) {
      if (map['bestStreak'] is num) {
        parsedBestStreak = (map['bestStreak'] as num).toInt();
      } else {
        parsedBestStreak = int.tryParse(map['bestStreak'].toString()) ?? 0;
      }
    }

    int parsedPerfectDays = 0;
    if (map['perfectDaysCount'] != null) {
      if (map['perfectDaysCount'] is num) {
        parsedPerfectDays = (map['perfectDaysCount'] as num).toInt();
      } else {
        parsedPerfectDays = int.tryParse(map['perfectDaysCount'].toString()) ?? 0;
      }
    }

    return UserProfile(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      totalPoints: parsedPoints,
      proStatus: map['proStatus'] as bool? ?? false,
      tier: map['tier'] as String? ?? 'Free',
      profileStatus: map['profileStatus'] as String? ?? 'active',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      proStartDate: map['proStartDate'] != null
          ? DateTime.tryParse(map['proStartDate'].toString())
          : null,
      proEndDate: map['proEndDate'] != null
          ? DateTime.tryParse(map['proEndDate'].toString())
          : null,
      currentStreak: parsedCurrentStreak,
      bestStreak: parsedBestStreak,
      perfectDaysCount: parsedPerfectDays,
      lastActiveDate: map['lastActiveDate'] != null
          ? DateTime.tryParse(map['lastActiveDate'].toString())
          : null,
      photoUrl: map['photoUrl'] as String?,
      hasSeenOnboarding: map['hasSeenOnboarding'] as bool? ?? true,
    );
  }
}
