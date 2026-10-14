import 'package:flutter/foundation.dart';
import '../models/activity.dart';
import '../models/reward.dart';
import '../services/activity_service.dart';
import '../services/reward_service.dart';
import '../services/server_time_service.dart';
import '../services/user_service.dart';

/// Abstract Payment Gateway Interface
/// Easily swap [MockPaymentGateway] with [RevenueCatPaymentGateway] or [InAppPurchasePaymentGateway] in the future!
abstract class PaymentGateway {
  Future<bool> processPayment({required String userId, required String productId});
}

/// Current Simulated/Mock Payment Gateway (1-click temporary payment flow)
class MockPaymentGateway implements PaymentGateway {
  @override
  Future<bool> processPayment({required String userId, required String productId}) async {
    // Simulate network delay for In-App Purchase / RevenueCat API response
    await Future.delayed(const Duration(milliseconds: 1200));
    if (kDebugMode) {
      print('MockPaymentGateway: Payment approved for user $userId (Product: $productId)');
    }
    return true; // Returns true for success
  }
}

class PurchaseService {
  final UserService _userService;
  final PaymentGateway _paymentGateway;

  PurchaseService({UserService? userService, PaymentGateway? paymentGateway})
      : _userService = userService ?? UserService(),
        _paymentGateway = paymentGateway ?? MockPaymentGateway();

  /// Daily Limits for Free Tier users:
  static const int freeDailyActivityAddLimit = 3;
  static const int freeDailyRewardAddLimit = 3;
  static const int freeDailyActivityCompleteLimit = 3;

  /// Check if user has active Pro subscription
  Future<bool> isUserPro(String userId) async {
    final user = await _userService.getUser(userId);
    return user?.isPro ?? false;
  }

  /// Check quota for adding an activity today
  Future<UsageQuota> checkActivityAddQuota(String userId, [List<Activity>? activities]) async {
    final pro = await isUserPro(userId);
    if (pro) {
      return const UsageQuota(
        isAllowed: true,
        isPro: true,
        usedCount: 0,
        maxLimit: -1,
        reason: 'PointSpend Pro üyesisiniz. Sınırsız aktivite ekleme hakkınız var.',
      );
    }

    final list = activities ?? await ActivityService().getActivitiesByUser(userId);
    final todayStart = ActivityService.getLogicalDayStart();
    final createdToday = list.where((a) {
      final d = a.createdAt;
      return d != null && (d.isAfter(todayStart) || d.isAtSameMomentAs(todayStart));
    }).length;

    final allowed = createdToday < freeDailyActivityAddLimit;
    return UsageQuota(
      isAllowed: allowed,
      isPro: false,
      usedCount: createdToday,
      maxLimit: freeDailyActivityAddLimit,
      reason: allowed
          ? 'Bugün kalan aktivite ekleme hakkı: ${freeDailyActivityAddLimit - createdToday}/$freeDailyActivityAddLimit'
          : 'Ücretsiz planda günde maksimum $freeDailyActivityAddLimit aktivite ekleyebilirsiniz (Her gece 00:00\'da yenilenir). Sınırsız eklemek için Pro\'ya yükseltin! ⭐',
    );
  }

  Future<bool> canAddActivity(String userId, [List<Activity>? userActivities]) async {
    final quota = await checkActivityAddQuota(userId, userActivities);
    return quota.isAllowed;
  }

  /// Check quota for adding a reward today
  Future<UsageQuota> checkRewardAddQuota(String userId, [List<Reward>? rewards]) async {
    final pro = await isUserPro(userId);
    if (pro) {
      return const UsageQuota(
        isAllowed: true,
        isPro: true,
        usedCount: 0,
        maxLimit: -1,
        reason: 'PointSpend Pro üyesisiniz. Sınırsız ödül ekleme hakkınız var.',
      );
    }

    final list = rewards ?? await RewardService().getRewardsByUser(userId);
    final todayStart = ActivityService.getLogicalDayStart();
    final createdToday = list.where((r) {
      final d = r.createdAt;
      return d != null && (d.isAfter(todayStart) || d.isAtSameMomentAs(todayStart));
    }).length;

    final allowed = createdToday < freeDailyRewardAddLimit;
    return UsageQuota(
      isAllowed: allowed,
      isPro: false,
      usedCount: createdToday,
      maxLimit: freeDailyRewardAddLimit,
      reason: allowed
          ? 'Bugün kalan ödül ekleme hakkı: ${freeDailyRewardAddLimit - createdToday}/$freeDailyRewardAddLimit'
          : 'Ücretsiz planda günde maksimum $freeDailyRewardAddLimit ödül ekleyebilirsiniz (Her gece 00:00\'da yenilenir). Sınırsız eklemek için Pro\'ya yükseltin! ⭐',
    );
  }

  Future<bool> canAddReward(String userId, [List<Reward>? userRewards]) async {
    final quota = await checkRewardAddQuota(userId, userRewards);
    return quota.isAllowed;
  }

  /// Check quota for completing an activity today
  Future<UsageQuota> checkActivityCompleteQuota(String userId) async {
    final pro = await isUserPro(userId);
    if (pro) {
      return const UsageQuota(
        isAllowed: true,
        isPro: true,
        usedCount: 0,
        maxLimit: -1,
        reason: 'PointSpend Pro üyesisiniz. Sınırsız aktivite tamamlama hakkınız var.',
      );
    }

    final todayCompletions = await ActivityService().getTodayCompletionsCount(userId);
    final allowed = todayCompletions < freeDailyActivityCompleteLimit;
    return UsageQuota(
      isAllowed: allowed,
      isPro: false,
      usedCount: todayCompletions,
      maxLimit: freeDailyActivityCompleteLimit,
      reason: allowed
          ? 'Bugün kalan tamamlama hakkı: ${freeDailyActivityCompleteLimit - todayCompletions}/$freeDailyActivityCompleteLimit'
          : 'Ücretsiz planda günde maksimum $freeDailyActivityCompleteLimit aktivite tamamlayabilirsiniz (Her gece 00:00\'da yenilenir). Sınırsız tamamlamak için Pro\'ya yükseltin! ⭐',
    );
  }

  Future<bool> canCompleteActivity(String userId) async {
    final quota = await checkActivityCompleteQuota(userId);
    return quota.isAllowed;
  }

  /// Process Pro Upgrade Payment
  Future<bool> purchasePro(String userId) async {
    try {
      // 1. Process payment via the configured Gateway (Mock or RevenueCat)
      final isSuccess = await _paymentGateway.processPayment(
        userId: userId,
        productId: 'pointspend_pro_yearly',
      );

      if (isSuccess) {
        final now = ServerTimeService.now;
        final expiry = now.add(const Duration(days: 365));

        // 2. Upgrade user proStatus to true in Firestore & save dates
        await _userService.updateUser(userId, {
          'proStatus': true,
          'tier': 'Pro',
          'proStartDate': now.toIso8601String(),
          'proEndDate': expiry.toIso8601String(),
        });
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) print('Purchase Pro error: $e');
      return false;
    }
  }

  /// Restore purchases
  Future<bool> restorePurchases(String userId) async {
    try {
      final now = ServerTimeService.now;
      final expiry = now.add(const Duration(days: 365));

      await _userService.updateUser(userId, {
        'proStatus': true,
        'tier': 'Pro',
        'proStartDate': now.toIso8601String(),
        'proEndDate': expiry.toIso8601String(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Cancel / Terminate Pro Subscription
  Future<bool> cancelProSubscription(String userId) async {
    try {
      final now = ServerTimeService.now;
      await _userService.updateUser(userId, {
        'proStatus': false,
        'tier': 'Free',
        'proEndDate': now.toIso8601String(),
        'proCancelledAt': now.toIso8601String(),
      });
      return true;
    } catch (e) {
      if (kDebugMode) print('Cancel Pro error: $e');
      return false;
    }
  }
}

class UsageQuota {
  final bool isAllowed;
  final bool isPro;
  final int usedCount;
  final int maxLimit; // 3 for Free, -1 for Pro (unlimited)
  final String reason;

  const UsageQuota({
    required this.isAllowed,
    required this.isPro,
    required this.usedCount,
    required this.maxLimit,
    required this.reason,
  });

  int get remaining => isPro ? 999 : (maxLimit - usedCount).clamp(0, maxLimit);
}
