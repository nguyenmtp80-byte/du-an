package market.campus.com.dto.request;

import java.util.List;

public class CreateProductRequest {
    private String title;
    private String description;
    private Integer price;
    private List<String> imageUrls;
    private String category;
    private String condition;
    private Integer quantity;
    private String locationName;

    public CreateProductRequest() {}

    public CreateProductRequest(String title, String description, Integer price,
                                List<String> imageUrls, String category, String condition,
                                Integer quantity, String locationName) {
        this.title = title;
        this.description = description;
        this.price = price;
        this.imageUrls = imageUrls;
        this.category = category;
        this.condition = condition;
        this.quantity = quantity;
        this.locationName = locationName;
    }

    // Getters and Setters
    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public Integer getPrice() { return price; }
    public void setPrice(Integer price) { this.price = price; }

    public List<String> getImageUrls() { return imageUrls; }
    public void setImageUrls(List<String> imageUrls) { this.imageUrls = imageUrls; }

    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }

    public String getCondition() { return condition; }
    public void setCondition(String condition) { this.condition = condition; }

    public Integer getQuantity() { return quantity; }
    public void setQuantity(Integer quantity) { this.quantity = quantity; }

    public String getLocationName() { return locationName; }
    public void setLocationName(String locationName) { this.locationName = locationName; }
}