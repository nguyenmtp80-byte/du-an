package market.campus.com.model;

import jakarta.persistence.*;
import market.campus.com.model.enums.ProductCondition;
import market.campus.com.model.enums.ProductStatus;
import org.hibernate.annotations.CreationTimestamp;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "products")
public class Product {
    @Id
    @Column(length = 255)
    private String id;

    @Column(nullable = false, length = 255)
    private String title;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal price;

    @Column(name = "image_urls", columnDefinition = "TEXT[]")
    private String[] imageUrls;

    @Column(length = 100)
    private String category;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ProductStatus status;

    @Enumerated(EnumType.STRING)
    @Column(nullable = true)
    private ProductCondition condition;

    @Column(nullable = false)
    private Integer quantity = 1;

    @Column(name = "location_name", length = 255)
    private String locationName;

    @ManyToOne
    @JoinColumn(name = "seller_id", nullable = false)
    private User seller;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    public Product() {}

    public Product(String id, String title, String description, BigDecimal price,
                   String[] imageUrls, String category, ProductCondition condition,
                   ProductStatus status, Integer quantity, String locationName, User seller) {
        this.id = id;
        this.title = title;
        this.description = description;
        this.price = price;
        this.imageUrls = imageUrls;
        this.category = category;
        this.condition = condition;
        this.status = status;
        this.quantity = quantity != null ? quantity : 1;
        this.locationName = locationName;
        this.seller = seller;
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

    public String[] getImageUrls() { return imageUrls; }
    public void setImageUrls(String[] imageUrls) { this.imageUrls = imageUrls; }

    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }

    public ProductCondition getCondition() { return condition; }
    public void setCondition(ProductCondition condition) { this.condition = condition; }

    public ProductStatus getStatus() { return status; }
    public void setStatus(ProductStatus status) { this.status = status; }

    public Integer getQuantity() { return quantity; }
    public void setQuantity(Integer quantity) { this.quantity = quantity; }

    public String getLocationName() { return locationName; }
    public void setLocationName(String locationName) { this.locationName = locationName; }

    public User getSeller() { return seller; }
    public void setSeller(User seller) { this.seller = seller; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    /**
     * Helper method để lấy URL ảnh đầu tiên (cho giỏ hàng, danh sách, v.v.)
     */
    public String getFirstImageUrl() {
        if (imageUrls != null && imageUrls.length > 0) {
            return imageUrls[0];
        }
        return null;
    }
}