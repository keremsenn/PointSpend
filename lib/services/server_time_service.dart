import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Professional, tamper-proof Server Time Service.
/// Synchronizes with atomic Google/server clocks and uses a monotonic CPU Stopwatch
/// to prevent device clock manipulation (changing phone date/time forward or backward).
class ServerTimeService {
  static final ServerTimeService _instance = ServerTimeService._internal();
  static ServerTimeService get instance => _instance;

  ServerTimeService._internal();

  DateTime? _syncedServerUtc;
  final Stopwatch _stopwatch = Stopwatch();
  bool _isSyncing = false;

  /// Global accessor: returns the current synchronized server time in local timezone.
  /// If server time hasn't synced yet or app is offline, safely falls back to [DateTime.now()].
  static DateTime get now => instance.currentLocalTime;

  DateTime get currentLocalTime {
    if (_syncedServerUtc != null) {
      final currentUtc = _syncedServerUtc!.add(_stopwatch.elapsed);
      return currentUtc.toLocal();
    }
    return DateTime.now();
  }

  /// Check whether server time has been successfully synchronized.
  bool get isSynced => _syncedServerUtc != null;

  /// Synchronize with trusted atomic server clocks via lightweight HTTP HEAD request.
  Future<bool> sync() async {
    if (_isSyncing) return isSynced;
    _isSyncing = true;

    final endpoints = [
      'https://www.google.com',
      'https://firebase.google.com',
      'https://cloudflare.com',
    ];

    for (final url in endpoints) {
      try {
        final client = HttpClient();
        client.connectionTimeout = const Duration(seconds: 3);
        final request = await client.headUrl(Uri.parse(url));
        final response = await request.close();
        final dateHeader = response.headers.value(HttpHeaders.dateHeader);
        client.close();

        if (dateHeader != null && dateHeader.isNotEmpty) {
          final parsedDate = HttpDate.parse(dateHeader);
          _syncedServerUtc = parsedDate.toUtc();
          _stopwatch.reset();
          _stopwatch.start();
          _isSyncing = false;
          if (kDebugMode) {
            print('ServerTimeService: Synced with $url -> ${_syncedServerUtc!.toLocal()}');
          }
          return true;
        }
      } catch (e) {
        if (kDebugMode) {
          print('ServerTimeService: Sync failed for $url: $e');
        }
      }
    }

    _isSyncing = false;
    return false;
  }
}
