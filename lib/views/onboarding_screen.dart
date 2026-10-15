import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinish;

  const OnboardingScreen({super.key, required this.onFinish});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<_OnboardingItem> _items = [
    _OnboardingItem(
      icon: Icons.bolt_rounded,
      gradientColors: [Color(0xFF10B981), Color(0xFF047857)],
      glowColor: Color(0xFF10B981),
      stepTag: 'ADIM 1 / 3 • ALIŞKANLIK KAZAN',
      title: 'Aktivitelerini Belirle ve Alışkanlık Kazan',
      description:
          'Kendine günlük, haftalık veya isteğe bağlı görevler oluştur. Belirlediğin saatlerde hatırlatıcılar alarak hiçbir hedefini kaçırma.',
      bulletPoints: [
        'Günlük ve haftalık düzenli aktiviteler 📅',
        'Akıllı bildirimlerle tam vaktinde hatırlatıcı 🔔',
        'Her görev için özel puan değeri belirleme 🪙',
      ],
    ),
    _OnboardingItem(
      icon: Icons.local_fire_department_rounded,
      gradientColors: [Color(0xFFF97316), Color(0xFFC2410C)],
      glowColor: Color(0xFFF97316),
      stepTag: 'ADIM 2 / 3 • MOTİVASYONUNU KORU',
      title: 'Görevleri Tamamla, Puanları ve Seriyi Kap',
      description:
          'Aktivitelerini bitirdikçe tek dokunuşla puanlarını kap. Her gün görevlerini yaparak serini (Streak) büyüt ve alışkanlık zincirini kırma!',
      bulletPoints: [
        'Günlük seri (Streak) sayacı ile motivasyon 🔥',
        'Tamamladıkça cüzdanına eklenen anlık puanlar ⚡',
        'Profilinde detaylı başarı istatistikleri 📊',
      ],
    ),
    _OnboardingItem(
      icon: Icons.card_giftcard_rounded,
      gradientColors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
      glowColor: Color(0xFF8B5CF6),
      stepTag: 'ADIM 3 / 3 • KENDİNİ ÖDÜLLENDİR',
      title: 'Puanlarını Harca, Hayalindeki Ödülü Aç!',
      description:
          'Kendini ödüllendirmek istediğin şeyleri ekle (kahve, oyun, kitap veya tatil). Puanların biriktikçe kilitleri aç ve hak ettiğin ödülün tadını çıkar!',
      bulletPoints: [
        'Kendi kişiselleştirilmiş ödül havuzun 🎁',
        'Puan biriktirdikçe açılan özel kilitler 🔓',
        'Disiplinini somut ödüllerle taçlandırma 🎉',
      ],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _items.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onFinish();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Üst Bar: Logo ve "Geç" Butonu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.stars_rounded,
                          color: Color(0xFF16A34A),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'PointSpend',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  if (_currentPage < _items.length - 1)
                    TextButton(
                      onPressed: widget.onFinish,
                      style: TextButton.styleFrom(
                        foregroundColor: textColor.withValues(alpha: 0.6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      child: const Text(
                        'Geç',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    )
                  else
                    const SizedBox(width: 48),
                ],
              ),
            ),

            // Kaydırılabilir Kartlar Alanı
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _items.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return _buildPageCard(context, item, isDark, textColor);
                },
              ),
            ),

            // Alt Kontroller: Sayfa Noktaları ve İleri / Başla Butonu
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Geri Butonu (Sadece 1. sayfadan sonra)
                  if (_currentPage > 0)
                    IconButton.filledTonal(
                      onPressed: _prevPage,
                      icon: const Icon(Icons.arrow_back_rounded, size: 20),
                      style: IconButton.styleFrom(
                        backgroundColor: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF1F5F9),
                        foregroundColor: textColor,
                        padding: const EdgeInsets.all(12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 48),

                  // Sayfa Noktaları (Indicators)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(_items.length, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFF16A34A)
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.15)
                                  : Colors.black.withValues(alpha: 0.12)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),

                  // İleri veya Başla Butonu
                  ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currentPage == _items.length - 1 ? 'Başla' : 'İleri',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          _currentPage == _items.length - 1
                              ? Icons.rocket_launch_rounded
                              : Icons.arrow_forward_rounded,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageCard(
    BuildContext context,
    _OnboardingItem item,
    bool isDark,
    Color textColor,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          // Görsel Rozet / İkon Kutusu
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: item.gradientColors,
              ),
              borderRadius: BorderRadius.circular(36),
              boxShadow: [
                BoxShadow(
                  color: item.glowColor.withValues(alpha: 0.35),
                  blurRadius: 32,
                  spreadRadius: 2,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Icon(
              item.icon,
              size: 64,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),

          // Adım Etiketi
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: item.glowColor.withValues(alpha: isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: item.glowColor.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              item.stepTag,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isDark ? item.glowColor : const Color(0xFF166534),
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Başlık
          Text(
            item.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: textColor,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12),

          // Açıklama
          Text(
            item.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: textColor.withValues(alpha: 0.7),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          // Özellik Maddeleri (Bullet chips container)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E293B).withValues(alpha: 0.7)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            child: Column(
              children: item.bulletPoints.map((point) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF16A34A),
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          point,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textColor.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingItem {
  final IconData icon;
  final List<Color> gradientColors;
  final Color glowColor;
  final String stepTag;
  final String title;
  final String description;
  final List<String> bulletPoints;

  const _OnboardingItem({
    required this.icon,
    required this.gradientColors,
    required this.glowColor,
    required this.stepTag,
    required this.title,
    required this.description,
    required this.bulletPoints,
  });
}
