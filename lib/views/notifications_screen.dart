import 'package:flutter/material.dart';
import '../models/app_notification.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatelessWidget {
  final String userId;
  const NotificationsScreen({super.key, required this.userId});

  static Route<void> route(String userId) => MaterialPageRoute(
        builder: (_) => NotificationsScreen(userId: userId),
      );

  IconData _iconForType(String type) {
    switch (type) {
      case 'daily_reset':
        return Icons.wb_sunny_rounded;
      case 'streak':
        return Icons.local_fire_department_rounded;
      case 'reward':
        return Icons.card_giftcard_rounded;
      case 'perfect_day':
        return Icons.stars_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'daily_reset':
        return const Color(0xFF0EA5E9);
      case 'streak':
        return const Color(0xFFEA580C);
      case 'reward':
        return const Color(0xFFEAB308);
      case 'perfect_day':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF16A34A);
    }
  }

  Color _bgForType(String type) {
    switch (type) {
      case 'daily_reset':
        return const Color(0xFFE0F2FE);
      case 'streak':
        return const Color(0xFFFFEDD5);
      case 'reward':
        return const Color(0xFFFEF9C3);
      case 'perfect_day':
        return const Color(0xFFEDE9FE);
      default:
        return const Color(0xFFDCFCE7);
    }
  }

  String _timeAgo(DateTime createdAt) {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inSeconds < 60) return 'Az önce';
    if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
    if (diff.inHours < 24) return '${diff.inHours} sa önce';
    if (diff.inDays < 7) return '${diff.inDays} gün önce';
    return '${createdAt.day}.${createdAt.month}.${createdAt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final service = NotificationService.instance;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0.5,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
        title: Text(
          'Bildirimler',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => service.markAllAsRead(userId),
            icon: const Icon(Icons.done_all_rounded, size: 18),
            label: const Text('Tümünü Oku'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF16A34A),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: service.watchNotifications(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF16A34A)),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: const BoxDecoration(
                      color: Color(0xFFDCFCE7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      size: 56,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Henüz Bildirim Yok',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            );
          }

          // Separate unread and read notifications
          final unread = notifications.where((n) => !n.isRead).toList();
          final read = notifications.where((n) => n.isRead).toList();

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            children: [
              if (unread.isNotEmpty) ...[
                const _SectionHeader(
                  label: 'Okunmamış Bildirimler',
                  color: Color(0xFF16A34A),
                ),
                const SizedBox(height: 8),
                ...unread.map(
                  (n) => _NotificationTile(
                    notification: n,
                    userId: userId,
                    service: service,
                    icon: _iconForType(n.type),
                    iconColor: _colorForType(n.type),
                    iconBg: _bgForType(n.type),
                    timeAgo: _timeAgo(n.createdAt),
                    isDark: isDark,
                    isUnread: true,
                  ),
                ),
                if (read.isNotEmpty) const SizedBox(height: 16),
              ],
              if (read.isNotEmpty) ...[
                _SectionHeader(
                  label: 'Önceden Gelen Bildirimler',
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                ),
                const SizedBox(height: 8),
                ...read.map(
                  (n) => _NotificationTile(
                    notification: n,
                    userId: userId,
                    service: service,
                    icon: _iconForType(n.type),
                    iconColor: _colorForType(n.type).withValues(alpha: 0.5),
                    iconBg: _bgForType(n.type).withValues(alpha: 0.5),
                    timeAgo: _timeAgo(n.createdAt),
                    isDark: isDark,
                    isUnread: false,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color color;

  const _SectionHeader({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final String userId;
  final NotificationService service;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String timeAgo;
  final bool isDark;
  final bool isUnread;

  const _NotificationTile({
    required this.notification,
    required this.userId,
    required this.service,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.timeAgo,
    required this.isDark,
    required this.isUnread,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseText = theme.colorScheme.onSurface;

    // Görülmeyen bildirimler: koyu siyah text & bold
    // Önceden gelen bildirimler: soluk siyah text (faded black text)
    final titleColor = isUnread
        ? (isDark ? Colors.white : Colors.black)
        : (isDark ? Colors.white38 : Colors.black38);

    final bodyColor = isUnread
        ? (isDark ? Colors.white70 : Colors.black87)
        : (isDark ? Colors.white30 : Colors.black38);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      onDismissed: (_) => service.deleteNotification(userId, notification.id),
      child: GestureDetector(
        onTap: () {
          if (isUnread) {
            service.markAsRead(userId, notification.id);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isUnread
                ? (isDark ? const Color(0xFF1E293B) : Colors.white)
                : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
            borderRadius: BorderRadius.circular(16),
            border: isUnread
                ? Border.all(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.4),
                    width: 1.5,
                  )
                : Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.04),
                    width: 1,
                  ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isUnread ? 0.05 : 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isUnread
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                              color: titleColor,
                            ),
                          ),
                        ),
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 8),
                            decoration: const BoxDecoration(
                              color: Color(0xFF16A34A),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: TextStyle(
                        fontSize: 13,
                        color: bodyColor,
                        height: 1.4,
                        fontWeight: isUnread
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        fontSize: 11,
                        color: baseText.withValues(
                            alpha: isUnread ? 0.5 : 0.3),
                        fontWeight: FontWeight.w500,
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
}
