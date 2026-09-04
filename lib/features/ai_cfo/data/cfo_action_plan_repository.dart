import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/cfo_action_item.dart';

class CfoActionPlanRepository {
  CfoActionPlanRepository({SupabaseClient? client}) : _injectedClient = client;

  final SupabaseClient? _injectedClient;
  SupabaseClient get _client => _injectedClient ?? Supabase.instance.client;

  Future<List<CfoActionItem>> getActionItems(String businessId) async {
    try {
      final response = await _client
          .from('cfo_action_items')
          .select()
          .eq('business_id', businessId)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((json) => CfoActionItem.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (_) {
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<CfoActionItem?> saveActionItem(CfoActionItem item) async {
    try {
      final response = await _client
          .from('cfo_action_items')
          .upsert(item.toJson())
          .select()
          .single();

      return CfoActionItem.fromJson(response);
    } catch (_) {
      return item;
    }
  }
}
