import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/business.dart';

class BusinessRepository {
  BusinessRepository({SupabaseClient? client}) : _injectedClient = client;

  final SupabaseClient? _injectedClient;
  SupabaseClient get _client => _injectedClient ?? Supabase.instance.client;

  Future<Business?> getCurrentUserBusiness() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _client
          .from('businesses')
          .select()
          .eq('owner_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return Business.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Database query error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to load business profile. Please try again.');
    }
  }

  Future<Business> createBusiness({
    required String name,
    required String industry,
    required String country,
    required String currency,
    required int fiscalYearStartMonth,
    required double startingCash,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception(
        'Authenticated user session required to create a business.',
      );
    }

    try {
      final response = await _client
          .from('businesses')
          .insert({
            'owner_id': userId,
            'name': name.trim(),
            'industry': industry.trim(),
            'country': country.trim(),
            'currency': currency.trim().toUpperCase(),
            'fiscal_year_start_month': fiscalYearStartMonth,
            'starting_cash': startingCash,
          })
          .select()
          .single();

      return Business.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to save business: ${e.message}');
    } catch (e) {
      throw Exception(
        'An unexpected error occurred while creating your business.',
      );
    }
  }

  Future<Business> updateBusiness(Business business) async {
    try {
      final response = await _client
          .from('businesses')
          .update({
            'name': business.name.trim(),
            'industry': business.industry?.trim(),
            'country': business.country?.trim(),
            'currency': business.currency.trim().toUpperCase(),
            'fiscal_year_start_month': business.fiscalYearStartMonth,
            'starting_cash': business.startingCash,
          })
          .eq('id', business.id)
          .select()
          .single();

      return Business.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to update business profile: ${e.message}');
    }
  }
}
