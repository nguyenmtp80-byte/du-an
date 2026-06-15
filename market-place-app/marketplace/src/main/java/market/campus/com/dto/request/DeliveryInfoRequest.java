package market.campus.com.dto.request;

public class DeliveryInfoRequest {
    private String receiverName;
    private String receiverPhone;
    private String deliveryLocation;
    private String notes;

    public DeliveryInfoRequest() {}

    public DeliveryInfoRequest(String receiverName, String receiverPhone, String deliveryLocation, String notes) {
        this.receiverName = receiverName;
        this.receiverPhone = receiverPhone;
        this.deliveryLocation = deliveryLocation;
        this.notes = notes;
    }

    // Getters and Setters
    public String getReceiverName() {
        return receiverName;
    }

    public void setReceiverName(String receiverName) {
        this.receiverName = receiverName;
    }

    public String getReceiverPhone() {
        return receiverPhone;
    }

    public void setReceiverPhone(String receiverPhone) {
        this.receiverPhone = receiverPhone;
    }

    public String getDeliveryLocation() {
        return deliveryLocation;
    }

    public void setDeliveryLocation(String deliveryLocation) {
        this.deliveryLocation = deliveryLocation;
    }

    public String getNotes() {
        return notes;
    }

    public void setNotes(String notes) {
        this.notes = notes;
    }
}
