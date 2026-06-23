import 'package:flutter/foundation.dart';

import '../services/notification_api_service.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationProvider({NotificationApiService? notificationApiService})
      : _notificationApiService =
            notificationApiService ?? NotificationApiService();

  final NotificationApiService _notificationApiService;

  int _unreadCount = 0;
  bool _isLoading = false;

  int get unreadCount => _unreadCount;
  bool get hasUnread => _unreadCount > 0;
  bool get isLoading => _isLoading;

  Future<void> loadUnreadCount(String? userId) async {
    if (userId == null || userId.isEmpty) {
      _unreadCount = 0;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _unreadCount =
          await _notificationApiService.getUnreadCount(userId: userId);
    } catch (_) {
      _unreadCount = 0;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _unreadCount = 0;
    notifyListeners();
  }
}
