import 'package:flutter/material.dart';

import '../models/offer_card.dart';
import '../models/point_transaction.dart';
import '../models/quick_action.dart';

class PointService {
  static const int balance = 8420;

  static const List<QuickAction> quickActions = [
    QuickAction(icon: Icons.qr_code_scanner_rounded, label: 'QR Tara'),
    QuickAction(icon: Icons.card_giftcard_rounded, label: 'Puan Ekle'),
    QuickAction(icon: Icons.sync_alt_rounded, label: 'Harcama'),
  ];

  static const List<OfferCard> offers = [
    OfferCard(
      title: '%25 Market İndirimi',
      description: 'Grocery kategorisinde geçerli',
      color: Color(0xFFECFDF5),
    ),
    OfferCard(
      title: '2x Puan Günü',
      description: 'Yemek & Kafe alanında',
      color: Color(0xFFF0FDF4),
    ),
  ];

  static const List<PointTransaction> recentTransactions = [
    PointTransaction(
      title: 'Market alışverişi',
      subtitle: 'A101 • 1 saat önce',
      amount: '-240',
      type: TransactionType.expense,
    ),
    PointTransaction(
      title: 'Yılbaşı bonusu',
      subtitle: 'Sistem • Dün',
      amount: '+600',
      type: TransactionType.income,
    ),
    PointTransaction(
      title: 'Kafe kazancı',
      subtitle: 'Aroma Cafe • 3 gün önce',
      amount: '+180',
      type: TransactionType.income,
    ),
  ];
}
