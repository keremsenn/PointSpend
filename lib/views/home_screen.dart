import 'package:flutter/material.dart';
import '../core/utils/url_launcher_helper.dart';
import '../models/activity.dart';
import '../models/activity_completion.dart';
import '../models/reward.dart';
import '../models/user_profile.dart';
import '../services/activity_service.dart';
import '../services/notification_service.dart';
import '../services/purchase_service.dart';
import '../services/reward_service.dart';
import '../services/user_service.dart';
import 'dialogs/add_activity_dialog.dart';
import 'dialogs/add_reward_dialog.dart';
import 'dialogs/edit_activity_dialog.dart';
import 'dialogs/edit_reward_dialog.dart';
import 'dialogs/paywall_dialog.dart';
import 'notifications_screen.dart';
import 'widgets/reward_image_view.dart';

class HomeScreen extends StatelessWidget {
  final String userId;
  final UserProfile? initialUser;
  final List<Activity>? initialActivities;
  final List<Reward>? initialRewards;
  final Map<String, ActivityCompletion>? initialCompletions;

  const HomeScreen({
    super.key,
    required this.userId,
    this.initialUser,
    this.initialActivities,
    this.initialRewards,
    this.initialCompletions,
  });

  void _showActivityDetail(
    BuildContext context,
    Activity act,
    ActivityService activityService, {
    ActivityStatus? status,
  }) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: (status?.isCompleted ?? false)
                        ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9))
                        : const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    (status?.isCompleted ?? false) ? Icons.check_circle_rounded : Icons.bolt_rounded,
                    color: const Color(0xFF16A34A),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        act.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        (status?.isCompleted ?? false)
                            ? '+${act.pointValue} Puan (Kazanıldı)'
                            : '+${act.pointValue} Puan Kazandırır',
                        style: TextStyle(
                          color: (status?.isCompleted ?? false)
                              ? textColor.withValues(alpha: 0.6)
                              : const Color(0xFF16A34A),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (status != null && status.isCompleted) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF14241B) : const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 20, color: Color(0xFF16A34A)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Durum: Tamamlandı',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF166534)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            status.statusText,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF15803D)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
            if (act.reminderTime.isNotEmpty) ...[
              _detailRow(Icons.access_time_rounded, 'Hatırlatıcı Saati', act.reminderTime, textColor),
              const SizedBox(height: 10),
            ],
            _detailRow(Icons.repeat_rounded, 'Sıklık', act.frequencyLabel, textColor),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (dCtx) => AlertDialog(
                          title: const Text('Aktiviteyi Sil'),
                          content: Text('"${act.title}" aktivitesi kalıcı olarak silinecek. Emin misin?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dCtx, false),
                              child: const Text('İptal'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(dCtx, true),
                              child: const Text('Sil', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true && context.mounted) {
                        await activityService.deleteActivity(act.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Aktivite silindi.')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                    label: const Text('Sil', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.red.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      EditActivityDialog.show(context, act);
                    },
                    icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
                    label: const Text('Düzenle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showRewardDetail(BuildContext context, Reward rwd, RewardService rewardService) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                RewardImageView(
                  imageUrl: rwd.imageUrl,
                  width: 52,
                  height: 52,
                  borderRadius: BorderRadius.circular(14),
                  fallback: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.card_giftcard_rounded,
                      color: Color(0xFFD97706),
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rwd.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Gerekli: ${rwd.requiredPoints} Puan',
                        style: const TextStyle(
                          color: Color(0xFFD97706),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _detailRow(Icons.stars_rounded, 'Gerekli Puan', '${rwd.requiredPoints} Puan', textColor),
            if (rwd.optionalPrice != null) ...[
              const SizedBox(height: 10),
              _detailRow(
                Icons.payments_rounded,
                'Fiyat / Tahmini Değer',
                '${UrlLauncherHelper.formatPrice(rwd.optionalPrice!)} TL',
                textColor,
              ),
            ],
            if (rwd.optionalUrl != null && rwd.optionalUrl!.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              RewardLinkTile(
                url: rwd.optionalUrl!,
                textColor: textColor,
                isDark: theme.brightness == Brightness.dark,
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (dCtx) => AlertDialog(
                          title: const Text('Ödülü Sil'),
                          content: Text('"${rwd.title}" ödülü kalıcı olarak silinecek. Emin misin?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dCtx, false),
                              child: const Text('İptal'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(dCtx, true),
                              child: const Text('Sil', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true && context.mounted) {
                        await rewardService.deleteReward(rwd.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Ödül silindi.')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                    label: const Text('Sil', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.red.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      EditRewardDialog.show(context, rwd);
                    },
                    icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
                    label: const Text('Düzenle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, Color textColor) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF16A34A)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 13, color: textColor.withValues(alpha: 0.6)),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final userService = UserService();
    final activityService = ActivityService();
    final rewardService = RewardService();
    final purchaseService = PurchaseService();

    return StreamBuilder<UserProfile>(
      initialData: initialUser,
      stream: userService.watchUser(userId),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData && userSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: const Center(
              child: CircularProgressIndicator(color: Color(0xFF16A34A)),
            ),
          );
        }

        final user = userSnapshot.data ??
            UserProfile(
              id: userId,
              name: 'Kullanıcı',
              email: 'kullanici@pointspend.app',
              totalPoints: 1250,
              proStatus: false,
              tier: 'Free',
              profileStatus: 'active',
              createdAt: DateTime.now(),
            );

        final currentPoints = user.totalPoints;
        final theme = Theme.of(context);
        final textColor = theme.colorScheme.onSurface;
        final isDark = theme.brightness == Brightness.dark;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                // 1. Header & Points Card
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User info and badges
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.name,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFEDD5),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.local_fire_department_rounded, color: Colors.deepOrange, size: 18),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${user.displayStreak} Gün',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.deepOrange,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.star_rounded, color: Color(0xFF166534), size: 18),
                                      const SizedBox(width: 4),
                                      Text(
                                        user.proStatus ? 'PRO' : 'FREE',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF166534),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                StreamBuilder<int>(
                                  stream: NotificationService.instance.watchUnreadCount(userId),
                                  builder: (context, snap) {
                                    final unreadCount = snap.data ?? 0;
                                    return GestureDetector(
                                      onTap: () => Navigator.push(context, NotificationsScreen.route(userId)),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: theme.cardColor,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.05),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            Icon(Icons.notifications_outlined, color: textColor, size: 20),
                                            if (unreadCount > 0)
                                              Positioned(
                                                right: -2,
                                                top: -2,
                                                child: Container(
                                                  padding: const EdgeInsets.all(3),
                                                  decoration: const BoxDecoration(
                                                    color: Color(0xFF16A34A),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Points Balance Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF16A34A), Color(0xFF15803D)],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF16A34A).withValues(alpha: 0.3),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Mevcut Puan Bakiyeniz',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    '$currentPoints',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 42,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -1,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Puan',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => AddActivityDialog.show(context, userId),
                                      icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                                      label: const Text('Aktivite Ekle'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => AddRewardDialog.show(context, userId),
                                      icon: const Icon(Icons.card_giftcard_rounded, size: 18),
                                      label: const Text('Ödül Ekle'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: const Color(0xFF15803D),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. Activities Header
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 26, 20, 12),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '⚡ Bugün Kazan',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => AddActivityDialog.show(context, userId),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Ekle'),
                        ),
                      ],
                    ),
                  ),
                ),

                // 3. Activities Stream
                StreamBuilder<Map<String, ActivityCompletion>>(
                  initialData: initialCompletions,
                  stream: activityService.streamLatestCompletionsByUser(userId),
                  builder: (context, completionsSnapshot) {
                    final latestCompletions = completionsSnapshot.data ?? {};
                    return StreamBuilder<List<Activity>>(
                      initialData: initialActivities,
                      stream: activityService.streamActivitiesByUser(userId),
                      builder: (context, activitySnapshot) {
                        final activities = activitySnapshot.data ?? [];

                        if (activities.isEmpty) {
                          return SliverToBoxAdapter(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 20),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                              ),
                              child: Center(
                                child: Text(
                                  'Henüz aktivite eklenmedi. "+" butonundan yeni aktivite ekleyebilirsin.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: textColor.withValues(alpha: 0.6),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }

                        // Separate available and completed activities
                        final availableEntries = <MapEntry<Activity, ActivityStatus>>[];
                        final completedEntries = <MapEntry<Activity, ActivityStatus>>[];

                        for (final act in activities) {
                          final status = ActivityService.calculateStatus(act, latestCompletions[act.id]);
                          if (status.isAvailable) {
                            availableEntries.add(MapEntry(act, status));
                          } else {
                            // Yalnızca bir kez (once) seçilen aktiviteler tamamlanınca
                            // ana ekrandan tamamen kaybolsun, silik de olsa gözükmesin.
                            final freq = act.frequency.toLowerCase();
                            if (freq != 'once' && freq != 'optional') {
                              completedEntries.add(MapEntry(act, status));
                            }
                          }
                        }

                        final allEntries = [...availableEntries, ...completedEntries];

                        if (allEntries.isEmpty) {
                          return SliverToBoxAdapter(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 20),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                              ),
                              child: Center(
                                child: Text(
                                  'Şu an gösterilecek aktif bir aktivite yok. "+" butonundan yeni aktivite ekleyebilirsin.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: textColor.withValues(alpha: 0.6),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }

                        final showAllDoneBanner = availableEntries.isEmpty && completedEntries.isNotEmpty;

                        return SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                if (showAllDoneBanner) {
                                  if (index == 0) {
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF14241B) : const Color(0xFFF0FDF4),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: const Color(0xFFBBF7D0)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.task_alt_rounded, color: Color(0xFF16A34A), size: 28),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Tüm görevlerini tamamladın! 🎉',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                    color: Color(0xFF166534),
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'Aktivitelerinizin ne zaman yenileneceğini aşağıdan görebilirsiniz.',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: textColor.withValues(alpha: 0.7),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                }

                                final itemIndex = showAllDoneBanner ? index - 1 : index;
                                final entry = allEntries[itemIndex];
                                final act = entry.key;
                                final status = entry.value;
                                final isDone = status.isCompleted;

                                if (isDone) {
                                  // Tamamlanmış (Silik / Kilitli) Aktivite Kartı
                                  return GestureDetector(
                                    onTap: () => _showActivityDetail(context, act, activityService, status: status),
                                    child: Opacity(
                                      opacity: 0.68,
                                      child: Container(
                                        margin: const EdgeInsets.only(bottom: 10),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: isDark
                                                ? Colors.white.withValues(alpha: 0.08)
                                                : Colors.grey.withValues(alpha: 0.25),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 44,
                                              height: 44,
                                              decoration: BoxDecoration(
                                                color: isDark ? const Color(0xFF14241B) : const Color(0xFFDCFCE7),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: const Icon(
                                                Icons.check_circle_rounded,
                                                color: Color(0xFF16A34A),
                                                size: 24,
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Flexible(
                                                        child: Text(
                                                          act.title,
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.w600,
                                                            fontSize: 15,
                                                            color: textColor.withValues(alpha: 0.8),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: Text(
                                                          status.frequencyLabel,
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.bold,
                                                            color: textColor.withValues(alpha: 0.7),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        act.frequency == 'weekly'
                                                            ? Icons.calendar_month_rounded
                                                            : act.frequency == 'once'
                                                                ? Icons.lock_clock_rounded
                                                                : Icons.schedule_rounded,
                                                        size: 13,
                                                        color: const Color(0xFFD97706),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Expanded(
                                                        child: Text(
                                                          status.statusText,
                                                          style: const TextStyle(
                                                            color: Color(0xFFD97706),
                                                            fontWeight: FontWeight.w600,
                                                            fontSize: 11,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                              decoration: BoxDecoration(
                                                color: isDark ? const Color(0xFF334155).withValues(alpha: 0.5) : const Color(0xFFE2E8F0),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.lock_rounded, size: 13, color: textColor.withValues(alpha: 0.6)),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Tamamlandı',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w600,
                                                      color: textColor.withValues(alpha: 0.7),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                // Aktif (Tamamlanmaya Hazır) Aktivite Kartı
                                return GestureDetector(
                                  onTap: () => _showActivityDetail(context, act, activityService, status: status),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: theme.cardColor,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: const Color(0xFF16A34A).withValues(alpha: 0.25),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.03),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFDCFCE7),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Icon(
                                            Icons.radio_button_unchecked_rounded,
                                            color: Color(0xFF16A34A),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      act.title,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 15,
                                                        color: textColor,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFDCFCE7),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      status.frequencyLabel,
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                        color: Color(0xFF166534),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                '+${act.pointValue} Puan Kazandırır',
                                                style: const TextStyle(
                                                  color: Color(0xFF16A34A),
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton(
                                          onPressed: () async {
                                            try {
                                              final quota = await purchaseService.checkActivityCompleteQuota(userId);
                                              if (!quota.isAllowed) {
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text(quota.reason),
                                                      backgroundColor: const Color(0xFFD97706),
                                                      action: SnackBarAction(
                                                        label: 'Pro\'ya Geç',
                                                        textColor: Colors.white,
                                                        onPressed: () => PaywallDialog.show(context, userId),
                                                      ),
                                                      duration: const Duration(seconds: 4),
                                                    ),
                                                  );
                                                  PaywallDialog.show(context, userId);
                                                }
                                                return;
                                              }

                                              final success = await activityService.completeActivity(userId, act);
                                              if (context.mounted) {
                                                if (success) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('Tebrikler! "+${act.pointValue} Puan" kazanıldı! 🔥'),
                                                      backgroundColor: const Color(0xFF16A34A),
                                                      duration: const Duration(seconds: 2),
                                                    ),
                                                  );
                                                } else {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(
                                                      content: Text('Bu aktivite henüz yenilenme süresinde!'),
                                                      backgroundColor: Colors.orange,
                                                    ),
                                                  );
                                                }
                                              }
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
                                                );
                                              }
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF16A34A),
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                          child: const Text('Tamamladım'),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              childCount: allEntries.length + (showAllDoneBanner ? 1 : 0),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),

                // 4. Rewards Header
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 26, 20, 12),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '🎁 Ödüllerim',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => AddRewardDialog.show(context, userId),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Ekle'),
                        ),
                      ],
                    ),
                  ),
                ),

                // 5. Rewards Stream (Active / Unclaimed only)
                StreamBuilder<List<Reward>>(
                  initialData: initialRewards,
                  stream: rewardService.streamRewardsByUser(userId),
                  builder: (context, rewardSnapshot) {
                    final rewards = rewardSnapshot.data ?? [];
                    // Only active/unclaimed rewards shown on Home screen
                    final activeRewards = rewards.where((r) => !r.claimed).toList();

                    if (activeRewards.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                          ),
                          child: Center(
                            child: Text(
                              'Henüz eklenmiş aktif bir ödül yok.\n"+" butonundan yeni ödül ekleyebilirsin.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: textColor.withValues(alpha: 0.6),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),
                      );
                    }

                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final rwd = activeRewards[index];
                            final isUnlocked = currentPoints >= rwd.requiredPoints;
                            final progress = (currentPoints / rwd.requiredPoints).clamp(0.0, 1.0);

                            return GestureDetector(
                              onTap: () => _showRewardDetail(context, rwd, rewardService),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: theme.cardColor,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: isUnlocked
                                        ? const Color(0xFF86EFAC)
                                        : Colors.grey.withValues(alpha: 0.2),
                                    width: isUnlocked ? 1.5 : 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.03),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        _buildRewardThumbnail(rwd, isUnlocked),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      rwd.title,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 16,
                                                        color: textColor,
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: isUnlocked
                                                          ? const Color(0xFFDCFCE7)
                                                          : const Color(0xFFFEF3C7),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      isUnlocked ? 'Açık' : 'Kilitli',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.bold,
                                                        color: isUnlocked
                                                            ? const Color(0xFF15803D)
                                                            : const Color(0xFFB45309),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Gereken: ${rwd.requiredPoints} Puan',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: textColor.withValues(alpha: 0.6),
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '$currentPoints / ${rwd.requiredPoints} puan',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: textColor.withValues(alpha: 0.7),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          '${(progress * 100).toStringAsFixed(0)}%',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: textColor.withValues(alpha: 0.8),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        value: progress,
                                        minHeight: 8,
                                        backgroundColor: Colors.grey.withValues(alpha: 0.15),
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          isUnlocked ? const Color(0xFF16A34A) : const Color(0xFFF59E0B),
                                        ),
                                      ),
                                    ),
                                    if (isUnlocked) ...[
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            try {
                                              await rewardService.claimReward(userId, rwd);
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Tebrikler! "${rwd.title}" ödülü kullanıldı! (-${rwd.requiredPoints} Puan) 🎁'),
                                                    backgroundColor: const Color(0xFF15803D),
                                                  ),
                                                );
                                              }
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
                                                );
                                              }
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF15803D),
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                          child: Text(
                                            'Ödülü Kullan (${rwd.requiredPoints} Puan)',
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                          childCount: activeRewards.length,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRewardThumbnail(Reward rwd, bool isUnlocked) {
    final fallback = _buildFallbackRewardIcon(rwd, isUnlocked);
    final content = RewardImageView(
      imageUrl: rwd.imageUrl,
      width: 50,
      height: 50,
      borderRadius: BorderRadius.circular(14),
      fallback: fallback,
    );

    if (rwd.imageUrl.isEmpty) return content;

    return Stack(
      children: [
        content,
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isUnlocked ? const Color(0xFF16A34A) : const Color(0xFFD97706),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: Icon(
              isUnlocked ? Icons.lock_open_rounded : Icons.lock_rounded,
              size: 10,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackRewardIcon(Reward rwd, bool isUnlocked) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: isUnlocked ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        isUnlocked ? Icons.lock_open_rounded : Icons.lock_rounded,
        color: isUnlocked ? const Color(0xFF166534) : const Color(0xFFD97706),
      ),
    );
  }
}
