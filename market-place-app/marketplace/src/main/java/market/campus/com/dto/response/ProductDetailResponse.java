package market.campus.com.dto.response;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

public class ProductDetailResponse {
    private String id;
    private String name;
    private String description;
    private BigDecimal price;
    private String category;
    private String condition;
    private String status;
    private Integer quantity;
    private List<String> imageUrls;
    private String locationName;
    private Double latitude;
    private Double longitude;
    private SellerInfoResponse seller;
    private LocalDateTime createdAt;

    public ProductDetailResponse() {}

    public ProductDetailResponse(String id, String name, String description, BigDecimal price,
                                 String category, String condition, String status,
                                 Integer quantity, List<String> imageUrls, String locationName,
                                 Double latitude, Double longitude,
                                 SellerInfoResponse seller, LocalDateTime createdAt) {
        this.id = id;
        this.name = name;
        this.description = description;
        this.price = price;
        this.category = category;
        this.condition = condition;
        this.status = status;
        this.quantity = quantity;
        this.imageUrls = imageUrls;
        this.locationName = locationName;
        this.latitude = latitude;
        this.longitude = longitude;
        this.seller = seller;
        this.createdAt = createdAt;
    }

    // Getters and Setters
    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

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

    public Integer getQuantity() { return quantity; }
    public void setQuantity(Integer quantity) { this.quantity = quantity; }

    public List<String> getImageUrls() { return imageUrls; }
    public void setImageUrls(List<String> imageUrls) { this.imageUrls = imageUrls; }

    public String getLocationName() { return locationName; }
    public void setLocationName(String locationName) { this.locationName = locationName; }

    public Double getLatitude() { return latitude; }
    public void setLatitude(Double latitude) { this.latitude = latitude; }

    public Double getLongitude() { return longitude; }
    public void setLongitude(Double longitude) { this.longitude = longitude; }

    public SellerInfoResponse getSeller() { return seller; }
    public void setSeller(SellerInfoResponse seller) { this.seller = seller; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}