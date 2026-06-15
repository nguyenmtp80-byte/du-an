package market.campus.com.dto.response;

import java.math.BigDecimal;
import java.util.List;

public class CartResponse {
    private String cartId;
    private List<CartItemResponse> items;
    private Integer totalItems;
    private BigDecimal totalAmount;

    public CartResponse() {}

    public CartResponse(String cartId, List<CartItemResponse> items, Integer totalItems, BigDecimal totalAmount) {
        this.cartId = cartId;
        this.items = items;
        this.totalItems = totalItems;
        this.totalAmount = totalAmount;
    }

    // Getters and Setters
    public String getCartId() {
        return cartId;
    }

    public void setCartId(String cartId) {
        this.cartId = cartId;
    }

    public List<CartItemResponse> getItems() {
        return items;
    }

    public void setItems(List<CartItemResponse> items) {
        this.items = items;
    }

    public Integer getTotalItems() {
        return totalItems;
    }

    public void setTotalItems(Integer totalItems) {
        this.totalItems = totalItems;
    }

    public BigDecimal getTotalAmount() {
        return totalAmount;
    }

    public void setTotalAmount(BigDecimal totalAmount) {
        this.totalAmount = totalAmount;
    }
}
