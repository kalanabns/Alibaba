class Business {
  const Business({
    required this.id,
    required this.ownerId,
    required this.name,
    this.industry,
    this.country,
    this.currency = 'USD',
    this.fiscalYearStartMonth = 1,
    this.startingCash = 0.0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String,
      industry: json['industry'] as String?,
      country: json['country'] as String?,
      currency: (json['currency'] as String?) ?? 'USD',
      fiscalYearStartMonth: (json['fiscal_year_start_month'] as num?)?.toInt() ?? 1,
      startingCash: (json['starting_cash'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  final String id;
  final String ownerId;
  final String name;
  final String? industry;
  final String? country;
  final String currency;
  final int fiscalYearStartMonth;
  final double startingCash;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'name': name,
      'industry': industry,
      'country': country,
      'currency': currency,
      'fiscal_year_start_month': fiscalYearStartMonth,
      'starting_cash': startingCash,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
