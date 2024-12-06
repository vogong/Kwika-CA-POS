class Settings {
  final String currencySymbol;
  final String currencyCode;
  final double taxRate;
  final bool taxInclusive;
  final String taxName;

  Settings({
    this.currencySymbol = '\$',
    this.currencyCode = 'USD',
    this.taxRate = 13.0,
    this.taxInclusive = false,
    this.taxName = 'HST',
  });

  Settings copyWith({
    String? currencySymbol,
    String? currencyCode,
    double? taxRate,
    bool? taxInclusive,
    String? taxName,
  }) {
    return Settings(
      currencySymbol: currencySymbol ?? this.currencySymbol,
      currencyCode: currencyCode ?? this.currencyCode,
      taxRate: taxRate ?? this.taxRate,
      taxInclusive: taxInclusive ?? this.taxInclusive,
      taxName: taxName ?? this.taxName,
    );
  }
}
