package market.campus.com.dto.response;

import java.math.BigDecimal;
import java.util.List;

public class CartResponse {
    private String userId;
    private List<CartItemResponse> items;
    private Integer totalItems;
    private BigDecimal totalAmount;

    public CartResponse() {}

    public CartResponse(String userId, List<CartItemResponse> items, Integer totalItems, BigDecimal totalAmount) {
        this.userId = userId;
        this.items = items;
        this.totalItems = totalItems;
        this.totalAmount = totalAmount;
    }

    // Getters and Setters
    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }

    public List<CartItemResponse> getItems() { return items; }
    public void setItems(List<CartItemResponse> items) { this.items = items; }

    public Integer getTotalItems() { return totalItems; }
    public void setTotalItems(Integer totalItems) { this.totalItems = totalItems; }

    public BigDecimal getTotalAmount() { return totalAmount; }
    public void setTotalAmount(BigDecimal totalAmount) { this.totalAmount = totalAmount; }
}