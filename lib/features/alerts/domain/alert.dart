import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

enum AlertType { risk, opportunity, information }

enum AlertSeverity { critical, high, medium, low }

class Alert {
  const Alert({
    required this.id,
    required this.businessId,
    required this.alertType,
    required this.severity,
    required this.title,
    required this.description,
    this.recommendation,
    this.metricName,
    this.metricValue,
    this.thresholdValue,
    this.isRead = false,
    required this.createdAt,
    this.expiresAt,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      alertType: AlertType.values.firstWhere(
        (e) => e.name == json['alert_type'],
        orElse: () => AlertType.information,
      ),
      severity: AlertSeverity.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => AlertSeverity.low,
      ),
      title: json['title'] as String,
      description: json['description'] as String,
      recommendation: json['recommendation'] as String?,
      metricName: json['metric_name'] as String?,
      metricValue: (json['metric_value'] as num?)?.toDouble(),
      thresholdValue: (json['threshold_value'] as num?)?.toDouble(),
      isRead: (json['is_read'] as bool?) ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
    );
  }

  final String id;
  final String businessId;
  final AlertType alertType;
  final AlertSeverity severity;
  final String title;
  final String description;
  final String? recommendation;
  final String? metricName;
  final double? metricValue;
  final double? thresholdValue;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? expiresAt;

  bool get isRisk => alertType == AlertType.risk;
  bool get isOpportunity => alertType == AlertType.opportunity;

  Color get severityColor {
    if (isOpportunity) return AppTheme.primaryLight;
    switch (severity) {
      case AlertSeverity.critical:
        return AppTheme.errorColor;
      case AlertSeverity.high:
        return const Color(0xFFEA580C); // Dark orange
      case AlertSeverity.medium:
        return AppTheme.warningColor;
      case AlertSeverity.low:
        return AppTheme.infoColor;
    }
  }

  String get severityLabel {
    switch (severity) {
      case AlertSeverity.critical:
        return 'Critical';
      case AlertSeverity.high:
        return 'High Risk';
      case AlertSeverity.medium:
        return 'Medium Risk';
      case AlertSeverity.low:
        return isOpportunity ? 'Opportunity' : 'Notice';
    }
  }

  Alert copyWith({
    String? id,
    String? businessId,
    AlertType? alertType,
    AlertSeverity? severity,
    String? title,
    String? description,
    String? recommendation,
    String? metricName,
    double? metricValue,
    double? thresholdValue,
    bool? isRead,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) {
    return Alert(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      alertType: alertType ?? this.alertType,
      severity: severity ?? this.severity,
      title: title ?? this.title,
      description: description ?? this.description,
      recommendation: recommendation ?? this.recommendation,
      metricName: metricName ?? this.metricName,
      metricValue: metricValue ?? this.metricValue,
      thresholdValue: thresholdValue ?? this.thresholdValue,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'alert_type': alertType.name,
      'severity': severity.name,
      'title': title,
      'description': description,
      'recommendation': recommendation,
      'metric_name': metricName,
      'metric_value': metricValue,
      'threshold_value': thresholdValue,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
    };
  }
}
