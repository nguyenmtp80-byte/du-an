package market.campus.com.dto.response;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

public class ProductDetailResponse {
    private String id;
    private String name;
    private String description;
    private BigDecimal price;
    private String categoryName;
    private String condition;
    private String status;
    private List<ProductImageResponse> images;
    private SellerInfoResponse seller;
    private LocalDateTime createdAt;

    public ProductDetailResponse() {}

    public ProductDetailResponse(String id, String name, String description, BigDecimal price,
                                 String categoryName, String condition, String status,
                                 List<ProductImageResponse> images, SellerInfoResponse seller,
                                 LocalDateTime createdAt) {
        this.id = id;
        this.name = name;
        this.description = description;
        this.price = price;
        this.categoryName = categoryName;
        this.condition = condition;
        this.status = status;
        this.images = images;
        this.seller = seller;
        this.createdAt = createdAt;
    }

    // Getters and Setters
    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public BigDecimal getPrice() {
        return price;
    }

    public void setPrice(BigDecimal price) {
        this.price = price;
    }

    public String getCategoryName() {
        return categoryName;
    }

    public void setCategoryName(String categoryName) {
        this.categoryName = categoryName;
    }

    public String getCondition() {
        return condition;
    }

    public void setCondition(String condition) {
        this.condition = condition;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public List<ProductImageResponse> getImages() {
        return images;
    }

    public void setImages(List<ProductImageResponse> images) {
        this.images = images;
    }

    public SellerInfoResponse getSeller() {
        return seller;
    }

    public void setSeller(SellerInfoResponse seller) {
        this.seller = seller;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
}
