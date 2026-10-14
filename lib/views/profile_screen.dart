import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/notification_service.dart';
import '../core/theme/theme_controller.dart';
import '../models/user_profile.dart';
import '../services/activity_service.dart';
import '../services/reward_service.dart';
import '../services/storage_service.dart';
import '../services/user_service.dart';
import 'account_settings_screen.dart';
import 'dialogs/paywall_dialog.dart';
import 'notifications_screen.dart';

class ProfileScreen extends StatelessWidget {
  final String userId;
  final VoidCallback? onLogout;

  const ProfileScreen({super.key, required this.userId, this.onLogout});

  @override
  Widget build(BuildContext context) {
    final userService = UserService();
    final activityService = ActivityService();
    final rewardService = RewardService();

    final theme = Theme.of(context);
    final cardBg = theme.cardColor;
    final textColor = theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Profil & Ayarlar',
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0.5,
      ),
      body: StreamBuilder<UserProfile>(
        stream: userService.watchUser(userId),
        builder: (context, snapshot) {
          final user = snapshot.data;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // User Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _ProfileAvatar(userId: userId, photoUrl: user?.photoUrl),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.name ?? 'Kullanıcı',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user?.email ?? '',
                              style: TextStyle(fontSize: 13, color: textColor.withValues(alpha: 0.6)),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => PaywallDialog.show(context, userId),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  user?.proStatus == true ? 'Pro Üyelik (Aktif ✨)' : 'Ücretsiz Sürüm (Pro\'ya Yükselt)',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Statistics Section Header
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 12),
                    child: Text(
                      'Performans & İstatistikler 📊',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                ),

                // 2x2 Stats Grid
                Row(
                  children: [
                    // 1. Seri (Streak)
                    Expanded(
                      child: _StatCard(
                        cardBg: cardBg,
                        textColor: textColor,
                        icon: Icons.local_fire_department_rounded,
                        iconColor: Colors.deepOrange,
                        iconBg: Colors.deepOrange.withValues(alpha: 0.12),
                        title: 'Seri (Streak)',
                        value: '${user?.displayStreak ?? 0} Gün 🔥',
                        subtitle: 'Rekor: ${user?.bestStreak ?? 0} Gün',
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 2. Mükemmel Günler
                    Expanded(
                      child: _StatCard(
                        cardBg: cardBg,
                        textColor: textColor,
                        icon: Icons.stars_rounded,
                        iconColor: const Color(0xFFD97706),
                        iconBg: const Color(0xFFFEF3C7),
                        title: 'Mükemmel Günler',
                        value: '${user?.perfectDaysCount ?? 0} Gün 🌟',
                        subtitle: 'Tüm Görevler 3/3',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // 3. Toplam Aktivite
                    Expanded(
                      child: StreamBuilder<int>(
                        stream: activityService.streamTotalCompletionsCount(userId),
                        builder: (context, snap) {
                          final count = snap.data ?? 0;
                          return _StatCard(
                            cardBg: cardBg,
                            textColor: textColor,
                            icon: Icons.check_circle_rounded,
                            iconColor: const Color(0xFF16A34A),
                            iconBg: const Color(0xFFDCFCE7),
                            title: 'Toplam Aktivite',
                            value: '$count Adet ✅',
                            subtitle: 'Tamamlanan Görev',
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 4. Kullanılan Ödüller
                    Expanded(
                      child: StreamBuilder<int>(
                        stream: rewardService.streamTotalClaimsCount(userId),
                        builder: (context, snap) {
                          final count = snap.data ?? 0;
                          return _StatCard(
                            cardBg: cardBg,
                            textColor: textColor,
                            icon: Icons.card_giftcard_rounded,
                            iconColor: const Color(0xFF2563EB),
                            iconBg: const Color(0xFFDBEAFE),
                            title: 'Kullanılan Ödül',
                            value: '$count Adet 🎁',
                            subtitle: 'Hak Edilen Ödüller',
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Settings Section Header
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 12),
                    child: Text(
                      'Hesap & Ayarlar ⚙️',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                ),

                // Settings Section
                Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      // 1. Hesap Ayarları (Ad Soyad, E-Posta, Şifre)
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.manage_accounts_rounded, color: Color(0xFF16A34A), size: 20),
                        ),
                        title: Text('Hesap Ayarları', style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                        subtitle: Text('Ad soyad, e-posta ve şifre yönetimi', style: TextStyle(fontSize: 12, color: textColor.withValues(alpha: 0.6))),
                        trailing: Icon(Icons.chevron_right_rounded, color: textColor.withValues(alpha: 0.5)),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AccountSettingsScreen(userId: userId, onLogout: onLogout),
                            ),
                          );
                        },
                      ),
                      Divider(height: 1, color: theme.dividerColor),

                      ListTile(
                        leading: const Icon(Icons.notifications_active_outlined, color: Color(0xFF16A34A)),
                        title: Text('Hatırlatmalar & Bildirimler', style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            StreamBuilder<int>(
                              stream: NotificationService.instance.watchUnreadCount(userId),
                              builder: (context, snap) {
                                final count = snap.data ?? 0;
                                if (count == 0) return const SizedBox.shrink();
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF16A34A),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$count',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              },
                            ),
                            Icon(Icons.chevron_right_rounded, color: textColor.withValues(alpha: 0.5)),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(context, NotificationsScreen.route(userId));
                        },
                      ),
                      Divider(height: 1, color: theme.dividerColor),

                      // Dark / Light Mode Switch
                      ValueListenableBuilder<ThemeMode>(
                        valueListenable: ThemeController.instance.themeModeNotifier,
                        builder: (context, currentMode, _) {
                          final isDark = currentMode == ThemeMode.dark;
                          return SwitchListTile(
                            secondary: Icon(
                              isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                              color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF16A34A),
                            ),
                            title: Text(
                              'Karanlık Mod',
                              style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
                            ),
                            subtitle: Text(
                              isDark ? 'Karanlık tema aktif' : 'Aydınlık tema aktif',
                              style: TextStyle(fontSize: 12, color: textColor.withValues(alpha: 0.6)),
                            ),
                            value: isDark,
                            activeColor: const Color(0xFF16A34A),
                            onChanged: (val) {
                              ThemeController.instance.setThemeMode(
                                val ? ThemeMode.dark : ThemeMode.light,
                              );
                            },
                          );
                        },
                      ),
                      Divider(height: 1, color: theme.dividerColor),

                      ListTile(
                        leading: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFEAB308)),
                        title: Text('PointSpend Pro (Abonelik)', style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          user?.proStatus == true
                              ? 'Pro Aktif ✨ • Yönet veya iptal et'
                              : 'Sınırsız aktivite & ödül erişimi',
                          style: TextStyle(fontSize: 12, color: textColor.withValues(alpha: 0.6)),
                        ),
                        trailing: user?.proStatus == true
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'Yönet',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF166534),
                                  ),
                                ),
                              )
                            : Icon(Icons.chevron_right_rounded, color: textColor.withValues(alpha: 0.5)),
                        onTap: () => PaywallDialog.show(context, userId),
                      ),
                      if (onLogout != null) ...[
                        Divider(height: 1, color: theme.dividerColor),
                        ListTile(
                          leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                          title: const Text('Çıkış Yap', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                          subtitle: Text('Oturumu sonlandırır', style: TextStyle(fontSize: 12, color: textColor.withValues(alpha: 0.6))),
                          onTap: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (dCtx) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                title: const Row(
                                  children: [
                                    Icon(Icons.logout_rounded, color: Colors.redAccent),
                                    SizedBox(width: 10),
                                    Text('Çıkış Yap', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                content: const Text(
                                  'Çıkış yapmak istediğinize emin misiniz?',
                                  style: TextStyle(fontSize: 14),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(dCtx, false),
                                    child: const Text('İptal', style: TextStyle(color: Colors.grey)),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(dCtx, true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.redAccent,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    child: const Text('Çıkış Yap', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            );

                            if (confirmed == true && onLogout != null) {
                              onLogout!();
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProfileAvatar extends StatefulWidget {
  final String userId;
  final String? photoUrl;

  const _ProfileAvatar({required this.userId, this.photoUrl});

  @override
  State<_ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<_ProfileAvatar> {
  bool _isUploading = false;

  ImageProvider? _getAvatarProvider(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) return null;
    try {
      if (photoUrl.startsWith('data:image') || photoUrl.startsWith('base64,')) {
        final commaIndex = photoUrl.indexOf(',');
        final raw = commaIndex != -1 ? photoUrl.substring(commaIndex + 1) : photoUrl;
        return MemoryImage(base64Decode(raw));
      }
      return NetworkImage(photoUrl);
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 400,
      maxHeight: 400,
      imageQuality: 75,
    );

    if (pickedFile == null) return;

    setState(() => _isUploading = true);

    try {
      final storageService = StorageService();
      final downloadUrl = await storageService.uploadAvatarImage(pickedFile, widget.userId);

      if (downloadUrl != null && downloadUrl.isNotEmpty) {
        await UserService().updateUser(widget.userId, {'photoUrl': downloadUrl});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Profil fotoğrafınız başarıyla güncellendi!'),
              backgroundColor: Color(0xFF16A34A),
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        throw Exception('Resim işlenemedi.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString().replaceAll("Exception: ", "")}'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _selectPresetAvatar(String avatarUrl) async {
    Navigator.pop(context);
    setState(() => _isUploading = true);
    try {
      await UserService().updateUser(widget.userId, {'photoUrl': avatarUrl});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Profil avatarınız güncellendi!'),
            backgroundColor: Color(0xFF16A34A),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showPresetAvatars() {
    Navigator.pop(context);
    final presets = [
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
      'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200',
      'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=200',
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200',
      'https://images.unsplash.com/photo-1527980965255-d3b416303d12?w=200',
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hazır Profil Avatarları',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: presets.map((url) {
                return GestureDetector(
                  onTap: () => _selectPresetAvatar(url),
                  child: CircleAvatar(
                    radius: 36,
                    backgroundImage: NetworkImage(url),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Profil Fotoğrafı',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded, color: Color(0xFF16A34A)),
                  title: const Text('Galeriden Seç'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndUploadImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFF16A34A)),
                  title: const Text('Kamera ile Çek'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndUploadImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.face_rounded, color: Color(0xFF16A34A)),
                  title: const Text('Hazır Avatar Seç'),
                  onTap: _showPresetAvatars,
                ),
                if (widget.photoUrl != null && widget.photoUrl!.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                    title: const Text('Fotoğrafı Kaldır', style: TextStyle(color: Colors.redAccent)),
                    onTap: () async {
                      Navigator.pop(context);
                      await UserService().updateUser(widget.userId, {'photoUrl': ''});
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatarProvider = _getAvatarProvider(widget.photoUrl);

    return GestureDetector(
      onTap: _isUploading ? null : _showImageOptions,
      child: Stack(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFDCFCE7),
              border: Border.all(color: const Color(0xFF86EFAC), width: 2),
              image: avatarProvider != null
                  ? DecorationImage(
                      image: avatarProvider,
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _isUploading
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Color(0xFF16A34A),
                    ),
                  )
                : avatarProvider == null
                    ? const Icon(
                        Icons.person_rounded,
                        size: 38,
                        color: Color(0xFF166534),
                      )
                    : null,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                size: 12,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final Color cardBg;
  final Color textColor;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String value;
  final String subtitle;

  const _StatCard({
    required this.cardBg,
    required this.textColor,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: textColor.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
