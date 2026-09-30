import '../models/offer_card.dart';
import '../models/point_transaction.dart';
import '../models/quick_action.dart';
import '../services/point_service.dart';

class HomeViewModel {
  const HomeViewModel();

  List<QuickAction> get quickActions => PointService.quickActions;
  List<OfferCard> get offers => PointService.offers;
  List<PointTransaction> get transactions => PointService.recentTransactions;
  int get balance => PointService.balance;
}
