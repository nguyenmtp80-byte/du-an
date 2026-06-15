package market.campus.com.dto.request;

public class AddToCartRequest {
    private String productId;
    private Integer quantity;

    public AddToCartRequest() {}

    public AddToCartRequest(String productId, Integer quantity) {
        this.productId = productId;
        this.quantity = quantity;
    }

    // Getters and Setters
    public String getProductId() {
        return productId;
    }

    public void setProductId(String productId) {
        this.productId = productId;
    }

    public Integer getQuantity() {
        return quantity;
    }

    public void setQuantity(Integer quantity) {
        this.quantity = quantity;
    }
}
