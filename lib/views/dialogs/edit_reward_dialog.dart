import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/reward.dart';
import '../../services/reward_service.dart';
import '../../services/storage_service.dart';
import '../widgets/reward_image_view.dart';

class EditRewardDialog extends StatefulWidget {
  final Reward reward;

  const EditRewardDialog({super.key, required this.reward});

  static Future<void> show(BuildContext context, Reward reward) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditRewardDialog(reward: reward),
    );
  }

  @override
  State<EditRewardDialog> createState() => _EditRewardDialogState();
}

class _EditRewardDialogState extends State<EditRewardDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _pointsController;
  late final TextEditingController _priceController;
  late final TextEditingController _urlController;

  XFile? _selectedImageFile;
  Uint8List? _selectedImageBytes;
  bool _isLoading = false;

  final RewardService _rewardService = RewardService();
  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.reward.title);
    _pointsController = TextEditingController(text: widget.reward.requiredPoints.toString());
    _priceController = TextEditingController(
      text: widget.reward.optionalPrice != null ? widget.reward.optionalPrice.toString() : '',
    );
    _urlController = TextEditingController(text: widget.reward.optionalUrl ?? '');
  }

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
      String imageUrl = widget.reward.imageUrl;

      if (_selectedImageFile != null) {
        final uploadedUrl = await _storageService.uploadRewardImage(
          _selectedImageFile!,
          widget.reward.userId,
        );
        if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
          imageUrl = uploadedUrl;
        }
      }

      final points = int.tryParse(_pointsController.text.trim()) ?? widget.reward.requiredPoints;
      final price = double.tryParse(_priceController.text.trim());
      final rawUrl = _urlController.text.trim();

      final updated = widget.reward.copyWith(
        title: _titleController.text.trim(),
        requiredPoints: points,
        imageUrl: imageUrl,
        optionalPrice: price,
        optionalUrl: rawUrl.isNotEmpty ? rawUrl : null,
      );

      await _rewardService.updateReward(updated);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${updated.title}" ödülü güncellendi! (${updated.requiredPoints} Puan)'),
            backgroundColor: const Color(0xFF16A34A),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Güncelleme hatası: $e'), backgroundColor: Colors.red),
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
    final subtextColor = textColor.withValues(alpha: 0.7);

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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.edit_rounded, color: Color(0xFF16A34A), size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Ödülü Düzenle',
                        style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: textColor),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Image Picker / Preview Widget
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
                      : (widget.reward.imageUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Stack(
                                children: [
                                  RewardImageView(
                                    imageUrl: widget.reward.imageUrl,
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                    fallback: Center(
                                      child: Icon(Icons.card_giftcard_rounded, size: 40, color: subtextColor),
                                    ),
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
                                  'Ödül Fotoğrafı Seç (Galeriden Değiştir)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: subtextColor,
                                  ),
                                ),
                              ],
                            )),
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
                  labelText: 'Ödül Adı (Örn: Sinema Bileti)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  prefixIcon: const Icon(Icons.card_giftcard_rounded),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Lütfen bir ad girin';
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
                  if (val == null || val.trim().isEmpty) return 'Puan giriniz';
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
                  labelText: 'Fiyat / Maliyet (Opsiyonel)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  prefixIcon: const Icon(Icons.attach_money_rounded, color: Color(0xFF16A34A)),
                  suffixText: '₺',
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
                keyboardType: TextInputType.url,
                inputFormatters: [LengthLimitingTextInputFormatter(250)],
                buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                decoration: InputDecoration(
                  labelText: 'Ürün / Satın Alma Linki (Opsiyonel)',
                  hintText: 'https://...',
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
                      : const Text('Değişiklikleri Kaydet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
