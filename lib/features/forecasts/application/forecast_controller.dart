import 'package:flutter/foundation.dart';
import '../../financial_health/domain/financial_engine.dart';
import '../data/forecast_repository.dart';
import '../domain/forecast.dart';
import '../domain/forecast_engine.dart';

class ForecastController extends ChangeNotifier {
  ForecastController({ForecastRepository? repository})
    : _repository = repository ?? ForecastRepository();

  final ForecastRepository _repository;

  bool _isLoading = false;
  String? _errorMessage;
  ForecastEvaluation _evaluation = ForecastEvaluation.insufficient();

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ForecastEvaluation get evaluation => _evaluation;
  List<Forecast> get forecasts => _evaluation.forecasts;

  /// Injects memory-only forecast evaluation for safe demo mode.
  void loadInMemoryEvaluation(ForecastEvaluation evaluation) {
    _evaluation = evaluation;
    _errorMessage = null;
    notifyListeners();
  }

  /// Runs deterministic forecasting engine against historical monthly buckets
  /// and persists forecast predictions into Supabase.
  Future<void> generateAndSyncForecasts({
    required String businessId,
    required List<MonthlyFinancialBucket> buckets,
    double startingCash = 0.0,
    String currency = 'USD',
    bool silent = false,
  }) async {
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final result = ForecastEngine.generateForecasts(
        businessId: businessId,
        historicalBuckets: buckets,
        startingCash: startingCash,
        currency: currency,
      );

      _evaluation = result;

      if (result.isSufficient && result.forecasts.isNotEmpty) {
        await _repository.saveForecasts(
          businessId: businessId,
          forecasts: result.forecasts,
        );
      }
    } catch (e) {
      _errorMessage = 'Failed to generate financial forecasts: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
