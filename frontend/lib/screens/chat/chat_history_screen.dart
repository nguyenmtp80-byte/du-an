import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/chat.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';
import '../../services/chat_api_service.dart';
import '../../core/themes/app_theme.dart';
import '../../utils/formatters.dart';
import 'chat_screen.dart';
import '../../widgets/screen_header.dart';

class ChatHistoryScreen extends StatefulWidget {
  const ChatHistoryScreen({super.key});

  @override
  State<ChatHistoryScreen> createState() => ChatHistoryScreenState();
}

class ChatHistoryScreenState extends State<ChatHistoryScreen> {
  final _chatApiService = ChatApiService();

  List<ChatRoom> _rooms = [];
  bool _isLoading = false;
  String? _error;

  int get totalUnreadCount =>
      _rooms.fold<int>(0, (sum, room) => sum + room.unreadCount);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => loadRooms());
  }

  Future<void> loadRooms() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null || userId.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final rooms = await _chatApiService.getUserRooms(userId: userId);
      if (!mounted) {
        return;
      }

      setState(() {
        _rooms = rooms;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = 'Không thể tải tin nhắn.';
        _isLoading = false;
      });
    }
  }

  void _openChat(ChatRoom room) {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null || userId.isEmpty) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(
          roomId: room.id,
          currentUserId: userId,
          partnerName: room.partnerNameFor(userId),
          productName: room.productTitle,
          productImageUrl: room.productImage,
        ),
      ),
    ).then((_) => loadRooms());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: Column(
        children: [
          const ScreenHeader(title: 'Tin nhắn', showBackButton: false),
          Expanded(
            child: RefreshIndicator(
              onRefresh: loadRooms,
              color: AppColors.primary,
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _rooms.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.gray700),
            ),
          ),
        ],
      );
    }

    if (_rooms.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 80),
          Icon(Icons.chat_bubble_outline, size: 56, color: AppColors.gray400),
          SizedBox(height: 16),
          Text(
            'Chưa có cuộc trò chuyện',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.gray900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Nhắn tin với người bán từ trang chi tiết sản phẩm.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.gray500, height: 1.5),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _rooms.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final room = _rooms[index];
        final userId = context.read<AuthProvider>().user?.id ?? '';
        final partnerName = room.partnerNameFor(userId);
        final imageUrl = room.productImage?.trim() ?? '';

        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _openChat(room),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 52,
                          height: 52,
                          child: imageUrl.isEmpty
                              ? Container(
                                  color: AppColors.gray50,
                                  child: const Icon(
                                    Icons.image_outlined,
                                    color: AppColors.gray400,
                                  ),
                                )
                              : Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Container(
                                    color: AppColors.gray50,
                                    child: const Icon(
                                      Icons.broken_image_outlined,
                                      color: AppColors.gray400,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      if (room.unreadCount > 0)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              room.unreadCount > 9 ? '9+' : '${room.unreadCount}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                height: 1,
                              ),
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
                                partnerName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: room.unreadCount > 0
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  color: AppColors.gray900,
                                ),
                              ),
                            ),
                            if (room.updatedAt != null)
                              Text(
                                formatRelativeDate(room.updatedAt),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.gray400,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          room.productTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          room.lastMessage?.trim().isNotEmpty == true
                              ? room.lastMessage!
                              : 'Chưa có tin nhắn',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: room.unreadCount > 0
                                ? AppColors.gray900
                                : AppColors.gray500,
                            fontWeight:
                                room.unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.gray400),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
