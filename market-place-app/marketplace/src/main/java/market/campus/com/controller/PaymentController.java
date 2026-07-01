package market.campus.com.controller;

import market.campus.com.dto.response.OrderResponse;
import market.campus.com.dto.response.PaymentQrResponse;
import market.campus.com.model.User;
import market.campus.com.service.PaymentService;
import market.campus.com.service.PaymentService.PaymentInfoResponse;
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

    // ==================== THÔNG TIN THANH TOÁN ====================

    /**
     * GET /api/payments/{orderId}/info
     * Lấy thông tin thanh toán + hướng dẫn theo phương thức
     */
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

    // ==================== QR PAYMENT ====================

    /**
     * GET /api/payments/{orderId}/qr
     * Tạo QR thanh toán (chỉ BANK_TRANSFER_QR)
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
     * PUT /api/payments/{orderId}/qr/confirm
     * Xác nhận đã thanh toán QR (sandbox) — PENDING → APPROVED
     */
    @PutMapping("/{orderId}/qr/confirm")
    public ResponseEntity<?> confirmQrPayment(@RequestHeader("X-User-Id") String userId,
                                               @PathVariable String orderId) {
        try {
            User user = new User();
            user.setId(userId);
            OrderResponse response = paymentService.confirmQrPayment(orderId, user);
            return ResponseEntity.ok(new SuccessResponse("Xác nhận thanh toán QR thành công", response));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(new ErrorResponse(e.getMessage()));
        }
    }

    /**
     * PUT /api/payments/{orderId}/qr/cancel
     * Hủy thanh toán QR — PENDING → CANCELLED
     */
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

    // ==================== CASH PAYMENT ====================

    /**
     * PUT /api/payments/{orderId}/cash/confirm
     * Xác nhận đã thanh toán tiền mặt (khi nhận hàng)
     * APPROVED → COMPLETED
     * Cả buyer và seller đều có thể gọi
     */
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

    /**
     * PUT /api/payments/{orderId}/cash/cancel
     * Hủy đơn hàng tiền mặt khi chưa xác nhận
     * PENDING → CANCELLED
     */
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
}