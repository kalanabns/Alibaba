enum AIRole { user, assistant, system }

class AIConversation {
  const AIConversation({
    required this.id,
    required this.businessId,
    required this.userId,
    required this.sessionId,
    required this.role,
    required this.message,
    required this.createdAt,
  });

  factory AIConversation.fromJson(Map<String, dynamic> json) {
    return AIConversation(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      userId: json['user_id'] as String,
      sessionId: json['session_id'] as String,
      role: AIRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => AIRole.user,
      ),
      message: json['message'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final String id;
  final String businessId;
  final String userId;
  final String sessionId;
  final AIRole role;
  final String message;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'user_id': userId,
      'session_id': sessionId,
      'role': role.name,
      'message': message,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
