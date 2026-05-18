class MemberAlert {
  final int id;
  final int memberId;
  final String title;
  final String message;
  final String alertType;
  final int priority;
  final bool isRead;
  final DateTime sentAt;
  final DateTime? viewedAt;

  const MemberAlert({
    required this.id,
    required this.memberId,
    required this.title,
    required this.message,
    required this.alertType,
    required this.priority,
    required this.isRead,
    required this.sentAt,
    this.viewedAt,
  });

  factory MemberAlert.fromJson(Map<String, dynamic> json) {
    return MemberAlert(
      id: json['id'] as int,
      memberId: json['memberId'] as int,
      title: json['title'] as String,
      message: json['message'] as String,
      alertType: json['alertType'] as String? ?? 'INFO',
      priority: json['priority'] as int? ?? 0,
      isRead: json['isRead'] as bool? ?? false,
      sentAt: DateTime.parse(json['sentAt'] as String),
      viewedAt:
          json['viewedAt'] != null
              ? DateTime.parse(json['viewedAt'] as String)
              : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'memberId': memberId,
    'title': title,
    'message': message,
    'alertType': alertType,
    'priority': priority,
    'isRead': isRead,
    'sentAt': sentAt.toIso8601String(),
    'viewedAt': viewedAt?.toIso8601String(),
  };
}

class SendAlertRequest {
  final String title;
  final String message;
  final String? alertType;
  final int? priority;
  final bool sendToAllActiveMembers;
  final int? memberId;
  final List<int>? memberIds;

  SendAlertRequest({
    required this.title,
    required this.message,
    this.alertType,
    this.priority,
    this.sendToAllActiveMembers = true,
    this.memberId,
    this.memberIds,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'message': message,
    'alertType': alertType,
    'priority': priority,
    'sendToAllActiveMembers': sendToAllActiveMembers,
    'memberId': memberId,
    'memberIds': memberIds,
  };
}
