package market.campus.com.controller;

import market.campus.com.dto.request.AddToCartRequest;
import market.campus.com.dto.request.UpdateCartItemRequest;
import market.campus.com.dto.response.CartResponse;
import market.campus.com.model.User;
import market.campus.com.service.CartService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/cart")
@CrossOrigin(origins = "*", maxAge = 3600)
public class CartController {

    @Autowired
    private CartService cartService;

    // TODO: Lấy user từ authentication context
    // Tạm thời sử dụng userId từ header

    @PostMapping("/add")
    public ResponseEntity<?> addToCart(@RequestHeader("X-User-Id") String userId, 
                                       @RequestBody AddToCartRequest request) {
        try {
            User user = new User();
            user.setId(userId);
            CartResponse response = cartService.addToCart(user, request);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(new ErrorResponse(e.getMessage()));
        }
    }

    @GetMapping
    public ResponseEntity<?> getCart(@RequestHeader("X-User-Id") String userId) {
        try {
            User user = new User();
            user.setId(userId);
            CartResponse response = cartService.getCart(user);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(new ErrorResponse(e.getMessage()));
        }
    }

    @PutMapping("/update")
    public ResponseEntity<?> updateCartItem(@RequestHeader("X-User-Id") String userId,
                                           @RequestBody UpdateCartItemRequest request) {
        try {
            User user = new User();
            user.setId(userId);
            CartResponse response = cartService.updateCartItem(user, request);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(new ErrorResponse(e.getMessage()));
        }
    }

    @DeleteMapping("/{cartItemId}")
    public ResponseEntity<?> removeFromCart(@RequestHeader("X-User-Id") String userId,
                                           @PathVariable String cartItemId) {
        try {
            User user = new User();
            user.setId(userId);
            CartResponse response = cartService.removeFromCart(user, cartItemId);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(new ErrorResponse(e.getMessage()));
        }
    }

    // Inner class cho error response
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
