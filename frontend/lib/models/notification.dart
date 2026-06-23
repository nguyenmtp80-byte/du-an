class AppNotification {
  const AppNotification({
    required this.id,
    required this.receiverId,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    this.orderId,
    this.createdAt,
  });

  final String id;
  final String receiverId;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final String? orderId;
  final DateTime? createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id']?.toString() ?? '',
      receiverId: json['receiverId']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      type: json['type'] as String? ?? '',
      isRead: json['isRead'] as bool? ?? false,
      orderId: json['orderId']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}
