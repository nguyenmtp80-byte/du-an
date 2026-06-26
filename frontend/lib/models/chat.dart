class ChatRoom {
  const ChatRoom({
    required this.id,
    required this.productId,
    required this.productTitle,
    this.productImage,
    required this.buyerId,
    required this.buyerName,
    required this.sellerId,
    required this.sellerName,
    this.lastMessage,
    this.unreadCount = 0,
    this.updatedAt,
  });

  final String id;
  final String productId;
  final String productTitle;
  final String? productImage;
  final String buyerId;
  final String buyerName;
  final String sellerId;
  final String sellerName;
  final String? lastMessage;
  final int unreadCount;
  final DateTime? updatedAt;

  String partnerNameFor(String userId) {
    if (userId == sellerId) {
      return buyerName;
    }
    return sellerName;
  }

  String partnerIdFor(String userId) {
    if (userId == sellerId) {
      return buyerId;
    }
    return sellerId;
  }

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      productTitle: json['productTitle'] as String? ?? '',
      productImage: json['productImage'] as String?,
      buyerId: json['buyerId']?.toString() ?? '',
      buyerName: json['buyerName'] as String? ?? '',
      sellerId: json['sellerId']?.toString() ?? '',
      sellerName: json['sellerName'] as String? ?? '',
      lastMessage: json['lastMessage'] as String?,
      unreadCount: json['unreadCount'] as int? ?? 0,
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.senderName,
    required this.message,
    this.isRead = false,
    this.createdAt,
  });

  final String id;
  final String roomId;
  final String senderId;
  final String senderName;
  final String message;
  final bool isRead;
  final DateTime? createdAt;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      roomId: json['roomId']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      senderName: json['senderName'] as String? ?? '',
      message: json['message'] as String? ?? '',
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}
