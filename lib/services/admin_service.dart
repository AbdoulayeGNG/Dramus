import 'package:flutter/foundation.dart';

class AdminStatistics {
  final int totalListings;
  final int totalSaleListings;
  final int totalRentListings;
  final int totalUsers;
  final int totalAgents;
  final int totalAgencies;
  final double totalTransactionValue;
  final int premiumListings;
  final double averagePropertyPrice;
  final int monthlyNewListings;

  AdminStatistics({
    required this.totalListings,
    required this.totalSaleListings,
    required this.totalRentListings,
    required this.totalUsers,
    required this.totalAgents,
    required this.totalAgencies,
    required this.totalTransactionValue,
    required this.premiumListings,
    required this.averagePropertyPrice,
    required this.monthlyNewListings,
  });
}

class AdminService extends ChangeNotifier {
  late AdminStatistics _statistics;

  AdminService() {
    _initializeStatistics();
  }

  AdminStatistics get statistics => _statistics;

  void _initializeStatistics() {
    _statistics = AdminStatistics(
      totalListings: 2847,
      totalSaleListings: 1523,
      totalRentListings: 1324,
      totalUsers: 5420,
      totalAgents: 234,
      totalAgencies: 45,
      totalTransactionValue: 185000000,
      premiumListings: 456,
      averagePropertyPrice: 650000,
      monthlyNewListings: 342,
    );
  }

  List<MapEntry<String, int>> getSalesData() {
    return [
      MapEntry('Jan', 45),
      MapEntry('Fév', 52),
      MapEntry('Mar', 48),
      MapEntry('Avr', 61),
      MapEntry('Mai', 55),
      MapEntry('Juin', 67),
      MapEntry('Juil', 72),
      MapEntry('Août', 68),
      MapEntry('Sep', 74),
      MapEntry('Oct', 71),
      MapEntry('Nov', 65),
      MapEntry('Déc', 59),
    ];
  }

  List<MapEntry<String, double>> getPropertyTypeDistribution() {
    return [
      MapEntry('Appartements', 35.5),
      MapEntry('Villas', 28.3),
      MapEntry('Maisons', 22.1),
      MapEntry('Bureaux', 14.1),
    ];
  }

  List<MapEntry<String, int>> getUserActivity() {
    return [
      MapEntry('Conakry', 3245),
      MapEntry('Kindia', 856),
      MapEntry('Mamou', 432),
      MapEntry('Kindia', 289),
      MapEntry('Autre', 598),
    ];
  }
}
