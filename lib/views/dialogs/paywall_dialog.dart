import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../services/purchase_service.dart';
import '../../services/user_service.dart';

class PaywallDialog extends StatefulWidget {
  final String userId;

  const PaywallDialog({super.key, required this.userId});

  static Future<bool?> show(BuildContext context, String userId) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PaywallDialog(userId: userId),
    );
  }

  @override
  State<PaywallDialog> createState() => _PaywallDialogState();
}

class _PaywallDialogState extends State<PaywallDialog> {
  bool _isLoading = false;
  final PurchaseService _purchaseService = PurchaseService();
  final UserService _userService = UserService();

  Future<void> _handlePurchase() async {
    setState(() => _isLoading = true);
    try {
      final success = await _purchaseService.purchasePro(widget.userId);
      if (mounted) {
        if (success) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tebrikler! PointSpend Pro üyeliğiniz aktif edildi! 🎉'),
              backgroundColor: Color(0xFF16A34A),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Satın alma tamamlanamadı.'), backgroundColor: Colors.red),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleCancelSubscription() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
            SizedBox(width: 10),
            Text('Üyeliği Sonlandır', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PointSpend Pro üyeliğinizi iptal etmek istediğinize emin misiniz?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            SizedBox(height: 12),
            Text(
              'Üyeliğinizi sonlandırdığınızda:\n'
              '• Günlük sınırsız aktivite ekleme hakkı biter (Günde max 3)\n'
              '• Günlük sınırsız ödül ekleme hakkı biter (Günde max 3)\n'
              '• Günlük sınırsız aktivite tamamlama hakkı biter (Günde max 3)\n\n'
              'Hesabınız anında Ücretsiz plana geçirilecektir.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx, false),
            child: const Text('Vazgeç', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dCtx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Evet, Sonlandır', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final success = await _purchaseService.cancelProSubscription(widget.userId);
      if (mounted) {
        if (success) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pro üyeliğiniz sonlandırıldı. Ücretsiz plana geçildi.'),
              backgroundColor: Color(0xFFD97706),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('İptal işlemi tamamlanamadı.'), backgroundColor: Colors.red),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year;
    return '$d.$m.$y';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardBg = theme.cardColor;
    final textColor = theme.colorScheme.onSurface;
    final subtextColor = textColor.withValues(alpha: 0.7);

    return StreamBuilder<UserProfile>(
      stream: _userService.watchUser(widget.userId),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final isPro = user?.proStatus ?? false;

        final startDate = user?.proStartDate ?? user?.createdAt ?? DateTime.now();
        final endDate = user?.proEndDate ?? startDate.add(const Duration(days: 365));

        return Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Crown Header Icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: isPro ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    Icons.workspace_premium_rounded,
                    size: 44,
                    color: isPro ? const Color(0xFF166534) : const Color(0xFFD97706),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isPro ? 'PointSpend Pro Üyeliğiniz' : 'PointSpend Pro',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isPro
                      ? 'Sınırsız ayrıcalıkların ve Pro avantajların keyfini çıkarıyorsunuz.'
                      : 'Limitlere takılmadan hedeflerine ulaş!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: subtextColor),
                ),
                const SizedBox(height: 24),

                if (isPro) ...[
                  // Pro Subscription Details Card (Dates & Status)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Abonelik Durumu',
                              style: TextStyle(fontSize: 13, color: subtextColor, fontWeight: FontWeight.w500),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Aktif ✨',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Başlangıç Tarihi', style: TextStyle(fontSize: 12, color: subtextColor)),
                                const SizedBox(height: 2),
                                Text(
                                  _formatDate(startDate),
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Bitiş / Yenileme Tarihi', style: TextStyle(fontSize: 12, color: subtextColor)),
                                const SizedBox(height: 2),
                                Text(
                                  _formatDate(endDate),
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Features List
                _buildFeatureRow(Icons.check_circle_rounded, 'Sınırsız Aktivite Ekleme (Free: Günlük 3)', textColor),
                const SizedBox(height: 12),
                _buildFeatureRow(Icons.check_circle_rounded, 'Sınırsız Ödül Ekleme (Free: Günlük 3)', textColor),
                const SizedBox(height: 12),
                _buildFeatureRow(Icons.check_circle_rounded, 'Sınırsız Aktivite Tamamlama (Free: Günlük 3)', textColor),
                const SizedBox(height: 12),
                _buildFeatureRow(Icons.check_circle_rounded, 'Gelişmiş İstatistikler ve Streak Takibi', textColor),
                const SizedBox(height: 12),
                _buildFeatureRow(Icons.check_circle_rounded, 'Öncelikli Bildirimler & Özel Destek', textColor),
                const SizedBox(height: 24),

                if (!isPro) ...[
                  // Price Tag (For non-Pro users)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Yıllık / Tek Seferlik Pro', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                            const SizedBox(height: 2),
                            Text('RevenueCat Güvenli Ödeme', style: TextStyle(fontSize: 12, color: subtextColor)),
                          ],
                        ),
                        const Text(
                          '₺99.99',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF16A34A)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handlePurchase,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Text('Pro\'ya Yükselt', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Şimdilik Geç', style: TextStyle(color: subtextColor)),
                  ),
                ] else ...[
                  // Pro Member Actions
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: const Text('Tamam', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _handleCancelSubscription,
                      icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 20),
                      label: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.redAccent, strokeWidth: 2),
                            )
                          : const Text(
                              'Üyeliği Sonlandır / İptal Et',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.6), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, Color textColor) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF16A34A), size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
          ),
        ),
      ],
    );
  }
}
