package market.campus.com.controller;

import lombok.RequiredArgsConstructor;
import market.campus.com.dto.response.NotificationResponse;
import market.campus.com.model.User;
import market.campus.com.service.NotificationService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/notifications")
@CrossOrigin(origins = "*", maxAge = 3600)
@RequiredArgsConstructor
public class NotificationController {

    private final NotificationService notificationService;

    // TODO: Lấy user từ authentication context
    // Tạm thời sử dụng userId từ header

    @GetMapping
    public ResponseEntity<?> getUserNotifications(@RequestHeader("X-User-Id") String userId) {
        try {
            User user = new User();
            user.setId(userId);
            List<NotificationResponse> notifications = notificationService.getUserNotifications(user);
            return ResponseEntity.ok(notifications);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }

    @GetMapping("/unread")
    public ResponseEntity<?> getUnreadNotifications(@RequestHeader("X-User-Id") String userId) {
        try {
            User user = new User();
            user.setId(userId);
            List<NotificationResponse> notifications = notificationService.getUnreadNotifications(user);
            return ResponseEntity.ok(notifications);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }

    @GetMapping("/unread/count")
    public ResponseEntity<?> countUnreadNotifications(@RequestHeader("X-User-Id") String userId) {
        try {
            User user = new User();
            user.setId(userId);
            long count = notificationService.countUnreadNotifications(user);
            return ResponseEntity.ok(Map.of("count", count));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }

    @PutMapping("/{notificationId}/read")
    public ResponseEntity<?> markAsRead(@RequestHeader("X-User-Id") String userId,
                                        @PathVariable String notificationId) {
        try {
            User user = new User();
            user.setId(userId);
            NotificationResponse notification = notificationService.markAsRead(notificationId, user);
            return ResponseEntity.ok(notification);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }

    @PutMapping("/read-all")
    public ResponseEntity<?> markAllAsRead(@RequestHeader("X-User-Id") String userId) {
        try {
            User user = new User();
            user.setId(userId);
            notificationService.markAllAsRead(user);
            return ResponseEntity.ok(Map.of("message", "Đã đánh dấu tất cả thông báo là đã đọc"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }
}