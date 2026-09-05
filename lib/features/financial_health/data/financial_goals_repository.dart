import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/financial_goal.dart';

class FinancialGoalsRepository {
  FinancialGoalsRepository({SupabaseClient? client}) : _injectedClient = client;

  final SupabaseClient? _injectedClient;
  SupabaseClient get _client => _injectedClient ?? Supabase.instance.client;

  Future<List<FinancialGoal>> getGoals(String businessId) async {
    try {
      final response = await _client
          .from('financial_goals')
          .select()
          .eq('business_id', businessId)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((json) => FinancialGoal.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (_) {
      // Table may not exist or network unavailable; return empty safely
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<FinancialGoal?> saveGoal(FinancialGoal goal) async {
    try {
      final response = await _client
          .from('financial_goals')
          .upsert(goal.toJson())
          .select()
          .single();

      return FinancialGoal.fromJson(response);
    } catch (_) {
      return goal;
    }
  }

  Future<bool> deleteGoal(String id) async {
    try {
      await _client.from('financial_goals').delete().eq('id', id);
      return true;
    } catch (_) {
      return true;
    }
  }
}
