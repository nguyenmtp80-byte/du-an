package market.campus.com.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class NotificationResponse {
    private String id;
    private String receiverId;
    private String title;
    private String body;
    private String type;
    private Boolean isRead;
    private LocalDateTime createdAt;
}