import 'package:flutter/material.dart';
import '../../models/activity.dart';
import '../../services/activity_service.dart';
import '../../services/purchase_service.dart';
import '../../services/server_time_service.dart';
import 'paywall_dialog.dart';

class AddActivityDialog extends StatefulWidget {
  final String userId;

  const AddActivityDialog({super.key, required this.userId});

  static Future<void> show(BuildContext context, String userId) async {
    final activityService = ActivityService();
    final purchaseService = PurchaseService();

    final activities = await activityService.getActivitiesByUser(userId);
    final quota = await purchaseService.checkActivityAddQuota(userId, activities);

    if (!context.mounted) return;

    if (!quota.isAllowed) {
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
      return;
    }

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddActivityDialog(userId: userId),
    );
  }

  @override
  State<AddActivityDialog> createState() => _AddActivityDialogState();
}

class _AddActivityDialogState extends State<AddActivityDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _pointsController = TextEditingController(text: '25');
  String _frequency = 'daily';
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);
  bool _isLoading = false;

  final ActivityService _activityService = ActivityService();
  final PurchaseService _purchaseService = PurchaseService();

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF16A34A),
                brightness: Theme.of(context).brightness,
              ),
            ),
            child: child!,
          ),
        );
      },
    );
    if (picked != null) {
      setState(() => _reminderTime = picked);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final currentActivities = await _activityService.getActivitiesByUser(widget.userId);
      final quota = await _purchaseService.checkActivityAddQuota(widget.userId, currentActivities);

      if (!quota.isAllowed) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(quota.reason),
              backgroundColor: const Color(0xFFD97706),
              action: SnackBarAction(
                label: 'Pro\'ya Geç',
                textColor: Colors.white,
                onPressed: () => PaywallDialog.show(context, widget.userId),
              ),
              duration: const Duration(seconds: 4),
            ),
          );
          PaywallDialog.show(context, widget.userId);
        }
        return;
      }

      final points = int.tryParse(_pointsController.text.trim()) ?? 10;
      final now = ServerTimeService.now;
      final reminderStr = '${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}';
      final newActivity = Activity(
        id: now.millisecondsSinceEpoch.toString(),
        userId: widget.userId,
        title: _titleController.text.trim(),
        pointValue: points,
        frequency: _frequency,
        reminderTime: reminderStr,
        isActive: true,
        createdAt: now,
      );

      await _activityService.addActivity(newActivity);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${newActivity.title}" eklendi! (+${newActivity.pointValue} Puan)'),
            backgroundColor: const Color(0xFF16A34A),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final theme = Theme.of(context);
    final cardBg = theme.cardColor;
    final textColor = theme.colorScheme.onSurface;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: EdgeInsets.fromLTRB(24, 24, 24, bottomInset + 24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Yeni Aktivite Ekle',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Aktivite Adı (Örn: 30 dk Spor)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                prefixIcon: const Icon(Icons.fitness_center_rounded),
              ),
              validator: (val) => val == null || val.trim().isEmpty ? 'Lütfen bir ad girin' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _pointsController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Kazanılacak Puan',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                prefixIcon: const Icon(Icons.stars_rounded, color: Color(0xFFEAB308)),
                suffixText: 'Puan',
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Puan giriniz';
                if (int.tryParse(val.trim()) == null) return 'Geçerli sayı giriniz';
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _frequency,
              decoration: InputDecoration(
                labelText: 'Sıklık',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                prefixIcon: const Icon(Icons.repeat_rounded),
              ),
              items: const [
                DropdownMenuItem(value: 'daily', child: Text('Her Gün')),
                DropdownMenuItem(value: 'weekly', child: Text('Haftada Bir')),
                DropdownMenuItem(value: 'optional', child: Text('İsteğe Bağlı')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _frequency = val);
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickReminderTime,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.dividerColor),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.alarm_rounded, color: Color(0xFF16A34A)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Günlük Hatırlatıcı Bildirimi',
                            style: TextStyle(fontSize: 12, color: textColor.withValues(alpha: 0.6)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Her gün ${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF166534)),
                          SizedBox(width: 4),
                          Text(
                            'Saat Seç',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text('Kaydet ve Başla', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
