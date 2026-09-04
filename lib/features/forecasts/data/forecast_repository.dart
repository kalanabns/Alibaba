import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/forecast.dart';

class ForecastRepository {
  ForecastRepository({SupabaseClient? client}) : _injectedClient = client;

  final SupabaseClient? _injectedClient;
  SupabaseClient get _client => _injectedClient ?? Supabase.instance.client;

  /// Retrieves forecasts for a business.
  Future<List<Forecast>> getForecasts({required String businessId}) async {
    final response = await _client
        .from('forecasts')
        .select()
        .eq('business_id', businessId)
        .order('forecast_date', ascending: true);

    final list = response as List<dynamic>;
    return list
        .map((json) => Forecast.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Replaces existing forecasts with fresh evaluated forecasts.
  Future<void> saveForecasts({
    required String businessId,
    required List<Forecast> forecasts,
  }) async {
    if (forecasts.isEmpty) return;

    // Remove existing forecasts for this business
    await _client.from('forecasts').delete().eq('business_id', businessId);

    final payload = forecasts.map((f) {
      final json = f.toJson();
      json.remove('id'); // Let DB generate new UUID
      return json;
    }).toList();

    await _client.from('forecasts').insert(payload);
  }
}
