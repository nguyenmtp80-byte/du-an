package market.campus.com.service;

import market.campus.com.dto.response.ProductDetailResponse;
import market.campus.com.dto.response.ProductListResponse;
import market.campus.com.dto.response.SellerInfoResponse;
import market.campus.com.exception.ResourceNotFoundException;
import market.campus.com.model.Product;
import market.campus.com.repository.ProductRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.math.BigDecimal;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class ProductService {

    @Autowired
    private ProductRepository productRepository;

    public List<ProductListResponse> getAllProducts(String search, String category,
                                                     String status, BigDecimal minPrice,
                                                     BigDecimal maxPrice) {
        // Chuẩn hóa status thành uppercase để khớp với ENUM trong DB
        String statusParam = null;
        if (status != null && !status.isEmpty()) {
            statusParam = status.toUpperCase();
        }

        List<Product> products = productRepository.findFilteredProducts(
                search, category, statusParam, minPrice, maxPrice
        );

        return products.stream()
                .map(this::toProductListResponse)
                .collect(Collectors.toList());
    }

    private ProductListResponse toProductListResponse(Product product) {
        List<String> imageUrls = product.getImageUrls() != null
                ? Arrays.asList(product.getImageUrls())
                : Collections.emptyList();

        SellerInfoResponse sellerInfo = null;
        if (product.getSeller() != null) {
            sellerInfo = new SellerInfoResponse(
                    product.getSeller().getId(),
                    product.getSeller().getFullName() != null ? product.getSeller().getFullName() : "",
                    product.getSeller().getEmail(),
                    product.getSeller().getPhone(),
                    product.getSeller().getAvatarUrl()
            );
        }

        return new ProductListResponse(
                product.getId(),
                product.getTitle() != null ? product.getTitle() : "",
                product.getDescription(),
                product.getPrice(),
                imageUrls,
                product.getCategory(),
                product.getStatus() != null ? product.getStatus().toString() : "AVAILABLE",
                product.getLocationName(),
                sellerInfo,
                product.getCreatedAt()
        );
    }

    public ProductDetailResponse getProductDetail(String productId) {
        Product product = productRepository.findById(productId)
                .orElseThrow(() -> new ResourceNotFoundException("Sản phẩm không tồn tại"));

        // Map image_urls array to list of strings
        var imageUrls = product.getImageUrls() != null 
            ? Arrays.asList(product.getImageUrls()) 
            : java.util.Collections.<String>emptyList();

        // Map seller info
        var sellerInfo = new SellerInfoResponse(
                product.getSeller().getId(),
                product.getSeller().getFullName(),
                product.getSeller().getEmail(),
                product.getSeller().getPhone(),
                product.getSeller().getAvatarUrl()
        );

        // Map condition - handle null safely
        String conditionStr = product.getCondition() != null ? product.getCondition().toString() : null;

        return new ProductDetailResponse(
                product.getId(),
                product.getTitle(),
                product.getDescription(),
                product.getPrice(),
                product.getCategory(),
                conditionStr,
                product.getStatus().toString(),
                imageUrls,
                product.getLocationName(),
                sellerInfo,
                product.getCreatedAt()
        );
    }
}