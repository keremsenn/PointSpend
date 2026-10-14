import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants/app_strings.dart';
import '../services/activity_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/server_time_service.dart';
import 'activity_screen.dart';
import 'dialogs/add_activity_dialog.dart';
import 'dialogs/add_reward_dialog.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'rewards_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  String? _userId;
  bool _isCheckingSession = true;

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    ServerTimeService.instance.sync();
    _checkSavedSession();
  }

  /// Check if a valid 30-day session exists locally
  Future<void> _checkSavedSession() async {
    final savedUserId = await _authService.getValidSessionUserId();
    if (mounted) {
      setState(() {
        _userId = savedUserId;
        _isCheckingSession = false;
      });
      if (savedUserId != null) {
        _syncActivityReminders(savedUserId);
      }
    }
  }

  void _onLoginSuccess(String userId) {
    setState(() {
      _userId = userId;
    });
    _syncActivityReminders(userId);
  }

  Future<void> _syncActivityReminders(String userId) async {
    try {
      final activityService = ActivityService();
      final activities = await activityService.getActivitiesByUser(userId);
      final completedToday = await activityService.streamTodayCompletedActivityIds(userId).first;
      await NotificationService.instance.syncAllActivityReminders(activities, completedToday);
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Çıkış Yap', style: TextStyle(fontWeight: FontWeight.bold)),
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
        _selectedIndex = 0;
      });
    }
  }

  void _showAddSelectionModal(BuildContext context) {
    if (_userId == null) return;
    final theme = Theme.of(context);
    final cardBg = theme.cardColor;
    final textColor = theme.colorScheme.onSurface;

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ne Eklemek İstersin?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.bolt_rounded, color: Color(0xFF16A34A)),
              ),
              title: Text('Yeni Aktivite Ekle', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
              subtitle: Text('Tamamladıkça puan kazandıracak yeni bir görev', style: TextStyle(color: textColor.withValues(alpha: 0.6))),
              onTap: () {
                Navigator.pop(ctx);
                AddActivityDialog.show(context, _userId!);
              },
            ),
            Divider(color: theme.dividerColor),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.card_giftcard_rounded, color: Color(0xFFD97706)),
              ),
              title: Text('Yeni Ödül Ekle', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
              subtitle: Text('Puan biriktirdikçe açılacak gerçek hayat ödülü', style: TextStyle(color: textColor.withValues(alpha: 0.6))),
              onTap: () {
                Navigator.pop(ctx);
                AddRewardDialog.show(context, _userId!);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingSession) {
      return const Scaffold(
        backgroundColor: Color(0xFFF9FAFB),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF16A34A)),
              SizedBox(height: 16),
              Text('PointSpend Başlatılıyor...', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    if (_userId == null) {
      return LoginScreen(onLoginSuccess: _onLoginSuccess);
    }

    final pages = [
      HomeScreen(userId: _userId!),
      ActivityScreen(userId: _userId!),
      RewardsScreen(userId: _userId!),
      ProfileScreen(userId: _userId!, onLogout: _onLogout),
    ];

    return PopScope(
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
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddSelectionModal(context),
          backgroundColor: const Color(0xFF16A34A),
          foregroundColor: Colors.white,
          child: const Icon(Icons.add_rounded, size: 28),
        ),
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
}
