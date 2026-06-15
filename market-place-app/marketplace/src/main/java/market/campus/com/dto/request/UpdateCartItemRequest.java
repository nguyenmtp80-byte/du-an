package market.campus.com.dto.request;

public class UpdateCartItemRequest {
    private String cartItemId;
    private Integer quantity;

    public UpdateCartItemRequest() {}

    public UpdateCartItemRequest(String cartItemId, Integer quantity) {
        this.cartItemId = cartItemId;
        this.quantity = quantity;
    }

    // Getters and Setters
    public String getCartItemId() {
        return cartItemId;
    }

    public void setCartItemId(String cartItemId) {
        this.cartItemId = cartItemId;
    }

    public Integer getQuantity() {
        return quantity;
    }

    public void setQuantity(Integer quantity) {
        this.quantity = quantity;
    }
}
