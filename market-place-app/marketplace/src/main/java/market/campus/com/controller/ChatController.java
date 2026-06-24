package market.campus.com.controller;

import market.campus.com.dto.request.CreateChatRoomRequest;
import market.campus.com.dto.request.SendMessageRequest;
import market.campus.com.dto.response.ChatMessageResponse;
import market.campus.com.dto.response.ChatRoomResponse;
import market.campus.com.service.ChatService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/chat")
@CrossOrigin(origins = "*", maxAge = 3600)
public class ChatController {

    @Autowired
    private ChatService chatService;

    // Inner class for error responses
    public static class ErrorResponse {
        private String message;
        public ErrorResponse(String message) { this.message = message; }
        public String getMessage() { return message; }
        public void setMessage(String message) { this.message = message; }
    }

    /**
     * POST /api/chat/rooms - Tạo hoặc lấy phòng chat cho sản phẩm
     */
    @PostMapping("/rooms")
    public ResponseEntity<?> createOrGetRoom(@RequestHeader("X-User-Id") String userId,
                                              @RequestBody CreateChatRoomRequest request) {
        try {
            ChatRoomResponse room = chatService.createOrGetChatRoom(userId, request);
            return ResponseEntity.ok(room);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(new ErrorResponse(e.getMessage()));
        }
    }

    /**
     * GET /api/chat/rooms - Lấy danh sách phòng chat của user
     */
    @GetMapping("/rooms")
    public ResponseEntity<?> getUserRooms(@RequestHeader("X-User-Id") String userId) {
        try {
            List<ChatRoomResponse> rooms = chatService.getUserChatRooms(userId);
            return ResponseEntity.ok(rooms);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(new ErrorResponse(e.getMessage()));
        }
    }

    /**
     * GET /api/chat/rooms/{roomId}/messages - Lấy tin nhắn trong phòng
     */
    @GetMapping("/rooms/{roomId}/messages")
    public ResponseEntity<?> getMessages(@RequestHeader("X-User-Id") String userId,
                                          @PathVariable String roomId) {
        try {
            List<ChatMessageResponse> messages = chatService.getMessages(roomId, userId);
            return ResponseEntity.ok(messages);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(new ErrorResponse(e.getMessage()));
        }
    }

    /**
     * POST /api/chat/rooms/{roomId}/messages - Gửi tin nhắn
     */
    @PostMapping("/rooms/{roomId}/messages")
    public ResponseEntity<?> sendMessage(@RequestHeader("X-User-Id") String userId,
                                          @PathVariable String roomId,
                                          @RequestBody SendMessageRequest request) {
        try {
            ChatMessageResponse message = chatService.sendMessage(roomId, userId, request);
            return ResponseEntity.ok(message);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(new ErrorResponse(e.getMessage()));
        }
    }

    /**
     * PUT /api/chat/rooms/{roomId}/read - Đánh dấu đã đọc tin nhắn
     */
    @PutMapping("/rooms/{roomId}/read")
    public ResponseEntity<?> markAsRead(@RequestHeader("X-User-Id") String userId,
                                         @PathVariable String roomId) {
        try {
            chatService.markMessagesAsRead(roomId, userId);
            return ResponseEntity.ok().build();
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(new ErrorResponse(e.getMessage()));
        }
    }
}