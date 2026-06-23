package market.campus.com.service;

import lombok.RequiredArgsConstructor;
import market.campus.com.dto.response.NotificationResponse;
import market.campus.com.exception.ResourceNotFoundException;
import market.campus.com.model.Notification;
import market.campus.com.model.User;
import market.campus.com.repository.NotificationRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class NotificationServiceImpl implements NotificationService {

    private final NotificationRepository notificationRepository;

    @Override
    @Transactional
    public NotificationResponse createNotification(User receiver, String title, String body, String type, String orderId) {
        Notification notification = Notification.builder()
                .id(UUID.randomUUID().toString())
                .receiver(receiver)
                .title(title)
                .body(body)
                .type(type)
                .orderId(orderId)
                .isRead(false)
                .build();
        notification = notificationRepository.save(notification);
        return mapToDto(notification);
    }

    @Override
    @Transactional(readOnly = true)
    public List<NotificationResponse> getUserNotifications(User user) {
        return notificationRepository.findByReceiverOrderByCreatedAtDesc(user)
                .stream()
                .map(this::mapToDto)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public List<NotificationResponse> getUnreadNotifications(User user) {
        return notificationRepository.findByReceiverAndIsReadOrderByCreatedAtDesc(user, false)
                .stream()
                .map(this::mapToDto)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public long countUnreadNotifications(User user) {
        return notificationRepository.countByReceiverAndIsRead(user, false);
    }

    @Override
    @Transactional
    public NotificationResponse markAsRead(String notificationId, User user) {
        Notification notification = notificationRepository.findById(notificationId)
                .orElseThrow(() -> new ResourceNotFoundException("Thông báo không tồn tại"));

        if (!notification.getReceiver().getId().equals(user.getId())) {
            throw new SecurityException("Bạn không có quyền thao tác thông báo này");
        }

        notification.setIsRead(true);
        notification = notificationRepository.save(notification);
        return mapToDto(notification);
    }

    @Override
    @Transactional
    public void markAllAsRead(User user) {
        List<Notification> unreadNotifications =
                notificationRepository.findByReceiverAndIsReadOrderByCreatedAtDesc(user, false);
        unreadNotifications.forEach(notification -> notification.setIsRead(true));
        notificationRepository.saveAll(unreadNotifications);
    }

    private NotificationResponse mapToDto(Notification notification) {
        return NotificationResponse.builder()
                .id(notification.getId())
                .receiverId(notification.getReceiver().getId())
                .title(notification.getTitle())
                .body(notification.getBody())
                .type(notification.getType())
                .orderId(notification.getOrderId())
                .isRead(notification.getIsRead())
                .createdAt(notification.getCreatedAt())
                .build();
    }
}
