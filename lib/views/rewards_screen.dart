import 'package:flutter/material.dart';
import '../core/utils/url_launcher_helper.dart';
import '../models/reward.dart';
import '../services/reward_service.dart';
import 'widgets/reward_image_view.dart';

class RewardsScreen extends StatefulWidget {
  final String userId;

  const RewardsScreen({super.key, required this.userId});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  DateTime? _selectedDate;
  final RewardService _rewardService = RewardService();

  static const List<String> _turkishMonths = [
    '',
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
  ];

  String _formatDate(DateTime dt) {
    final day = dt.day;
    final month = _turkishMonths[dt.month];
    final year = dt.year;
    return '$day $month $year';
  }

  String _formatDateTime(DateTime dt) {
    final dateStr = _formatDate(dt);
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$dateStr, $hour:$minute';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(2020),
      lastDate: now,
      helpText: 'Ödül Tamamlanma Tarihi Seç',
      cancelText: 'İptal',
      confirmText: 'Filtrele',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF16A34A),
              brightness: Theme.of(context).brightness,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _showRewardDetail(BuildContext context, Reward rwd) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    final isDark = theme.brightness == Brightness.dark;
    final claimDate = rwd.claimedAt ?? rwd.createdAt ?? DateTime.now();

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
                _buildRewardThumbnail(rwd),
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
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '✓ Tamamlandı',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _infoRow(
              Icons.stars_rounded,
              'Harcanan Puan',
              '${rwd.requiredPoints} Puan',
              textColor,
            ),
            const SizedBox(height: 10),
            _infoRow(
              Icons.event_available_rounded,
              'Tamamlanma Tarihi',
              _formatDateTime(claimDate),
              textColor,
            ),
            if (rwd.optionalPrice != null) ...[
              const SizedBox(height: 10),
              _infoRow(
                Icons.payments_rounded,
                'Fiyat / Gerçek Değer',
                '${UrlLauncherHelper.formatPrice(rwd.optionalPrice!)} TL',
                textColor,
              ),
            ],
            if (rwd.optionalUrl != null && rwd.optionalUrl!.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              RewardLinkTile(
                url: rwd.optionalUrl!,
                textColor: textColor,
                isDark: isDark,
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Kapat',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, Color textColor) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF15803D)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 13, color: textColor.withValues(alpha: 0.6)),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onSurface;
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Tamamlanan Ödüller',
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0.5,
      ),
      body: StreamBuilder<List<Reward>>(
        stream: _rewardService.streamRewardsByUser(widget.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF15803D)),
            );
          }

          final allRewards = snapshot.data ?? [];
          // 1. Only completed/claimed rewards
          final allClaimed = allRewards.where((r) => r.claimed).toList();

          // 2. Sort newest first (en üstte en yeni tamamlanan ödüller)
          allClaimed.sort((a, b) {
            final dateA = a.claimedAt ?? a.createdAt ?? DateTime(2000);
            final dateB = b.claimedAt ?? b.createdAt ?? DateTime(2000);
            return dateB.compareTo(dateA);
          });

          // 3. Filter by date if selected
          final displayedRewards = _selectedDate == null
              ? allClaimed
              : allClaimed.where((r) {
                  final date = r.claimedAt ?? r.createdAt;
                  if (date == null) return false;
                  return _isSameDay(date, _selectedDate!);
                }).toList();

          return CustomScrollView(
            slivers: [
              // Date Filter Section at the top
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Filter title and quick chips
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_month_rounded,
                            size: 18,
                            color: const Color(0xFF16A34A),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Tarihe Göre Filtrele',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const Spacer(),
                          if (_selectedDate != null)
                            GestureDetector(
                              onTap: () => setState(() => _selectedDate = null),
                              child: Row(
                                children: [
                                  Text(
                                    'Temizle',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.red.shade600,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Icon(Icons.close_rounded, size: 14, color: Colors.red.shade600),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            // "Tümü" Chip
                            ChoiceChip(
                              label: const Text('Tüm Geçmiş'),
                              selected: _selectedDate == null,
                              selectedColor: const Color(0xFFDCFCE7),
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _selectedDate == null
                                    ? const Color(0xFF15803D)
                                    : textColor.withValues(alpha: 0.7),
                              ),
                              onSelected: (_) {
                                setState(() => _selectedDate = null);
                              },
                            ),
                            const SizedBox(width: 8),
                            // "Bugün" Chip
                            ChoiceChip(
                              label: const Text('Bugün'),
                              selected: _selectedDate != null && _isSameDay(_selectedDate!, now),
                              selectedColor: const Color(0xFFDCFCE7),
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: (_selectedDate != null && _isSameDay(_selectedDate!, now))
                                    ? const Color(0xFF15803D)
                                    : textColor.withValues(alpha: 0.7),
                              ),
                              onSelected: (_) {
                                setState(() => _selectedDate = now);
                              },
                            ),
                            const SizedBox(width: 8),
                            // "Dün" Chip
                            ChoiceChip(
                              label: const Text('Dün'),
                              selected: _selectedDate != null && _isSameDay(_selectedDate!, yesterday),
                              selectedColor: const Color(0xFFDCFCE7),
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: (_selectedDate != null && _isSameDay(_selectedDate!, yesterday))
                                    ? const Color(0xFF15803D)
                                    : textColor.withValues(alpha: 0.7),
                              ),
                              onSelected: (_) {
                                setState(() => _selectedDate = yesterday);
                              },
                            ),
                            const SizedBox(width: 8),
                            // Custom Date Picker Button / Chip
                            ActionChip(
                              avatar: const Icon(Icons.date_range_rounded, size: 16, color: Color(0xFF16A34A)),
                              label: Text(
                                _selectedDate != null &&
                                        !_isSameDay(_selectedDate!, now) &&
                                        !_isSameDay(_selectedDate!, yesterday)
                                    ? _formatDate(_selectedDate!)
                                    : 'Tarih Seç...',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: (_selectedDate != null &&
                                          !_isSameDay(_selectedDate!, now) &&
                                          !_isSameDay(_selectedDate!, yesterday))
                                      ? const Color(0xFF15803D)
                                      : textColor,
                                ),
                              ),
                              backgroundColor: (_selectedDate != null &&
                                      !_isSameDay(_selectedDate!, now) &&
                                      !_isSameDay(_selectedDate!, yesterday))
                                  ? const Color(0xFFDCFCE7)
                                  : null,
                              onPressed: () => _pickDate(context),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Summary box
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1C1A10) : const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFD97706).withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.history_rounded, color: Color(0xFFD97706), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedDate == null
                                    ? 'Toplam ${allClaimed.length} tamamlanan ödül geçmişi listeleniyor.'
                                    : '${_formatDate(_selectedDate!)} tarihinde tamamlanan ${displayedRewards.length} ödül bulundu.',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: textColor.withValues(alpha: 0.85),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Empty State Handling
              if (allClaimed.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFEF3C7),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.card_giftcard_rounded,
                              size: 56,
                              color: Color(0xFFD97706),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Henüz Tamamlanan Ödül Yok',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ana sayfadan puan biriktirip ödül kullandığında\ntüm geçmişin burada listelenecektir.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: textColor.withValues(alpha: 0.5),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (displayedRewards.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_busy_rounded,
                            size: 52,
                            color: textColor.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Bu Tarihte Ödül Bulunamadı',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${_formatDate(_selectedDate!)} tarihinde tamamlanmış ödül bulunmuyor.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: textColor.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () => setState(() => _selectedDate = null),
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('Tüm Geçmişi Göster'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                // List of Claimed Rewards
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final rwd = displayedRewards[index];
                        final claimDate = rwd.claimedAt ?? rwd.createdAt ?? DateTime.now();

                        return GestureDetector(
                          onTap: () => _showRewardDetail(context, rwd),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1C1A10) : const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFD97706).withValues(alpha: 0.35),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                _buildRewardThumbnail(rwd),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        rwd.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            '-${rwd.requiredPoints} Puan',
                                            style: const TextStyle(
                                              color: Color(0xFFD97706),
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.access_time_rounded,
                                            size: 12,
                                            color: textColor.withValues(alpha: 0.45),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _formatDateTime(claimDate),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: textColor.withValues(alpha: 0.55),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_rounded, color: Color(0xFF15803D), size: 14),
                                      SizedBox(width: 4),
                                      Text(
                                        'Tamamlandı',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF15803D),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: displayedRewards.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRewardThumbnail(Reward rwd) {
    final fallback = _buildFallbackIcon();
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
              color: const Color(0xFF15803D),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: const Icon(Icons.check, size: 10, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackIcon() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(
        Icons.check_circle_rounded,
        color: Color(0xFF15803D),
      ),
    );
  }
}
