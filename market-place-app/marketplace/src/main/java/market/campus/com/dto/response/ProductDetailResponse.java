package market.campus.com.dto.response;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

public class ProductDetailResponse {
    private String id;
    private String title;
    private String description;
    private BigDecimal price;
    private String category;
    private String condition;
    private String status;
    private List<String> imageUrls;
    private String locationName;
    private SellerInfoResponse seller;
    private LocalDateTime createdAt;

    public ProductDetailResponse() {}

    public ProductDetailResponse(String id, String title, String description, BigDecimal price,
                                 String category, String condition, String status,
                                 List<String> imageUrls, String locationName,
                                 SellerInfoResponse seller, LocalDateTime createdAt) {
        this.id = id;
        this.title = title;
        this.description = description;
        this.price = price;
        this.category = category;
        this.condition = condition;
        this.status = status;
        this.imageUrls = imageUrls;
        this.locationName = locationName;
        this.seller = seller;
        this.createdAt = createdAt;
    }

    // Getters and Setters
    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public BigDecimal getPrice() { return price; }
    public void setPrice(BigDecimal price) { this.price = price; }

    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }

    public String getCondition() { return condition; }
    public void setCondition(String condition) { this.condition = condition; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public List<String> getImageUrls() { return imageUrls; }
    public void setImageUrls(List<String> imageUrls) { this.imageUrls = imageUrls; }

    public String getLocationName() { return locationName; }
    public void setLocationName(String locationName) { this.locationName = locationName; }

    public SellerInfoResponse getSeller() { return seller; }
    public void setSeller(SellerInfoResponse seller) { this.seller = seller; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}