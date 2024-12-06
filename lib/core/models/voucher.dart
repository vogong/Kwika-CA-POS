class Voucher {
  final String id;
  final String name;
  final String description;
  final double value;
  final String imageUrl;
  final bool isPercentage;
  final bool isActive;

  Voucher({
    required this.id,
    required this.name,
    required this.description,
    required this.value,
    this.imageUrl = '',
    this.isPercentage = false,
    this.isActive = true,
  });

  factory Voucher.fromJson(Map<String, dynamic> json) {
    return Voucher(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      value: (json['value'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String? ?? '',
      isPercentage: json['isPercentage'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'value': value,
      'imageUrl': imageUrl,
      'isPercentage': isPercentage,
      'isActive': isActive,
    };
  }
}
