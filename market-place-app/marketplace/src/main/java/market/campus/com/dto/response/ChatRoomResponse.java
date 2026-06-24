package market.campus.com.dto.response;

import java.time.LocalDateTime;

public class ChatRoomResponse {
    private String id;
    private String productId;
    private String productTitle;
    private String productImage;
    private String buyerId;
    private String buyerName;
    private String sellerId;
    private String sellerName;
    private String lastMessage;
    private long unreadCount;
    private LocalDateTime updatedAt;

    public ChatRoomResponse() {}

    public ChatRoomResponse(String id, String productId, String productTitle, String productImage,
                            String buyerId, String buyerName, String sellerId, String sellerName,
                            String lastMessage, long unreadCount, LocalDateTime updatedAt) {
        this.id = id;
        this.productId = productId;
        this.productTitle = productTitle;
        this.productImage = productImage;
        this.buyerId = buyerId;
        this.buyerName = buyerName;
        this.sellerId = sellerId;
        this.sellerName = sellerName;
        this.lastMessage = lastMessage;
        this.unreadCount = unreadCount;
        this.updatedAt = updatedAt;
    }

    // Getters and Setters
    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getProductId() { return productId; }
    public void setProductId(String productId) { this.productId = productId; }

    public String getProductTitle() { return productTitle; }
    public void setProductTitle(String productTitle) { this.productTitle = productTitle; }

    public String getProductImage() { return productImage; }
    public void setProductImage(String productImage) { this.productImage = productImage; }

    public String getBuyerId() { return buyerId; }
    public void setBuyerId(String buyerId) { this.buyerId = buyerId; }

    public String getBuyerName() { return buyerName; }
    public void setBuyerName(String buyerName) { this.buyerName = buyerName; }

    public String getSellerId() { return sellerId; }
    public void setSellerId(String sellerId) { this.sellerId = sellerId; }

    public String getSellerName() { return sellerName; }
    public void setSellerName(String sellerName) { this.sellerName = sellerName; }

    public String getLastMessage() { return lastMessage; }
    public void setLastMessage(String lastMessage) { this.lastMessage = lastMessage; }

    public long getUnreadCount() { return unreadCount; }
    public void setUnreadCount(long unreadCount) { this.unreadCount = unreadCount; }

    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }
}