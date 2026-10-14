import 'package:flutter/material.dart';
import '../models/activity_completion.dart';
import '../services/activity_service.dart';

class ActivityScreen extends StatefulWidget {
  final String userId;

  const ActivityScreen({super.key, required this.userId});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  DateTime? _selectedDate;
  final ActivityService _activityService = ActivityService();

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
      helpText: 'Aktivite Tamamlanma Tarihi Seç',
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

  void _showCompletionDetail(BuildContext context, ActivityCompletion comp) {
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
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    color: Color(0xFF16A34A),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comp.activityTitle ?? 'Tamamlanan Aktivite',
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
              'Kazanılan Puan',
              '+${comp.earnedPoints} Puan',
              textColor,
            ),
            const SizedBox(height: 10),
            _infoRow(
              Icons.event_available_rounded,
              'Tamamlanma Tarihi',
              _formatDateTime(comp.completionDate),
              textColor,
            ),
            if (comp.optionalNote != null && comp.optionalNote!.isNotEmpty) ...[
              const SizedBox(height: 10),
              _infoRow(
                Icons.notes_rounded,
                'Ekstra Not',
                comp.optionalNote!,
                textColor,
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
        Icon(icon, size: 18, color: const Color(0xFF16A34A)),
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
          'Tamamlanan Aktiviteler',
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0.5,
      ),
      body: StreamBuilder<List<ActivityCompletion>>(
        stream: _activityService.streamAllCompletions(widget.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF16A34A)),
            );
          }

          final allCompletions = snapshot.data ?? [];

          // Sort newest first
          allCompletions.sort((a, b) => b.completionDate.compareTo(a.completionDate));

          // Filter by date if selected
          final displayedCompletions = _selectedDate == null
              ? allCompletions
              : allCompletions.where((c) => _isSameDay(c.completionDate, _selectedDate!)).toList();

          return CustomScrollView(
            slivers: [
              // Date Filter Section at the top
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Filter title and clear option
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_month_rounded,
                            size: 18,
                            color: Color(0xFF16A34A),
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
                          color: isDark ? const Color(0xFF14241B) : const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF16A34A).withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.history_rounded, color: Color(0xFF16A34A), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedDate == null
                                    ? 'Toplam ${allCompletions.length} tamamlanan aktivite geçmişi listeleniyor.'
                                    : '${_formatDate(_selectedDate!)} tarihinde tamamlanan ${displayedCompletions.length} aktivite bulundu.',
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
              if (allCompletions.isEmpty)
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
                              color: Color(0xFFDCFCE7),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.bolt_rounded,
                              size: 56,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Henüz Tamamlanan Aktivite Yok',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ana sayfadan aktivitelerini tamamladıkça\ntüm geçmişin burada listelenecektir.',
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
              else if (displayedCompletions.isEmpty)
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
                            'Bu Tarihte Aktivite Bulunamadı',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${_formatDate(_selectedDate!)} tarihinde tamamlanmış aktivite bulunmuyor.',
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
                // List of Completions
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final comp = displayedCompletions[index];

                        return GestureDetector(
                          onTap: () => _showCompletionDetail(context, comp),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF14241B) : const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF16A34A).withValues(alpha: 0.35),
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
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.bolt_rounded,
                                    color: Color(0xFF16A34A),
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        comp.activityTitle ?? 'Aktivite',
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
                                            '+${comp.earnedPoints} Puan',
                                            style: const TextStyle(
                                              color: Color(0xFF16A34A),
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
                                            ),
                                          ),
                                          if (comp.optionalNote != null &&
                                              comp.optionalNote!.isNotEmpty) ...[
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                '• ${comp.optionalNote!}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: textColor.withValues(alpha: 0.5),
                                                ),
                                              ),
                                            ),
                                          ],
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
                                            _formatDateTime(comp.completionDate),
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
                      childCount: displayedCompletions.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
