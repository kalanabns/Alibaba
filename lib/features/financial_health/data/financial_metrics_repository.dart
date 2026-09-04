import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/financial_metric.dart';

class FinancialMetricsRepository {
  FinancialMetricsRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<FinancialMetric?> getLatestMetric(String businessId) async {
    try {
      final response = await _client
          .from('financial_metrics')
          .select()
          .eq('business_id', businessId)
          .order('period_end', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return FinancialMetric.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception(
        'Database error fetching financial metrics: ${e.message}',
      );
    } catch (e) {
      throw Exception('Failed to load financial metrics.');
    }
  }

  Future<FinancialMetric?> getMetricForPeriod({
    required String businessId,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) async {
    try {
      final startStr = periodStart.toIso8601String().split('T').first;
      final endStr = periodEnd.toIso8601String().split('T').first;

      final response = await _client
          .from('financial_metrics')
          .select()
          .eq('business_id', businessId)
          .eq('period_start', startStr)
          .eq('period_end', endStr)
          .maybeSingle();

      if (response == null) return null;
      return FinancialMetric.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to load metric for period.');
    }
  }

  Future<FinancialMetric> upsertFinancialMetric(FinancialMetric metric) async {
    try {
      final payload = {
        'business_id': metric.businessId,
        'period_start': metric.periodStart.toIso8601String().split('T').first,
        'period_end': metric.periodEnd.toIso8601String().split('T').first,
        'revenue': metric.revenue,
        'expenses': metric.expenses,
        'profit': metric.profit,
        'profit_margin': metric.profitMargin,
        'cash_inflow': metric.cashInflow,
        'cash_outflow': metric.cashOutflow,
        'net_cash_flow': metric.netCashFlow,
        'debt': metric.debt,
        'receivables': metric.receivables,
        'payables': metric.payables,
        'revenue_growth': metric.revenueGrowth,
        'expense_growth': metric.expenseGrowth,
        'health_score': metric.healthScore,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      final response = await _client
          .from('financial_metrics')
          .upsert(payload, onConflict: 'business_id,period_start,period_end')
          .select()
          .single();

      return FinancialMetric.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to save financial metrics: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error persisting financial metrics: $e');
    }
  }
}
