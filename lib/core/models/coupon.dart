class Coupon {
  final String code;
  final double amount;
  final String description;
  final bool isPercentage;

  Coupon({
    required this.code,
    required this.amount,
    required this.description,
    this.isPercentage = false,
  });

  double calculateDiscount(double subtotal) {
    if (isPercentage) {
      return subtotal * (amount / 100);
    }
    return amount;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Coupon &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;
}
