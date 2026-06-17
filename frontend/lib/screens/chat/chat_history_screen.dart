import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/screen_header.dart';
import 'chat_screen.dart';

class _ChatPreview {
  const _ChatPreview({
    required this.id,
    required this.partnerName,
    required this.partnerAvatarUrl,
    required this.lastMessage,
    required this.timeLabel,
    required this.productName,
    required this.productImageUrl,
    required this.productPrice,
    this.unreadCount = 0,
    this.isOnline = false,
  });

  final String id;
  final String partnerName;
  final String partnerAvatarUrl;
  final String lastMessage;
  final String timeLabel;
  final String productName;
  final String productImageUrl;
  final double productPrice;
  final int unreadCount;
  final bool isOnline;
}

const _mockChats = [
  _ChatPreview(
    id: 'chat-1',
    partnerName: 'Sarah Chen',
    partnerAvatarUrl:
        'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100&h=100&fit=crop',
    lastMessage: 'Được nhé! Mình sẽ có mặt lúc 3 giờ chiều...',
    timeLabel: '10:24',
    productName: 'MacBook Air M1 2020',
    productImageUrl:
        'https://images.unsplash.com/photo-1611186871348-b1ce696e52c9?w=600&h=600&fit=crop',
    productPrice: 650,
    unreadCount: 2,
    isOnline: true,
  ),
  _ChatPreview(
    id: 'chat-2',
    partnerName: 'Minh Tuấn',
    partnerAvatarUrl:
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&h=100&fit=crop',
    lastMessage: 'Sách Calculus còn không bạn?',
    timeLabel: 'Hôm qua',
    productName: 'Giáo trình Calculus',
    productImageUrl:
        'https://images.unsplash.com/photo-1544947950-fa07a98d237f?w=600&h=600&fit=crop',
    productPrice: 120,
    unreadCount: 0,
    isOnline: false,
  ),
  _ChatPreview(
    id: 'chat-3',
    partnerName: 'Lan Anh',
    partnerAvatarUrl:
        'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=100&h=100&fit=crop',
    lastMessage: 'Ok, hẹn gặp ở thư viện nhé!',
    timeLabel: 'T2',
    productName: 'Bàn học gấp gọn',
    productImageUrl:
        'https://images.unsplash.com/photo-1518455027359-f3f8164ba6bd?w=600&h=600&fit=crop',
    productPrice: 45,
    unreadCount: 0,
    isOnline: true,
  ),
];

class ChatHistoryScreen extends StatelessWidget {
  const ChatHistoryScreen({super.key});

  void _openChat(BuildContext context, _ChatPreview chat) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(
          partnerName: chat.partnerName,
          partnerAvatarUrl: chat.partnerAvatarUrl,
          isOnline: chat.isOnline,
          productName: chat.productName,
          productImageUrl: chat.productImageUrl,
          productPrice: chat.productPrice,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: Column(
        children: [
          const ScreenHeader(title: 'Tin nhắn', showBackButton: false),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: _mockChats.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final chat = _mockChats[index];

                return _ChatHistoryTile(
                  chat: chat,
                  onTap: () => _openChat(context, chat),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatHistoryTile extends StatelessWidget {
  const _ChatHistoryTile({
    required this.chat,
    required this.onTap,
  });

  final _ChatPreview chat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasUnread = chat.unreadCount > 0;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.gray200,
                    backgroundImage: NetworkImage(chat.partnerAvatarUrl),
                  ),
                  if (chat.isOnline)
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chat.partnerName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                              color: AppColors.gray900,
                            ),
                          ),
                        ),
                        Text(
                          chat.timeLabel,
                          style: TextStyle(
                            fontSize: 11,
                            color: hasUnread ? AppColors.primary : AppColors.gray400,
                            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      chat.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: hasUnread ? AppColors.gray900 : AppColors.gray500,
                        fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            chat.productImageUrl,
                            width: 28,
                            height: 28,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              width: 28,
                              height: 28,
                              color: AppColors.gray200,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            chat.productName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.gray400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (hasUnread) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                  alignment: Alignment.center,
                  child: Text(
                    chat.unreadCount > 9 ? '9+' : '${chat.unreadCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
