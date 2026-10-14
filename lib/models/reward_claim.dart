class RewardClaim {
  const RewardClaim({
    required this.id,
    required this.rewardId,
    required this.claimDate,
    required this.spentPoints,
  });

  final String id;
  final String rewardId;
  final DateTime claimDate;
  final int spentPoints;

  RewardClaim copyWith({
    String? id,
    String? rewardId,
    DateTime? claimDate,
    int? spentPoints,
  }) {
    return RewardClaim(
      id: id ?? this.id,
      rewardId: rewardId ?? this.rewardId,
      claimDate: claimDate ?? this.claimDate,
      spentPoints: spentPoints ?? this.spentPoints,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'rewardId': rewardId,
      'claimDate': claimDate.toIso8601String(),
      'spentPoints': spentPoints,
    };
  }

  factory RewardClaim.fromMap(Map<String, dynamic> map) {
    return RewardClaim(
      id: map['id'] as String? ?? '',
      rewardId: map['rewardId'] as String? ?? '',
      claimDate: map['claimDate'] != null
          ? DateTime.tryParse(map['claimDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      spentPoints: map['spentPoints'] as int? ?? 0,
    );
  }
}
