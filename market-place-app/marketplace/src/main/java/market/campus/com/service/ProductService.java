package market.campus.com.service;

import market.campus.com.dto.response.ProductDetailResponse;
import market.campus.com.dto.response.ProductImageResponse;
import market.campus.com.dto.response.SellerInfoResponse;
import market.campus.com.exception.ResourceNotFoundException;
import market.campus.com.model.Product;
import market.campus.com.repository.ProductRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.util.Arrays;
import java.util.stream.Collectors;

@Service
public class ProductService {

    @Autowired
    private ProductRepository productRepository;

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