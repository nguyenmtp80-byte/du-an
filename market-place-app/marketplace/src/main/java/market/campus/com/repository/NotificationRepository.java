package market.campus.com.repository;

import market.campus.com.model.Notification;
import market.campus.com.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface NotificationRepository extends JpaRepository<Notification, String> {
    List<Notification> findByReceiverOrderByCreatedAtDesc(User receiver);
    List<Notification> findByReceiverAndIsReadOrderByCreatedAtDesc(User receiver, Boolean isRead);
    long countByReceiverAndIsRead(User receiver, Boolean isRead);
}