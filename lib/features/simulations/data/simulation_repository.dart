import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/simulation.dart';

class SimulationRepository {
  SimulationRepository({SupabaseClient? client}) : _injectedClient = client;

  final SupabaseClient? _injectedClient;
  SupabaseClient get _client => _injectedClient ?? Supabase.instance.client;

  /// Retrieves all saved simulations for a business ordered by most recent.
  Future<List<Simulation>> getSimulations({required String businessId}) async {
    final response = await _client
        .from('simulations')
        .select()
        .eq('business_id', businessId)
        .order('created_at', ascending: false);

    final list = response as List<dynamic>;
    return list
        .map((json) => Simulation.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Saves a new simulation record.
  Future<Simulation> saveSimulation({
    required String businessId,
    required String userId,
    required String name,
    required Map<String, dynamic> assumptions,
    required Map<String, dynamic> baselineMetrics,
    required Map<String, dynamic> projectedMetrics,
    String? aiAnalysis,
  }) async {
    final payload = {
      'business_id': businessId,
      'user_id': userId,
      'name': name,
      'assumptions': assumptions,
      'baseline_metrics': baselineMetrics,
      'projected_metrics': projectedMetrics,
      'ai_analysis': ?aiAnalysis,
    };

    final response = await _client
        .from('simulations')
        .insert(payload)
        .select()
        .single();

    return Simulation.fromJson(response);
  }

  /// Deletes a simulation by id.
  Future<void> deleteSimulation({required String simulationId}) async {
    await _client.from('simulations').delete().eq('id', simulationId);
  }
}
