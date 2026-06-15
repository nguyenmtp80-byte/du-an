package market.campus.com.dto.request;

public class CreateOrderRequest {
    private String paymentMethod;
    private DeliveryInfoRequest deliveryInfo;

    public CreateOrderRequest() {}

    public CreateOrderRequest(String paymentMethod, DeliveryInfoRequest deliveryInfo) {
        this.paymentMethod = paymentMethod;
        this.deliveryInfo = deliveryInfo;
    }

    // Getters and Setters
    public String getPaymentMethod() {
        return paymentMethod;
    }

    public void setPaymentMethod(String paymentMethod) {
        this.paymentMethod = paymentMethod;
    }

    public DeliveryInfoRequest getDeliveryInfo() {
        return deliveryInfo;
    }

    public void setDeliveryInfo(DeliveryInfoRequest deliveryInfo) {
        this.deliveryInfo = deliveryInfo;
    }
}
