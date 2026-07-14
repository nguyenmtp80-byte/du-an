import '../core/constants/api_config.dart';
import '../models/chat.dart';
import 'api_client.dart';

class ChatApiService {
  ChatApiService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<ChatRoom> createOrGetRoom({
    required String userId,
    required String productId,
  }) async {
    final response = await _apiClient.post(
      ApiConfig.chatRoomsEndpoint,
      extraHeaders: {'X-User-Id': userId},
      body: {'productId': productId},
    );

    return ChatRoom.fromJson(response);
  }

  Future<List<ChatRoom>> getUserRooms({required String userId}) async {
    final response = await _apiClient.getList(
      ApiConfig.chatRoomsEndpoint,
      extraHeaders: {'X-User-Id': userId},
    );

    return response.map(ChatRoom.fromJson).toList();
  }

  Future<List<ChatMessage>> getMessages({
    required String userId,
    required String roomId,
  }) async {
    final response = await _apiClient.getList(
      ApiConfig.chatRoomMessagesEndpoint(roomId),
      extraHeaders: {'X-User-Id': userId},
    );

    return response.map(ChatMessage.fromJson).toList();
  }

  Future<ChatMessage> sendMessage({
    required String userId,
    required String roomId,
    required String message,
  }) async {
    final response = await _apiClient.post(
      ApiConfig.chatRoomMessagesEndpoint(roomId),
      extraHeaders: {'X-User-Id': userId},
      body: {'message': message},
    );

    return ChatMessage.fromJson(response);
  }

  Future<void> markAsRead({
    required String userId,
    required String roomId,
  }) async {
    await _apiClient.put(
      ApiConfig.chatRoomReadEndpoint(roomId),
      extraHeaders: {'X-User-Id': userId},
    );
  }
}
