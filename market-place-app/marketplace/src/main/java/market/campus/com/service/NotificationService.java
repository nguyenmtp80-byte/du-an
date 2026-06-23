package market.campus.com.service;

import market.campus.com.dto.response.NotificationResponse;
import market.campus.com.model.User;

import java.util.List;

public interface NotificationService {
    NotificationResponse createNotification(User receiver, String title, String body, String type);
    List<NotificationResponse> getUserNotifications(User user);
    List<NotificationResponse> getUnreadNotifications(User user);
    long countUnreadNotifications(User user);
    NotificationResponse markAsRead(String notificationId, User user);
    void markAllAsRead(User user);
}
