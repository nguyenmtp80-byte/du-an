package market.campus.com.controller;

import market.campus.com.dto.response.OrderResponse;
import market.campus.com.dto.response.PaymentQrResponse;
import market.campus.com.model.User;
import market.campus.com.service.PaymentService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

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

    /**
     * GET /api/payments/{orderId}/qr
     * Tạo QR thanh toán cho đơn hàng (chỉ áp dụng BANK_TRANSFER_QR)
     */
    @GetMapping("/{orderId}/qr")
    public ResponseEntity<?> getPaymentQr(@RequestHeader("X-User-Id") String userId,
                                           @PathVariable String orderId) {
        try {
            User user = new User();
            user.setId(userId);
            PaymentQrResponse qrResponse = paymentService.generatePaymentQr(orderId, user);
            return ResponseEntity.ok(qrResponse);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(new ErrorResponse(e.getMessage()));
        }
    }

    /**
     * PUT /api/payments/{orderId}/confirm
     * Sandbox: Xác nhận đã thanh toán thành công
     * (Trong thực tế, webhook từ ngân hàng sẽ gọi)
     */
    @PutMapping("/{orderId}/confirm")
    public ResponseEntity<?> confirmPayment(@RequestHeader("X-User-Id") String userId,
                                             @PathVariable String orderId) {
        try {
            User user = new User();
            user.setId(userId);
            OrderResponse response = paymentService.confirmPayment(orderId, user);
            return ResponseEntity.ok(new SuccessResponse("Xác nhận thanh toán thành công", response));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(new ErrorResponse(e.getMessage()));
        }
    }

    /**
     * PUT /api/payments/{orderId}/cancel
     * Sandbox: Hủy thanh toán
     */
    @PutMapping("/{orderId}/cancel")
    public ResponseEntity<?> cancelPayment(@RequestHeader("X-User-Id") String userId,
                                            @PathVariable String orderId) {
        try {
            User user = new User();
            user.setId(userId);
            OrderResponse response = paymentService.cancelPayment(orderId, user);
            return ResponseEntity.ok(new SuccessResponse("Hủy thanh toán thành công", response));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(new ErrorResponse(e.getMessage()));
        }
    }
}