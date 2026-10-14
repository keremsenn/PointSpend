import '../services/server_time_service.dart';

class Reward {
  const Reward({
    required this.id,
    required this.userId,
    required this.title,
    required this.requiredPoints,
    required this.imageUrl,
    this.optionalPrice,
    this.optionalUrl,
    this.claimed = false,
    this.createdAt,
    this.claimedAt,
  });

  final String id;
  final String userId;
  final String title;
  final int requiredPoints;
  final String imageUrl;
  final double? optionalPrice;
  final String? optionalUrl;
  final bool claimed;
  final DateTime? createdAt;
  final DateTime? claimedAt;

  Reward copyWith({
    String? id,
    String? userId,
    String? title,
    int? requiredPoints,
    String? imageUrl,
    double? optionalPrice,
    String? optionalUrl,
    bool? claimed,
    DateTime? createdAt,
    DateTime? claimedAt,
  }) {
    return Reward(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      requiredPoints: requiredPoints ?? this.requiredPoints,
      imageUrl: imageUrl ?? this.imageUrl,
      optionalPrice: optionalPrice ?? this.optionalPrice,
      optionalUrl: optionalUrl ?? this.optionalUrl,
      claimed: claimed ?? this.claimed,
      createdAt: createdAt ?? this.createdAt,
      claimedAt: claimedAt ?? this.claimedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'requiredPoints': requiredPoints,
      'imageUrl': imageUrl,
      'optionalPrice': optionalPrice,
      'optionalUrl': optionalUrl,
      'claimed': claimed,
      'createdAt': (createdAt ?? ServerTimeService.now).toIso8601String(),
      'claimedAt': claimedAt?.toIso8601String(),
    };
  }

  factory Reward.fromMap(Map<String, dynamic> map) {
    int parsedPoints = 0;
    if (map['requiredPoints'] != null) {
      if (map['requiredPoints'] is num) {
        parsedPoints = (map['requiredPoints'] as num).toInt();
      } else {
        parsedPoints = int.tryParse(map['requiredPoints'].toString()) ?? 0;
      }
    }

    double? parsedPrice;
    if (map['optionalPrice'] != null) {
      if (map['optionalPrice'] is num) {
        parsedPrice = (map['optionalPrice'] as num).toDouble();
      } else {
        parsedPrice = double.tryParse(map['optionalPrice'].toString());
      }
    }

    return Reward(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      requiredPoints: parsedPoints,
      imageUrl: map['imageUrl'] as String? ?? '',
      optionalPrice: parsedPrice,
      optionalUrl: map['optionalUrl'] as String?,
      claimed: map['claimed'] as bool? ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString())
          : null,
      claimedAt: map['claimedAt'] != null
          ? DateTime.tryParse(map['claimedAt'].toString())
          : null,
    );
  }
}
