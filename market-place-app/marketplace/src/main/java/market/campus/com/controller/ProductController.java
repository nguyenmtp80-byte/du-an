package market.campus.com.controller;

import market.campus.com.dto.request.CreateProductRequest;
import market.campus.com.dto.response.NearbyProductResponse;
import market.campus.com.dto.response.ProductDetailResponse;
import market.campus.com.dto.response.ProductListResponse;
import market.campus.com.service.ProductService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;

@RestController
@RequestMapping("/api/products")
@CrossOrigin(origins = "*", maxAge = 3600)
public class ProductController {

    @Autowired
    private ProductService productService;

    /**
     * GET /api/products - Lấy danh sách sản phẩm với các bộ lọc
     * Query params: search, category, status, minPrice, maxPrice
     */
    @GetMapping
    public ResponseEntity<?> getAllProducts(
            @RequestParam(required = false) String search,
            @RequestParam(required = false) String category,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) BigDecimal minPrice,
            @RequestParam(required = false) BigDecimal maxPrice) {
        try {
            List<ProductListResponse> products = productService.getAllProducts(
                    search, category, status, minPrice, maxPrice
            );
            return ResponseEntity.ok(products);
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(
                    new ErrorResponse("Lỗi khi lấy danh sách sản phẩm: " + e.getMessage())
            );
        }
    }

    /**
     * POST /api/products - Tạo sản phẩm mới (đăng bán)
     */
    @PostMapping
    public ResponseEntity<?> createProduct(@RequestHeader("X-User-Id") String userId,
                                           @RequestBody CreateProductRequest request) {
        try {
            ProductDetailResponse product = productService.createProduct(userId, request);
            return ResponseEntity.ok(product);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(new ErrorResponse(e.getMessage()));
        }
    }

    /**
     * GET /api/products/nearby - Tìm sản phẩm gần vị trí người dùng
     * Query params: lat (latitude), lng (longitude), radius (km)
     * LƯU Ý: Phải đặt trước /{productId} để tránh xung đột route
     */
    @GetMapping("/nearby")
    public ResponseEntity<?> getNearbyProducts(
            @RequestParam("lat") Double latitude,
            @RequestParam("lng") Double longitude,
            @RequestParam(name = "radius", defaultValue = "5") Double radiusKm) {
        try {
            List<NearbyProductResponse> products = productService.getNearbyProducts(
                    latitude, longitude, radiusKm
            );
            return ResponseEntity.ok(products);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(new ErrorResponse(e.getMessage()));
        }
    }

    @GetMapping("/{productId}")
    public ResponseEntity<?> getProductDetail(@PathVariable String productId) {
        try {
            ProductDetailResponse product = productService.getProductDetail(productId);
            return ResponseEntity.ok(product);
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
