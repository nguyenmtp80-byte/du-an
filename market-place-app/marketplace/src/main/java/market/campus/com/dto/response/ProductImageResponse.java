package market.campus.com.dto.response;

public class ProductImageResponse {
    private String id;
    private String imageUrl;
    private Integer displayOrder;

    public ProductImageResponse() {}

    public ProductImageResponse(String id, String imageUrl, Integer displayOrder) {
        this.id = id;
        this.imageUrl = imageUrl;
        this.displayOrder = displayOrder;
    }

    // Getters and Setters
    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getImageUrl() {
        return imageUrl;
    }

    public void setImageUrl(String imageUrl) {
        this.imageUrl = imageUrl;
    }

    public Integer getDisplayOrder() {
        return displayOrder;
    }

    public void setDisplayOrder(Integer displayOrder) {
        this.displayOrder = displayOrder;
    }
}
