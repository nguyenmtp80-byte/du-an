import '../core/constants/api_config.dart';
import '../models/notification.dart';
import 'api_client.dart';

class NotificationApiService {
  NotificationApiService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<AppNotification>> getNotifications({required String userId}) async {
    final response = await _apiClient.getList(
      ApiConfig.notificationsEndpoint,
      extraHeaders: {'X-User-Id': userId},
    );

    return response.map(AppNotification.fromJson).toList();
  }

  Future<int> getUnreadCount({required String userId}) async {
    final response = await _apiClient.get(
      ApiConfig.notificationsUnreadCountEndpoint,
      extraHeaders: {'X-User-Id': userId},
    );

    final count = response['count'];
    if (count is int) {
      return count;
    }

    return int.tryParse(count?.toString() ?? '') ?? 0;
  }

  Future<void> markAsRead({
    required String userId,
    required String notificationId,
  }) async {
    await _apiClient.put(
      ApiConfig.notificationReadEndpoint(notificationId),
      extraHeaders: {'X-User-Id': userId},
    );
  }

  Future<void> markAllAsRead({required String userId}) async {
    await _apiClient.put(
      ApiConfig.notificationsReadAllEndpoint,
      extraHeaders: {'X-User-Id': userId},
    );
  }
}
