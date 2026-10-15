import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/reward.dart';
import '../../services/purchase_service.dart';
import '../../services/reward_service.dart';
import '../../services/server_time_service.dart';
import '../../services/storage_service.dart';
import 'paywall_dialog.dart';

class AddRewardDialog extends StatefulWidget {
  final String userId;

  const AddRewardDialog({super.key, required this.userId});

  static Future<void> show(BuildContext context, String userId) async {
    final rewardService = RewardService();
    final purchaseService = PurchaseService();

    final rewards = await rewardService.getRewardsByUser(userId);
    final quota = await purchaseService.checkRewardAddQuota(userId, rewards);

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
      builder: (context) => AddRewardDialog(userId: userId),
    );
  }

  @override
  State<AddRewardDialog> createState() => _AddRewardDialogState();
}

class _AddRewardDialogState extends State<AddRewardDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _pointsController = TextEditingController(text: '300');
  final _priceController = TextEditingController();
  final _urlController = TextEditingController();

  XFile? _selectedImageFile;
  Uint8List? _selectedImageBytes;

  bool _isLoading = false;

  final RewardService _rewardService = RewardService();
  final PurchaseService _purchaseService = PurchaseService();
  final StorageService _storageService = StorageService();

  @override
  void dispose() {
    _titleController.dispose();
    _pointsController.dispose();
    _priceController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 600,
        maxHeight: 600,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _selectedImageFile = picked;
          _selectedImageBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Görsel seçme hatası: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final currentRewards = await _rewardService.getRewardsByUser(widget.userId);
      final quota = await _purchaseService.checkRewardAddQuota(widget.userId, currentRewards);

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

      String imageUrl = 'https://images.unsplash.com/photo-1513151233558-d860c5398176?w=500';

      if (_selectedImageFile != null) {
        final uploadedUrl = await _storageService.uploadRewardImage(_selectedImageFile!, widget.userId);
        if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
          imageUrl = uploadedUrl;
        }
      }

      final points = int.tryParse(_pointsController.text.trim()) ?? 100;
      final price = double.tryParse(_priceController.text.trim());
      final now = ServerTimeService.now;
      final newReward = Reward(
        id: now.millisecondsSinceEpoch.toString(),
        userId: widget.userId,
        title: _titleController.text.trim(),
        requiredPoints: points,
        imageUrl: imageUrl,
        optionalPrice: price,
        optionalUrl: _urlController.text.trim().isNotEmpty ? _urlController.text.trim() : null,
        claimed: false,
        createdAt: now,
      );

      await _rewardService.addReward(newReward);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${newReward.title}" ödülü eklendi! (${newReward.requiredPoints} Puan)'),
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
    final subtextColor = textColor.withValues(alpha: 0.6);

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
                    'Yeni Ödül Ekle',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Image Picker Widget
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 140,
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF16A34A).withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: _selectedImageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Stack(
                            children: [
                              Image.memory(
                                _selectedImageBytes!,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.edit, color: Colors.white, size: 18),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.add_a_photo_rounded,
                              size: 36,
                              color: Color(0xFF16A34A),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Ödül Fotoğrafı Yükle (Galeriden Seç)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: subtextColor,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _titleController,
                maxLength: 50,
                inputFormatters: [LengthLimitingTextInputFormatter(50)],
                buildCounter: (context, {required currentLength, required isFocused, maxLength}) => isFocused
                    ? Text('$currentLength/$maxLength', style: TextStyle(fontSize: 11, color: textColor.withValues(alpha: 0.5)))
                    : null,
                decoration: InputDecoration(
                  labelText: 'Ödül Adı (Örn: Sinema Bilet, Kahve, Kulaklık)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  prefixIcon: const Icon(Icons.card_giftcard_rounded),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Lütfen bir ödül adı girin';
                  if (val.trim().length < 2) return 'Ödül adı en az 2 karakter olmalıdır';
                  if (val.trim().length > 50) return 'Ödül adı en fazla 50 karakter olabilir';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pointsController,
                maxLength: 7,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(7),
                ],
                buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                decoration: InputDecoration(
                  labelText: 'Gereken Puan',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  prefixIcon: const Icon(Icons.stars_rounded, color: Color(0xFFEAB308)),
                  suffixText: 'Puan',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Gereken puanı giriniz';
                  final p = int.tryParse(val.trim());
                  if (p == null) return 'Geçerli sayı giriniz';
                  if (p <= 0) return 'Puan en az 1 olmalıdır';
                  if (p > 1000000) return 'Gereken puan en fazla 1.000.000 olabilir';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                maxLength: 10,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  LengthLimitingTextInputFormatter(10),
                ],
                buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                decoration: InputDecoration(
                  labelText: 'İsteğe Bağlı Gerçek Fiyat (TL)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  prefixIcon: const Icon(Icons.payments_outlined),
                ),
                validator: (val) {
                  if (val != null && val.trim().isNotEmpty) {
                    final price = double.tryParse(val.trim().replaceAll(',', '.'));
                    if (price == null || price < 0) return 'Geçerli fiyat giriniz';
                    if (price > 1000000) return 'Fiyat en fazla 1.000.000 TL olabilir';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _urlController,
                maxLength: 250,
                inputFormatters: [LengthLimitingTextInputFormatter(250)],
                buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                decoration: InputDecoration(
                  labelText: 'İsteğe Bağlı Ürün Linki (URL)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  prefixIcon: const Icon(Icons.link_rounded),
                ),
                validator: (val) {
                  if (val != null && val.trim().isNotEmpty) {
                    if (val.trim().length > 250) return 'URL en fazla 250 karakter olabilir';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF15803D),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            ),
                            SizedBox(width: 12),
                            Text('Görsel Yükleniyor & Kaydediliyor...'),
                          ],
                        )
                      : const Text('Ödülü Kaydet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
