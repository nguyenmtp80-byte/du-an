package market.campus.com.controller;

import market.campus.com.dto.request.CreateOrderRequest;
import market.campus.com.dto.response.OrderResponse;
import market.campus.com.model.User;
import market.campus.com.service.OrderService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/orders")
@CrossOrigin(origins = "*", maxAge = 3600)
public class OrderController {

    @Autowired
    private OrderService orderService;

    // TODO: Lấy user từ authentication context
    // Tạm thời sử dụng userId từ header

    @PostMapping("/create")
    public ResponseEntity<?> createOrder(@RequestHeader("X-User-Id") String userId,
                                        @RequestBody CreateOrderRequest request) {
        try {
            User user = new User();
            user.setId(userId);
            OrderResponse response = orderService.createOrder(user, request);
            return ResponseEntity.ok(new SuccessResponse("Tạo đơn hàng thành công", response));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(new ErrorResponse(e.getMessage()));
        }
    }

    @GetMapping
    public ResponseEntity<?> getUserOrders(@RequestHeader("X-User-Id") String userId) {
        try {
            User user = new User();
            user.setId(userId);
            List<OrderResponse> response = orderService.getUserOrders(user);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(new ErrorResponse(e.getMessage()));
        }
    }

    // API: Seller lấy danh sách đơn hàng của mình
    @GetMapping("/seller/list")
    public ResponseEntity<?> getSellerOrders(@RequestHeader("X-User-Id") String userId) {
        try {
            User seller = new User();
            seller.setId(userId);
            List<OrderResponse> response = orderService.getSellerOrders(seller);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(new ErrorResponse(e.getMessage()));
        }
    }

    @GetMapping("/{orderId}")
    public ResponseEntity<?> getOrderDetail(@RequestHeader("X-User-Id") String userId,
                                           @PathVariable String orderId) {
        try {
            User user = new User();
            user.setId(userId);
            OrderResponse response = orderService.getOrderDetail(orderId, user);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(new ErrorResponse(e.getMessage()));
        }
    }

    // API 1: Seller accepts/approves an order
    @PutMapping("/{orderId}/accept")
    public ResponseEntity<?> acceptOrder(@RequestHeader("X-User-Id") String userId,
                                         @PathVariable String orderId) {
        try {
            User seller = new User();
            seller.setId(userId);
            OrderResponse response = orderService.acceptOrder(orderId, seller);
            return ResponseEntity.ok(new SuccessResponse("Xác nhận đơn hàng thành công", response));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(new ErrorResponse(e.getMessage()));
        }
    }

    // API: Buyer cancels an order
    @PutMapping("/{orderId}/cancel")
    public ResponseEntity<?> cancelOrder(@RequestHeader("X-User-Id") String userId,
                                          @PathVariable String orderId) {
        try {
            User buyer = new User();
            buyer.setId(userId);
            OrderResponse response = orderService.cancelOrder(orderId, buyer);
            return ResponseEntity.ok(new SuccessResponse("Hủy đơn hàng thành công", response));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(new ErrorResponse(e.getMessage()));
        }
    }

    // API 2: Seller completes an order
    @PutMapping("/{orderId}/complete")
    public ResponseEntity<?> completeOrder(@RequestHeader("X-User-Id") String userId,
                                           @PathVariable String orderId) {
        try {
            User seller = new User();
            seller.setId(userId);
            OrderResponse response = orderService.completeOrder(orderId, seller);
            return ResponseEntity.ok(new SuccessResponse("Hoàn tất đơn hàng thành công", response));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(new ErrorResponse(e.getMessage()));
        }
    }

    // Inner classes cho responses
    public static class SuccessResponse {
        private String message;
        private Object data;

        public SuccessResponse(String message, Object data) {
            this.message = message;
            this.data = data;
        }

        public String getMessage() {
            return message;
        }

        public void setMessage(String message) {
            this.message = message;
        }

        public Object getData() {
            return data;
        }

        public void setData(Object data) {
            this.data = data;
        }
    }

    public static class ErrorResponse {
        private String message;

        public ErrorResponse(String message) {
            this.message = message;
        }

        public String getMessage() {
            return message;
        }

        public void setMessage(String message) {
            this.message = message;
        }
    }
}
