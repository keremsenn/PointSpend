class ActivityCompletion {
  const ActivityCompletion({
    required this.id,
    required this.activityId,
    required this.completionDate,
    required this.earnedPoints,
    this.activityTitle,
    this.optionalNote,
    this.optionalPhoto,
  });

  final String id;
  final String activityId;
  final DateTime completionDate;
  final int earnedPoints;
  final String? activityTitle;
  final String? optionalNote;
  final String? optionalPhoto;

  ActivityCompletion copyWith({
    String? id,
    String? activityId,
    DateTime? completionDate,
    int? earnedPoints,
    String? activityTitle,
    String? optionalNote,
    String? optionalPhoto,
  }) {
    return ActivityCompletion(
      id: id ?? this.id,
      activityId: activityId ?? this.activityId,
      completionDate: completionDate ?? this.completionDate,
      earnedPoints: earnedPoints ?? this.earnedPoints,
      activityTitle: activityTitle ?? this.activityTitle,
      optionalNote: optionalNote ?? this.optionalNote,
      optionalPhoto: optionalPhoto ?? this.optionalPhoto,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'activityId': activityId,
      'completionDate': completionDate.toIso8601String(),
      'earnedPoints': earnedPoints,
      'activityTitle': activityTitle,
      'optionalNote': optionalNote,
      'optionalPhoto': optionalPhoto,
    };
  }

  factory ActivityCompletion.fromMap(Map<String, dynamic> map) {
    return ActivityCompletion(
      id: map['id'] as String? ?? '',
      activityId: map['activityId'] as String? ?? '',
      completionDate: map['completionDate'] != null
          ? DateTime.tryParse(map['completionDate'].toString()) ??
                DateTime.now()
          : DateTime.now(),
      earnedPoints: map['earnedPoints'] as int? ?? 0,
      activityTitle: map['activityTitle'] as String?,
      optionalNote: map['optionalNote'] as String?,
      optionalPhoto: map['optionalPhoto'] as String?,
    );
  }
}
