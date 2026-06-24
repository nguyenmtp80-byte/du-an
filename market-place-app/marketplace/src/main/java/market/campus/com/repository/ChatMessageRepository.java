package market.campus.com.repository;

import market.campus.com.model.ChatMessage;
import market.campus.com.model.ChatRoom;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ChatMessageRepository extends JpaRepository<ChatMessage, String> {
    List<ChatMessage> findByRoomOrderByCreatedAtAsc(ChatRoom room);

    @Query("SELECT COUNT(cm) FROM ChatMessage cm WHERE cm.room = :room AND cm.isRead = :isRead AND cm.sender.id <> :senderId")
    long countUnreadByRoomAndNotSender(@Param("room") ChatRoom room,
                                       @Param("isRead") Boolean isRead,
                                       @Param("senderId") String senderId);
}
