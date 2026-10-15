import '../services/server_time_service.dart';

class Activity {
  const Activity({
    required this.id,
    required this.userId,
    required this.title,
    required this.pointValue,
    required this.frequency,
    required this.reminderTime,
    required this.isActive,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String title;
  final int pointValue;
  final String frequency;
  final String reminderTime;
  final bool isActive;
  final DateTime? createdAt;

  Activity copyWith({
    String? id,
    String? userId,
    String? title,
    int? pointValue,
    String? frequency,
    String? reminderTime,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Activity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      pointValue: pointValue ?? this.pointValue,
      frequency: frequency ?? this.frequency,
      reminderTime: reminderTime ?? this.reminderTime,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'pointValue': pointValue,
      'frequency': frequency,
      'reminderTime': reminderTime,
      'isActive': isActive,
      'createdAt': (createdAt ?? ServerTimeService.now).toIso8601String(),
    };
  }

  factory Activity.fromMap(Map<String, dynamic> map) {
    int parsedPoints = 0;
    if (map['pointValue'] != null) {
      if (map['pointValue'] is num) {
        parsedPoints = (map['pointValue'] as num).toInt();
      } else {
        parsedPoints = int.tryParse(map['pointValue'].toString()) ?? 0;
      }
    }

    return Activity(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      pointValue: parsedPoints,
      frequency: map['frequency'] as String? ?? 'daily',
      reminderTime: map['reminderTime'] as String? ?? '09:00',
      isActive: map['isActive'] as bool? ?? true,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString())
          : null,
    );
  }

  String get frequencyLabel {
    switch (frequency) {
      case 'weekly':
        return 'Haftada Bir';
      case 'once':
      case 'optional':
        return 'Yalnızca Bir Kez';
      case 'daily':
      default:
        return 'Her Gün';
    }
  }
}

class ActivityStatus {
  const ActivityStatus({
    required this.isCompleted,
    required this.isAvailable,
    required this.statusText,
    required this.frequencyLabel,
    this.nextAvailableDate,
  });

  final bool isCompleted;
  final bool isAvailable;
  final String statusText;
  final String frequencyLabel;
  final DateTime? nextAvailableDate;
}
