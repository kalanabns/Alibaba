import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/alert.dart';

class AlertRepository {
  AlertRepository({SupabaseClient? client}) : _injectedClient = client;

  final SupabaseClient? _injectedClient;
  SupabaseClient get _client => _injectedClient ?? Supabase.instance.client;

  /// Retrieves alerts for a given business.
  Future<List<Alert>> getAlerts({
    required String businessId,
    bool? isRead,
    int limit = 50,
  }) async {
    var query = _client.from('alerts').select().eq('business_id', businessId);

    if (isRead != null) {
      query = query.eq('is_read', isRead);
    }

    final response = await query
        .order('created_at', ascending: false)
        .limit(limit);

    final list = response as List<dynamic>;
    return list
        .map((json) => Alert.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Synchronizes generated risks and opportunities into the database,
  /// preventing duplicate alerts from being created on every dashboard reload.
  Future<List<Alert>> syncAlerts({
    required String businessId,
    required List<Alert> evaluatedAlerts,
  }) async {
    if (evaluatedAlerts.isEmpty) {
      return getAlerts(businessId: businessId);
    }

    // Fetch existing active alerts to check for duplicates
    final existingAlerts = await getAlerts(businessId: businessId, limit: 100);

    final existingTitles = existingAlerts
        .where((a) => !a.isRead)
        .map((a) => '${a.alertType.name}_${a.title.toLowerCase()}')
        .toSet();

    final toInsert = <Map<String, dynamic>>[];

    for (final alert in evaluatedAlerts) {
      final key = '${alert.alertType.name}_${alert.title.toLowerCase()}';
      if (!existingTitles.contains(key)) {
        toInsert.add({
          'business_id': businessId,
          'alert_type': alert.alertType.name,
          'severity': alert.severity.name,
          'title': alert.title,
          'description': alert.description,
          'recommendation': alert.recommendation,
          'metric_name': alert.metricName,
          'metric_value': alert.metricValue,
          'threshold_value': alert.thresholdValue,
          'is_read': false,
        });
        existingTitles.add(key);
      }
    }

    if (toInsert.isNotEmpty) {
      await _client.from('alerts').insert(toInsert);
    }

    return getAlerts(businessId: businessId);
  }

  /// Marks a specific alert as read.
  Future<void> markAsRead(String alertId) async {
    await _client.from('alerts').update({'is_read': true}).eq('id', alertId);
  }

  /// Marks all alerts for a business as read.
  Future<void> markAllAsRead(String businessId) async {
    await _client
        .from('alerts')
        .update({'is_read': true})
        .eq('business_id', businessId)
        .eq('is_read', false);
  }

  /// Deletes an alert record.
  Future<void> deleteAlert(String alertId) async {
    await _client.from('alerts').delete().eq('id', alertId);
  }
}
