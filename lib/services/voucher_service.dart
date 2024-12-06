import '../core/models/voucher.dart';

class VoucherService {
  // Simulated voucher data
  final List<Voucher> _vouchers = [
    Voucher(
      id: 'V001',
      name: 'Birthday Special',
      description: 'Special birthday discount voucher',
      value: 15.0,
      isPercentage: true,
      imageUrl: 'assets/images/birthday.png',
    ),
    Voucher(
      id: 'V002',
      name: 'Loyalty Reward',
      description: '\$25 off your purchase',
      value: 25.0,
      imageUrl: 'assets/images/loyalty.png',
    ),
    Voucher(
      id: 'V003',
      name: 'Holiday Bundle',
      description: '20% off holiday items',
      value: 20.0,
      isPercentage: true,
      imageUrl: 'assets/images/holiday.png',
    ),
    Voucher(
      id: 'V004',
      name: 'Welcome Gift',
      description: '\$10 off first purchase',
      value: 10.0,
      imageUrl: 'assets/images/welcome.png',
    ),
    Voucher(
      id: 'V005',
      name: 'VIP Member',
      description: '30% off premium items',
      value: 30.0,
      isPercentage: true,
      imageUrl: 'assets/images/vip.png',
    ),
  ];

  Future<List<Voucher>> getVouchers() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    return _vouchers;
  }

  Future<Voucher?> getVoucherById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _vouchers.firstWhere(
      (voucher) => voucher.id == id,
      orElse: () => throw Exception('Voucher not found'),
    );
  }
}
