package market.campus.com.controller;

import market.campus.com.dto.response.OrderResponse;
import market.campus.com.dto.response.PaymentQrResponse;
import market.campus.com.dto.response.PaymentTransactionResponse;
import market.campus.com.model.User;
import market.campus.com.service.PaymentService;
import market.campus.com.service.PaymentService.PaymentInfoResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/payments")
@CrossOrigin(origins = "*", maxAge = 3600)
public class PaymentController {

    @Autowired
    private PaymentService paymentService;

    public static class ErrorResponse {
        private String message;
        public ErrorResponse(String message) { this.message = message; }
        public String getMessage() { return message; }
        public void setMessage(String message) { this.message = message; }
    }

    public static class SuccessResponse {
        private String message;
        private Object data;
        public SuccessResponse(String message, Object data) {
            this.message = message;
            this.data = data;
        }
        public String getMessage() { return message; }
        public void setMessage(String message) { this.message = message; }
        public Object getData() { return data; }
        public void setData(Object data) { this.data = data; }
    }

    // ==================== THÔNG TIN THANH TOÁN ====================

    @GetMapping("/{orderId}/info")
    public ResponseEntity<?> getPaymentInfo(@RequestHeader("X-User-Id") String userId,
                                             @PathVariable String orderId) {
        try {
            User user = new User();
            user.setId(userId);
            PaymentInfoResponse info = paymentService.getPaymentInfo(orderId, user);
            return ResponseEntity.ok(info);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(new ErrorResponse(e.getMessage()));
        }
    }

    // ==================== BƯỚC 1: SINH QR ====================

    @GetMapping("/{orderId}/qr")
    public ResponseEntity<?> getPaymentQr(@RequestHeader("X-User-Id") String userId,
                                           @PathVariable String orderId,
                                           jakarta.servlet.http.HttpServletRequest request) {
        try {
            User user = new User();
            user.setId(userId);
            String ipAddress = market.campus.com.config.VnpayConfig.getIpAddress(request);
            PaymentQrResponse qrResponse = paymentService.generatePaymentQr(orderId, user, ipAddress);
            return ResponseEntity.ok(qrResponse);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(new ErrorResponse(e.getMessage()));
        }
    }

    // ==================== BƯỚC 2: WEBHOOK - HỆ THỐNG NHẬN TIỀN ====================
    // *** ĐÂY LÀ BƯỚC QUAN TRỌNG NHẤT ***

    /**
     * POST /api/payments/webhook
     * 
     * SANDBOX: Frontend gọi API này khi user nhấn "Tôi đã chuyển khoản"
     * THỰC TẾ: Ngân hàng gọi webhook này khi có giao dịch đến
     * 
     * Body: { "referenceCode": "MARKET-abc12345", "amount": 15000000, "bankTransactionId": "REF123" }
     */
    @PostMapping("/webhook")
    public ResponseEntity<?> bankWebhook(@RequestBody Map<String, Object> webhookData) {
        try {
            String referenceCode = (String) webhookData.get("referenceCode");
            int amount = Integer.parseInt(webhookData.get("amount").toString());
            String bankTransactionId = (String) webhookData.getOrDefault("bankTransactionId", null);

            PaymentTransactionResponse response = paymentService.processBankWebhook(referenceCode, amount, bankTransactionId);
            return ResponseEntity.ok(new SuccessResponse("Xử lý webhook thành công", response));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(new ErrorResponse(e.getMessage()));
        }
    }

    /**
     * POST /api/payments/{orderId}/confirm-transfer
     * 
     * Frontend gọi API này khi user nhấn "Tôi đã chuyển khoản".
     * Hệ thống tự động lấy referenceCode từ orderId và gọi webhook.
     * 
     * Đây là cách đơn giản hơn để test trên Postman (không cần biết referenceCode)
     */
    @PostMapping("/{orderId}/confirm-transfer")
    public ResponseEntity<?> confirmTransfer(@RequestHeader("X-User-Id") String userId,
                                              @PathVariable String orderId,
                                              jakarta.servlet.http.HttpServletRequest request) {
        try {
            User user = new User();
            user.setId(userId);
            
            String ipAddress = market.campus.com.config.VnpayConfig.getIpAddress(request);
            // Trước tiên kiểm tra user có phải buyer không
            PaymentQrResponse qrCheck = paymentService.generatePaymentQr(orderId, user, ipAddress);
            
            // Gọi webhook với thông tin từ QR
            String refCode = qrCheck.getReferenceCode();
            int amount = qrCheck.getAmount();
            
            PaymentTransactionResponse response = paymentService.processBankWebhook(refCode, amount, "MANUAL-" + System.currentTimeMillis());
            return ResponseEntity.ok(new SuccessResponse("Xác nhận chuyển khoản thành công", response));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(new ErrorResponse(e.getMessage()));
        }
    }

    // ==================== BƯỚC 2.5: VNPAY IPN & RETURN ====================

    @GetMapping("/vnpay/ipn")
    public ResponseEntity<?> vnpayIpn(@RequestParam Map<String, String> allParams) {
        try {
            String result = paymentService.processVnpayIpn(allParams);
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            return ResponseEntity.ok("{\"RspCode\":\"99\",\"Message\":\"Unknown error\"}");
        }
    }

    @GetMapping("/vnpay/return")
    public ResponseEntity<?> vnpayReturn(@RequestParam Map<String, String> allParams) {
        // Redirect to deep-link to open the Flutter app
        String responseCode = allParams.get("vnp_ResponseCode");
        String txnRef = allParams.get("vnp_TxnRef");
        // Deep link format (can be customized)
        String deepLink = "marketcampus://payment-result?txnRef=" + txnRef + "&responseCode=" + responseCode;
        
        return ResponseEntity.status(org.springframework.http.HttpStatus.FOUND)
                .header(org.springframework.http.HttpHeaders.LOCATION, deepLink)
                .build();
    }

    // ==================== BƯỚC 3: KIỂM TRA GIAO DỊCH ====================

    @GetMapping("/{orderId}/transaction")
    public ResponseEntity<?> checkTransaction(@RequestHeader("X-User-Id") String userId,
                                               @PathVariable String orderId) {
        try {
            User user = new User();
            user.setId(userId);
            PaymentTransactionResponse response = paymentService.checkTransaction(orderId, user);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(new ErrorResponse(e.getMessage()));
        }
    }

    // ==================== BƯỚC 4: SELLER XÁC NHẬN ĐÃ NHẬN TIỀN ====================

    @PutMapping("/{orderId}/seller-confirm")
    public ResponseEntity<?> confirmSellerReceived(@RequestHeader("X-User-Id") String userId,
                                                    @PathVariable String orderId) {
        try {
            User seller = new User();
            seller.setId(userId);
            OrderResponse response = paymentService.confirmSellerReceived(orderId, seller);
            return ResponseEntity.ok(new SuccessResponse("Xác nhận đã nhận được tiền thành công", response));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(new ErrorResponse(e.getMessage()));
        }
    }

    // ==================== CÁC API KHÁC ====================

    @PutMapping("/{orderId}/qr/cancel")
    public ResponseEntity<?> cancelQrPayment(@RequestHeader("X-User-Id") String userId,
                                              @PathVariable String orderId) {
        try {
            User user = new User();
            user.setId(userId);
            OrderResponse response = paymentService.cancelQrPayment(orderId, user);
            return ResponseEntity.ok(new SuccessResponse("Hủy thanh toán QR thành công", response));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(new ErrorResponse(e.getMessage()));
        }
    }

    @PutMapping("/{orderId}/cash/confirm")
    public ResponseEntity<?> confirmCashPayment(@RequestHeader("X-User-Id") String userId,
                                                 @PathVariable String orderId) {
        try {
            User user = new User();
            user.setId(userId);
            OrderResponse response = paymentService.confirmCashPayment(orderId, user);
            return ResponseEntity.ok(new SuccessResponse("Xác nhận thanh toán tiền mặt thành công", response));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(new ErrorResponse(e.getMessage()));
        }
    }

    @PutMapping("/{orderId}/cash/cancel")
    public ResponseEntity<?> cancelCashOrder(@RequestHeader("X-User-Id") String userId,
                                              @PathVariable String orderId) {
        try {
            User user = new User();
            user.setId(userId);
            OrderResponse response = paymentService.cancelCashOrder(orderId, user);
            return ResponseEntity.ok(new SuccessResponse("Hủy đơn hàng tiền mặt thành công", response));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(new ErrorResponse(e.getMessage()));
        }
    }

    @GetMapping("/transactions")
    public ResponseEntity<?> getUserTransactions(@RequestHeader("X-User-Id") String userId) {
        try {
            User user = new User();
            user.setId(userId);
            List<PaymentTransactionResponse> transactions = paymentService.getUserTransactions(user);
            return ResponseEntity.ok(transactions);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(new ErrorResponse(e.getMessage()));
        }
    }
}