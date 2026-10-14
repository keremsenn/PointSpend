import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/user_service.dart';
import 'dialogs/edit_profile_dialog.dart';
import 'dialogs/paywall_dialog.dart';

class AccountSettingsScreen extends StatelessWidget {
  final String userId;
  final VoidCallback? onLogout;

  const AccountSettingsScreen({super.key, required this.userId, this.onLogout});

  @override
  Widget build(BuildContext context) {
    final userService = UserService();
    final theme = Theme.of(context);
    final cardBg = theme.cardColor;
    final textColor = theme.colorScheme.onSurface;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Hesap Ayarları',
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0.5,
      ),
      body: StreamBuilder<UserProfile>(
        stream: userService.watchUser(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF16A34A)),
            );
          }

          final user = snapshot.data;
          if (user == null) {
            return const Center(child: Text('Kullanıcı bilgisi bulunamadı.'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF16A34A).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildAvatar(user.photoUrl),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user.email,
                              style: TextStyle(
                                fontSize: 13,
                                color: textColor.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 10),
                  child: Text(
                    'Kişisel ve Güvenlik Bilgileri',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textColor.withValues(alpha: 0.7),
                    ),
                  ),
                ),

                // Settings Card
                Container(
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
                  child: Column(
                    children: [
                      // 1. Edit Name
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.person_outline_rounded, color: Color(0xFF16A34A), size: 20),
                        ),
                        title: Text(
                          'Ad Soyad Değiştir',
                          style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          user.name,
                          style: TextStyle(fontSize: 12, color: textColor.withValues(alpha: 0.6)),
                        ),
                        trailing: Icon(Icons.chevron_right_rounded, color: textColor.withValues(alpha: 0.4)),
                        onTap: () => EditProfileDialog.showEditName(context, user),
                      ),
                      Divider(height: 1, color: theme.dividerColor),

                      // 2. Edit Email
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.email_outlined, color: Color(0xFF16A34A), size: 20),
                        ),
                        title: Text(
                          'E-Posta Adresini Değiştir',
                          style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          user.email,
                          style: TextStyle(fontSize: 12, color: textColor.withValues(alpha: 0.6)),
                        ),
                        trailing: Icon(Icons.chevron_right_rounded, color: textColor.withValues(alpha: 0.4)),
                        onTap: () => EditProfileDialog.showEditEmail(context, user),
                      ),
                      Divider(height: 1, color: theme.dividerColor),

                      // 3. Edit Password
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.lock_outline_rounded, color: Color(0xFF16A34A), size: 20),
                        ),
                        title: Text(
                          'Şifreyi Değiştir',
                          style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '••••••••',
                          style: TextStyle(fontSize: 12, color: textColor.withValues(alpha: 0.6)),
                        ),
                        trailing: Icon(Icons.chevron_right_rounded, color: textColor.withValues(alpha: 0.4)),
                        onTap: () => EditProfileDialog.showEditPassword(context, user),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 10),
                  child: Text(
                    'Abonelik ve Plan Yönetimi',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textColor.withValues(alpha: 0.7),
                    ),
                  ),
                ),

                // Subscription Card
                Container(
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
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: user.proStatus ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.workspace_premium_rounded,
                        color: user.proStatus ? const Color(0xFF166534) : const Color(0xFFD97706),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      user.proStatus ? 'PointSpend Pro (Aktif ✨)' : 'Ücretsiz Plan (Free)',
                      style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      user.proStatus
                          ? 'Aboneliği yönet veya üyeliği sonlandır'
                          : 'Sınırsız ayrıcalıklar için Pro\'ya yükselt',
                      style: TextStyle(fontSize: 12, color: textColor.withValues(alpha: 0.6)),
                    ),
                    trailing: user.proStatus
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Yönet / İptal',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.redAccent,
                              ),
                            ),
                          )
                        : Icon(Icons.chevron_right_rounded, color: textColor.withValues(alpha: 0.4)),
                    onTap: () => PaywallDialog.show(context, userId),
                  ),
                ),

                const SizedBox(height: 24),
                // Security notice box
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1C1A10) : const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFD97706).withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.security_rounded, color: Color(0xFFD97706), size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Hesap ve güvenlik bilgileriniz şifrelenmiş olarak Firebase üzerinde korunmaktadır. Bilgilerinizi güncellediğinizde sonraki oturum açışlarınızda yeni bilgileriniz geçerli olacaktır.',
                          style: TextStyle(
                            fontSize: 12,
                            color: textColor.withValues(alpha: 0.75),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (onLogout != null) ...[
                  const SizedBox(height: 24),
                  Container(
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
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                      ),
                      title: const Text(
                        'Çıkış Yap',
                        style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Oturumu sonlandırır',
                        style: TextStyle(fontSize: 12, color: textColor.withValues(alpha: 0.6)),
                      ),
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
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                          onLogout!();
                        }
                      },
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvatar(String? photoUrl) {
    ImageProvider? provider;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      try {
        if (photoUrl.startsWith('data:image') || photoUrl.startsWith('base64,')) {
          final commaIndex = photoUrl.indexOf(',');
          final raw = commaIndex != -1 ? photoUrl.substring(commaIndex + 1) : photoUrl;
          provider = MemoryImage(base64Decode(raw));
        } else {
          provider = NetworkImage(photoUrl);
        }
      } catch (_) {}
    }

    if (provider != null) {
      return CircleAvatar(
        radius: 24,
        backgroundImage: provider,
      );
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.manage_accounts_rounded,
        color: Color(0xFF16A34A),
        size: 26,
      ),
    );
  }
}
