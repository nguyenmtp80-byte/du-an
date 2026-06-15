package market.campus.com.service;

import market.campus.com.dto.response.ProductDetailResponse;
import market.campus.com.dto.response.ProductImageResponse;
import market.campus.com.dto.response.SellerInfoResponse;
import market.campus.com.exception.ResourceNotFoundException;
import market.campus.com.model.Product;
import market.campus.com.model.ProductImage;
import market.campus.com.repository.ProductRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.util.stream.Collectors;

@Service
public class ProductService {

    @Autowired
    private ProductRepository productRepository;

    public ProductDetailResponse getProductDetail(String productId) {
        Product product = productRepository.findById(productId)
                .orElseThrow(() -> new ResourceNotFoundException("Sản phẩm không tồn tại"));

        // Map images
        var images = product.getImages().stream()
                .map(img -> new ProductImageResponse(img.getId(), img.getImageUrl(), img.getDisplayOrder()))
                .collect(Collectors.toList());

        // Map seller info
        var sellerInfo = new SellerInfoResponse(
                product.getSeller().getId(),
                product.getSeller().getFullName(),
                product.getSeller().getEmail(),
                product.getSeller().getPhone(),
                product.getSeller().getAvatarUrl()
        );

        return new ProductDetailResponse(
                product.getId(),
                product.getName(),
                product.getDescription(),
                product.getPrice(),
                product.getCategory().getName(),
                product.getCondition().toString(),
                product.getStatus().toString(),
                images,
                sellerInfo,
                product.getCreatedAt()
        );
    }
}
