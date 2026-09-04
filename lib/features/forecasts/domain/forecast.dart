enum ForecastType { revenue, expenses, cashFlow, cashBalance }

class Forecast {
  const Forecast({
    required this.id,
    required this.businessId,
    required this.forecastType,
    required this.forecastDate,
    required this.predictedValue,
    this.lowerBound,
    this.upperBound,
    this.confidence,
    this.modelVersion = '1.0.0',
    required this.createdAt,
  });

  factory Forecast.fromJson(Map<String, dynamic> json) {
    return Forecast(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      forecastType: _forecastTypeFromString(json['forecast_type'] as String),
      forecastDate: DateTime.parse(json['forecast_date'] as String),
      predictedValue: (json['predicted_value'] as num).toDouble(),
      lowerBound: (json['lower_bound'] as num?)?.toDouble(),
      upperBound: (json['upper_bound'] as num?)?.toDouble(),
      confidence: (json['confidence'] as num?)?.toDouble(),
      modelVersion: (json['model_version'] as String?) ?? '1.0.0',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final String id;
  final String businessId;
  final ForecastType forecastType;
  final DateTime forecastDate;
  final double predictedValue;
  final double? lowerBound;
  final double? upperBound;
  final double? confidence;
  final String modelVersion;
  final DateTime createdAt;

  static ForecastType _forecastTypeFromString(String val) {
    switch (val) {
      case 'revenue':
        return ForecastType.revenue;
      case 'expenses':
        return ForecastType.expenses;
      case 'cash_flow':
        return ForecastType.cashFlow;
      case 'cash_balance':
        return ForecastType.cashBalance;
      default:
        return ForecastType.revenue;
    }
  }

  static String _forecastTypeToString(ForecastType type) {
    switch (type) {
      case ForecastType.revenue:
        return 'revenue';
      case ForecastType.expenses:
        return 'expenses';
      case ForecastType.cashFlow:
        return 'cash_flow';
      case ForecastType.cashBalance:
        return 'cash_balance';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'forecast_type': _forecastTypeToString(forecastType),
      'forecast_date': forecastDate.toIso8601String().split('T').first,
      'predicted_value': predictedValue,
      'lower_bound': lowerBound,
      'upper_bound': upperBound,
      'confidence': confidence,
      'model_version': modelVersion,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
