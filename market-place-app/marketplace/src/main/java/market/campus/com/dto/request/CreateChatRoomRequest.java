package market.campus.com.dto.request;

public class CreateChatRoomRequest {
    private String productId;

    public CreateChatRoomRequest() {}

    public CreateChatRoomRequest(String productId) {
        this.productId = productId;
    }

    public String getProductId() { return productId; }
    public void setProductId(String productId) { this.productId = productId; }
}