package market.campus.com.dto.response;

import java.math.BigDecimal;

public class SellerInfoResponse {
    private String id;
    private String fullName;
    private String email;
    private String phone;
    private String avatarUrl;

    public SellerInfoResponse() {}

    public SellerInfoResponse(String id, String fullName, String email, String phone, String avatarUrl) {
        this.id = id;
        this.fullName = fullName;
        this.email = email;
        this.phone = phone;
        this.avatarUrl = avatarUrl;
    }

    // Getters and Setters
    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getFullName() {
        return fullName;
    }

    public void setFullName(String fullName) {
        this.fullName = fullName;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getPhone() {
        return phone;
    }

    public void setPhone(String phone) {
        this.phone = phone;
    }

    public String getAvatarUrl() {
        return avatarUrl;
    }

    public void setAvatarUrl(String avatarUrl) {
        this.avatarUrl = avatarUrl;
    }
}
