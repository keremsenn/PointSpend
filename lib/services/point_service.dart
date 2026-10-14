import 'package:flutter/material.dart';

import '../models/offer_card.dart';
import '../models/point_transaction.dart';
import '../models/quick_action.dart';

class PointService {
  static const int balance = 8420;

  static final List<QuickAction> quickActions = [
    const QuickAction(
      id: 'qr_scan',
      icon: Icons.qr_code_scanner_rounded,
      label: 'QR Tara',
      route: '/qr-scan',
    ),
    const QuickAction(
      id: 'add_points',
      icon: Icons.card_giftcard_rounded,
      label: 'Puan Ekle',
      route: '/add-points',
    ),
    const QuickAction(
      id: 'spend',
      icon: Icons.sync_alt_rounded,
      label: 'Harcama',
      route: '/spend',
    ),
  ];

  static final List<OfferCard> offers = [
    OfferCard(
      id: 'market_25',
      title: '%25 Market İndirimi',
      description: 'Grocery kategorisinde geçerli',
      color: const Color(0xFFECFDF5),
      validUntil: DateTime.now().add(const Duration(days: 14)),
    ),
    OfferCard(
      id: 'double_points',
      title: '2x Puan Günü',
      description: 'Yemek & Kafe alanında',
      color: const Color(0xFFF0FDF4),
      validUntil: DateTime.now().add(const Duration(days: 21)),
    ),
  ];

  static final List<PointTransaction> recentTransactions = [
    PointTransaction(
      id: 'tx_001',
      title: 'Market alışverişi',
      subtitle: 'A101 • 1 saat önce',
      amount: '-240',
      type: TransactionType.expense,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    PointTransaction(
      id: 'tx_002',
      title: 'Yılbaşı bonusu',
      subtitle: 'Sistem • Dün',
      amount: '+600',
      type: TransactionType.income,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    PointTransaction(
      id: 'tx_003',
      title: 'Kafe kazancı',
      subtitle: 'Aroma Cafe • 3 gün önce',
      amount: '+180',
      type: TransactionType.income,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];
}
