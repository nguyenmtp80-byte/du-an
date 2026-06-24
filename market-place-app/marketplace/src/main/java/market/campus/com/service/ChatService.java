package market.campus.com.service;

import market.campus.com.dto.request.CreateChatRoomRequest;
import market.campus.com.dto.request.SendMessageRequest;
import market.campus.com.dto.response.ChatMessageResponse;
import market.campus.com.dto.response.ChatRoomResponse;
import market.campus.com.exception.InvalidDataException;
import market.campus.com.exception.ResourceNotFoundException;
import market.campus.com.model.*;
import market.campus.com.repository.ChatMessageRepository;
import market.campus.com.repository.ChatRoomRepository;
import market.campus.com.repository.ProductRepository;
import market.campus.com.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class ChatService {

    @Autowired
    private ChatRoomRepository chatRoomRepository;

    @Autowired
    private ChatMessageRepository chatMessageRepository;

    @Autowired
    private ProductRepository productRepository;

    @Autowired
    private UserRepository userRepository;

    /**
     * Create or get existing chat room for a buyer and a product.
     * The buyer chats with the product's seller.
     */
    @Transactional
    public ChatRoomResponse createOrGetChatRoom(String buyerId, CreateChatRoomRequest request) {
        User buyer = userRepository.findById(buyerId)
                .orElseThrow(() -> new ResourceNotFoundException("Người dùng không tồn tại"));

        Product product = productRepository.findById(request.getProductId())
                .orElseThrow(() -> new ResourceNotFoundException("Sản phẩm không tồn tại"));

        // Can't chat with yourself
        if (product.getSeller().getId().equals(buyerId)) {
            throw new InvalidDataException("Bạn không thể tự nhắn tin với sản phẩm của mình");
        }

        // Check if room already exists for this buyer-product pair
        ChatRoom room = chatRoomRepository.findByProductAndBuyer(product, buyer)
                .orElse(null);

        if (room == null) {
            room = new ChatRoom(
                    UUID.randomUUID().toString(),
                    product,
                    buyer,
                    product.getSeller()
            );
            room.setUpdatedAt(LocalDateTime.now());
            room = chatRoomRepository.save(room);
        }

        return toChatRoomResponse(room, buyerId);
    }

    /**
     * Get all chat rooms for a user (both as buyer and seller)
     */
    public List<ChatRoomResponse> getUserChatRooms(String userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("Người dùng không tồn tại"));

        List<ChatRoom> rooms = chatRoomRepository.findByBuyerOrSellerOrderByUpdatedAtDesc(user, user);
        return rooms.stream()
                .map(room -> toChatRoomResponse(room, userId))
                .collect(Collectors.toList());
    }

    /**
     * Send a message in a chat room
     */
    @Transactional
    public ChatMessageResponse sendMessage(String roomId, String senderId, SendMessageRequest request) {
        if (request.getMessage() == null || request.getMessage().trim().isEmpty()) {
            throw new InvalidDataException("Tin nhắn không được để trống");
        }

        ChatRoom room = chatRoomRepository.findById(roomId)
                .orElseThrow(() -> new ResourceNotFoundException("Phòng chat không tồn tại"));

        User sender = userRepository.findById(senderId)
                .orElseThrow(() -> new ResourceNotFoundException("Người dùng không tồn tại"));

        // Validate sender is part of this room
        boolean isParticipant = room.getBuyer().getId().equals(senderId)
                || room.getSeller().getId().equals(senderId);
        if (!isParticipant) {
            throw new InvalidDataException("Bạn không phải thành viên của phòng chat này");
        }

        ChatMessage chatMessage = new ChatMessage(
                UUID.randomUUID().toString(),
                room,
                sender,
                request.getMessage()
        );
        chatMessage = chatMessageRepository.save(chatMessage);

        // Update room's last message and updated_at
        room.setLastMessage(request.getMessage());
        room.setUpdatedAt(LocalDateTime.now());
        chatRoomRepository.save(room);

        return toChatMessageResponse(chatMessage);
    }

    /**
     * Get messages for a chat room
     */
    public List<ChatMessageResponse> getMessages(String roomId, String userId) {
        ChatRoom room = chatRoomRepository.findById(roomId)
                .orElseThrow(() -> new ResourceNotFoundException("Phòng chat không tồn tại"));

        // Validate user is part of this room
        boolean isParticipant = room.getBuyer().getId().equals(userId)
                || room.getSeller().getId().equals(userId);
        if (!isParticipant) {
            throw new InvalidDataException("Bạn không có quyền xem tin nhắn trong phòng này");
        }

        return chatMessageRepository.findByRoomOrderByCreatedAtAsc(room)
                .stream()
                .map(this::toChatMessageResponse)
                .collect(Collectors.toList());
    }

    /**
     * Mark all messages in a room as read for a specific user
     */
    @Transactional
    public void markMessagesAsRead(String roomId, String userId) {
        ChatRoom room = chatRoomRepository.findById(roomId)
                .orElseThrow(() -> new ResourceNotFoundException("Phòng chat không tồn tại"));

        boolean isParticipant = room.getBuyer().getId().equals(userId)
                || room.getSeller().getId().equals(userId);
        if (!isParticipant) {
            throw new InvalidDataException("Bạn không có quyền thao tác trong phòng này");
        }

        List<ChatMessage> unreadMessages = chatMessageRepository.findByRoomOrderByCreatedAtAsc(room)
                .stream()
                .filter(msg -> !msg.getIsRead() && !msg.getSender().getId().equals(userId))
                .collect(Collectors.toList());

        unreadMessages.forEach(msg -> msg.setIsRead(true));
        chatMessageRepository.saveAll(unreadMessages);
    }

    private ChatRoomResponse toChatRoomResponse(ChatRoom room, String currentUserId) {
        long unreadCount = chatMessageRepository.countUnreadByRoomAndNotSender(room, false, currentUserId);

        return new ChatRoomResponse(
                room.getId(),
                room.getProduct().getId(),
                room.getProduct().getTitle(),
                room.getProduct().getFirstImageUrl(),
                room.getBuyer().getId(),
                room.getBuyer().getFullName() != null ? room.getBuyer().getFullName() : room.getBuyer().getEmail(),
                room.getSeller().getId(),
                room.getSeller().getFullName() != null ? room.getSeller().getFullName() : room.getSeller().getEmail(),
                room.getLastMessage(),
                unreadCount,
                room.getUpdatedAt()
        );
    }

    private ChatMessageResponse toChatMessageResponse(ChatMessage message) {
        return new ChatMessageResponse(
                message.getId(),
                message.getRoom().getId(),
                message.getSender().getId(),
                message.getSender().getFullName() != null ? message.getSender().getFullName() : message.getSender().getEmail(),
                message.getMessage(),
                message.getIsRead(),
                message.getCreatedAt()
        );
    }
}