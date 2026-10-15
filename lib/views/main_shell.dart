import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants/app_strings.dart';
import '../models/activity.dart';
import '../models/activity_completion.dart';
import '../models/reward.dart';
import '../models/user_profile.dart';
import '../services/activity_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/reward_service.dart';
import '../services/server_time_service.dart';
import '../services/user_service.dart';
import 'activity_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';
import 'profile_screen.dart';
import 'rewards_screen.dart';
import 'splash_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  String? _userId;
  bool _isAppLoading = true;
  bool _showOnboarding = false;
  String _splashStatus = 'Veriler hazırlanıyor...';
  UserProfile? _preloadedUser;
  List<Activity>? _preloadedActivities;
  List<Reward>? _preloadedRewards;
  Map<String, ActivityCompletion>? _preloadedCompletions;

  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final ActivityService _activityService = ActivityService();
  final RewardService _rewardService = RewardService();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  /// Uygulama ilk açıldığında Splash Screen görünürken
  /// sunucu saatini, oturumu ve tüm anasayfa verilerini paralel olarak önceden yükler.
  Future<void> _initializeApp() async {
    final startTime = DateTime.now();

    try {
      // 1. Sunucu saatini senkronize et
      unawaited(ServerTimeService.instance.sync());

      // 2. Kayıtlı kullanıcı oturumunu kontrol et
      final savedUserId = await _authService.getValidSessionUserId();

      if (savedUserId != null) {
        _userId = savedUserId;

        // 3. Anasayfa verilerini paralel (eşzamanlı) olarak yükle
        final results = await Future.wait([
          // Kullanıcı profili (Mevcut puan, streak vb.)
          _userService.getUser(savedUserId).timeout(
                const Duration(seconds: 4),
                onTimeout: () => null,
              ),
          // Aktiviteler listesi
          _activityService.getActivitiesByUser(savedUserId).timeout(
                const Duration(seconds: 4),
                onTimeout: () => <Activity>[],
              ),
          // Ödüller listesi
          _rewardService.getRewardsByUser(savedUserId).timeout(
                const Duration(seconds: 4),
                onTimeout: () => <Reward>[],
              ),
          // Son tamamlanma durumları
          _activityService
              .streamLatestCompletionsByUser(savedUserId)
              .first
              .timeout(
                const Duration(seconds: 4),
                onTimeout: () => <String, ActivityCompletion>{},
              ),
        ]);

        _preloadedUser = results[0] as UserProfile?;
        _preloadedActivities = results[1] as List<Activity>?;
        _preloadedRewards = results[2] as List<Reward>?;
        _preloadedCompletions =
            results[3] as Map<String, ActivityCompletion>?;

        final activities = _preloadedActivities ?? <Activity>[];

        // Hatırlatıcı bildirimlerini arka planda senkronize et
        try {
          final completedToday = await _activityService
              .streamTodayCompletedActivityIds(savedUserId)
              .first
              .timeout(const Duration(seconds: 2), onTimeout: () => <String>{});
          await NotificationService.instance
              .syncAllActivityReminders(activities, completedToday);
        } catch (_) {}
      }
    } catch (_) {
      // Olası ağ gecikmesi veya hatasında güvenle devam et
    }

    // Splash ekranının görsel kalitesini hissettirmek için taban süre (en az 1 saniye)
    final elapsed = DateTime.now().difference(startTime).inMilliseconds;
    if (elapsed < 1000) {
      await Future.delayed(Duration(milliseconds: 1000 - elapsed));
    }

    // Arka plandaki tüm işlemler bitti: durumu güncelle
    if (mounted) {
      setState(() {
        _splashStatus = 'Hazır! ✨';
      });
    }

    // Kullanıcının talebi: Arka planda tüm işlemler bittikten sonra ek yarım saniye (500 ms) bekle
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() {
        _isAppLoading = false;
      });
    }
  }

  void _onLoginSuccess(String userId, {bool isNewUser = false}) {
    setState(() {
      _userId = userId;
      _showOnboarding = isNewUser;
    });
    if (!isNewUser) {
      _authService.setHasSeenOnboarding();
    }
    _syncActivityReminders(userId);
  }

  void _onOnboardingComplete() async {
    if (_userId != null) {
      try {
        await _userService.updateUser(_userId!, {'hasSeenOnboarding': true});
      } catch (_) {}
    }
    await _authService.setHasSeenOnboarding();
    if (mounted) {
      setState(() {
        _showOnboarding = false;
        if (_preloadedUser != null) {
          _preloadedUser = _preloadedUser!.copyWith(hasSeenOnboarding: true);
        }
      });
    }
  }

  Future<void> _syncActivityReminders(String userId) async {
    try {
      final activities = await _activityService.getActivitiesByUser(userId);
      final completedToday =
          await _activityService.streamTodayCompletedActivityIds(userId).first;
      await NotificationService.instance
          .syncAllActivityReminders(activities, completedToday);
    } catch (_) {}
  }

  Future<bool> _confirmExitApp() async {
    if (_selectedIndex != 0) {
      setState(() {
        _selectedIndex = 0;
      });
      return false;
    }

    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final textColor = theme.colorScheme.onSurface;
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.exit_to_app_rounded, color: Colors.redAccent),
              SizedBox(width: 10),
              Text('Çıkış Yap', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'Çıkış yapmak istediğinize emin misiniz?',
            style: TextStyle(fontSize: 14, color: textColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('İptal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Çıkış Yap',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    return shouldExit ?? false;
  }

  void _onLogout() async {
    await _authService.logout();
    if (mounted) {
      setState(() {
        _userId = null;
        _showOnboarding = false;
        _preloadedUser = null;
        _preloadedActivities = null;
        _preloadedRewards = null;
        _preloadedCompletions = null;
        _selectedIndex = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (_isAppLoading) {
      content = SplashScreen(
        key: const ValueKey('splash'),
        statusMessage: _splashStatus,
      );
    } else if (_userId == null) {
      // 1. Giriş yapılmamışsa DOĞRUDAN Giriş / Kayıt ekranı (ilk indirmede onboarding YOK!)
      content = LoginScreen(
        key: const ValueKey('login'),
        onLoginSuccess: _onLoginSuccess,
      );
    } else if (_showOnboarding) {
      // 2. YALNIZCA yeni kayıt olan kullanıcı hesaba girdiğinde onboarding görünür!
      content = OnboardingScreen(
        key: const ValueKey('onboarding'),
        onFinish: _onOnboardingComplete,
      );
    } else {
      // 3. Giriş yapmış kullanıcılar (eski kullanıcılar veya onboarding'i tamamlayanlar) DOĞRUDAN anasayfaya!
      final pages = [
        HomeScreen(
          userId: _userId!,
          initialUser: _preloadedUser,
          initialActivities: _preloadedActivities,
          initialRewards: _preloadedRewards,
          initialCompletions: _preloadedCompletions,
        ),
        ActivityScreen(userId: _userId!),
        RewardsScreen(userId: _userId!),
        ProfileScreen(userId: _userId!, onLogout: _onLogout),
      ];

      content = PopScope(
        key: const ValueKey('main_shell'),
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          final shouldExit = await _confirmExitApp();
          if (shouldExit) {
            SystemNavigator.pop();
          }
        },
        child: Scaffold(
          body: IndexedStack(index: _selectedIndex, children: pages),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (value) {
              setState(() {
                _selectedIndex = value;
              });
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: AppStrings.home,
              ),
              NavigationDestination(
                icon: Icon(Icons.fitness_center_outlined),
                selectedIcon: Icon(Icons.fitness_center_rounded),
                label: AppStrings.activity,
              ),
              NavigationDestination(
                icon: Icon(Icons.card_giftcard_outlined),
                selectedIcon: Icon(Icons.card_giftcard_rounded),
                label: AppStrings.rewards,
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person_rounded),
                label: AppStrings.profile,
              ),
            ],
          ),
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      child: content,
    );
  }
}
