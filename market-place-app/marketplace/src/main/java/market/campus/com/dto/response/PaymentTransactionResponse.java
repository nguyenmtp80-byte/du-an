package market.campus.com.dto.response;

import java.time.LocalDateTime;

public class PaymentTransactionResponse {
    private String transactionId;
    private String orderId;
    private String referenceCode;
    private int amount;
    private String bankCode;
    private String bankAccountNumber;
    private String bankAccountName;
    private String transferContent;
    private String status; // PENDING, SUCCESS, FAILED
    private String note;
    private LocalDateTime createdAt;
    private LocalDateTime confirmedAt;

    public PaymentTransactionResponse() {}

    public PaymentTransactionResponse(String transactionId, String orderId, String referenceCode,
                                      int amount, String bankCode, String bankAccountNumber,
                                      String bankAccountName, String transferContent, String status,
                                      String note, LocalDateTime createdAt, LocalDateTime confirmedAt) {
        this.transactionId = transactionId;
        this.orderId = orderId;
        this.referenceCode = referenceCode;
        this.amount = amount;
        this.bankCode = bankCode;
        this.bankAccountNumber = bankAccountNumber;
        this.bankAccountName = bankAccountName;
        this.transferContent = transferContent;
        this.status = status;
        this.note = note;
        this.createdAt = createdAt;
        this.confirmedAt = confirmedAt;
    }

    public String getTransactionId() { return transactionId; }
    public void setTransactionId(String transactionId) { this.transactionId = transactionId; }

    public String getOrderId() { return orderId; }
    public void setOrderId(String orderId) { this.orderId = orderId; }

    public String getReferenceCode() { return referenceCode; }
    public void setReferenceCode(String referenceCode) { this.referenceCode = referenceCode; }

    public int getAmount() { return amount; }
    public void setAmount(int amount) { this.amount = amount; }

    public String getBankCode() { return bankCode; }
    public void setBankCode(String bankCode) { this.bankCode = bankCode; }

    public String getBankAccountNumber() { return bankAccountNumber; }
    public void setBankAccountNumber(String bankAccountNumber) { this.bankAccountNumber = bankAccountNumber; }

    public String getBankAccountName() { return bankAccountName; }
    public void setBankAccountName(String bankAccountName) { this.bankAccountName = bankAccountName; }

    public String getTransferContent() { return transferContent; }
    public void setTransferContent(String transferContent) { this.transferContent = transferContent; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getNote() { return note; }
    public void setNote(String note) { this.note = note; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public LocalDateTime getConfirmedAt() { return confirmedAt; }
    public void setConfirmedAt(LocalDateTime confirmedAt) { this.confirmedAt = confirmedAt; }
}