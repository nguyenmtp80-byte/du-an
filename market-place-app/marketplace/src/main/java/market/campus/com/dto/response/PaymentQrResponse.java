package market.campus.com.dto.response;

public class PaymentQrResponse {
    private String orderId;
    private int amount;
    private String bankCode;
    private String bankAccountNumber;
    private String bankAccountName;
    private String content;
    private String referenceCode; // Mã tham chiếu để đối soát
    private String qrDataUrl;     // Base64 encoded QR image
    private String paymentUrl;    // VNPay checkout URL
    private String status;

    public PaymentQrResponse() {}

    public PaymentQrResponse(String orderId, int amount, String bankCode, String bankAccountNumber,
                             String bankAccountName, String content, String referenceCode,
                             String qrDataUrl, String paymentUrl, String status) {
        this.orderId = orderId;
        this.amount = amount;
        this.bankCode = bankCode;
        this.bankAccountNumber = bankAccountNumber;
        this.bankAccountName = bankAccountName;
        this.content = content;
        this.referenceCode = referenceCode;
        this.qrDataUrl = qrDataUrl;
        this.paymentUrl = paymentUrl;
        this.status = status;
    }

    public String getOrderId() { return orderId; }
    public void setOrderId(String orderId) { this.orderId = orderId; }

    public int getAmount() { return amount; }
    public void setAmount(int amount) { this.amount = amount; }

    public String getBankCode() { return bankCode; }
    public void setBankCode(String bankCode) { this.bankCode = bankCode; }

    public String getBankAccountNumber() { return bankAccountNumber; }
    public void setBankAccountNumber(String bankAccountNumber) { this.bankAccountNumber = bankAccountNumber; }

    public String getBankAccountName() { return bankAccountName; }
    public void setBankAccountName(String bankAccountName) { this.bankAccountName = bankAccountName; }

    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }

    public String getReferenceCode() { return referenceCode; }
    public void setReferenceCode(String referenceCode) { this.referenceCode = referenceCode; }

    public String getQrDataUrl() { return qrDataUrl; }
    public void setQrDataUrl(String qrDataUrl) { this.qrDataUrl = qrDataUrl; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getPaymentUrl() { return paymentUrl; }
    public void setPaymentUrl(String paymentUrl) { this.paymentUrl = paymentUrl; }
}