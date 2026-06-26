package market.campus.com.service;

import market.campus.com.dto.request.CreateProductRequest;
import market.campus.com.dto.response.NearbyProductResponse;
import market.campus.com.dto.response.ProductDetailResponse;
import market.campus.com.dto.response.ProductListResponse;
import market.campus.com.dto.response.SellerInfoResponse;
import market.campus.com.exception.InvalidDataException;
import market.campus.com.exception.ResourceNotFoundException;
import market.campus.com.model.Product;
import market.campus.com.model.User;
import market.campus.com.model.enums.ProductCondition;
import market.campus.com.model.enums.ProductStatus;
import market.campus.com.repository.ProductRepository;
import market.campus.com.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.math.BigDecimal;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class ProductService {

    @Autowired
    private ProductRepository productRepository;

    @Autowired
    private UserRepository userRepository;

    @Transactional
    public ProductDetailResponse createProduct(String userId, CreateProductRequest request) {
        // Validate required fields
        if (request.getTitle() == null || request.getTitle().trim().isEmpty()) {
            throw new InvalidDataException("Tên sản phẩm không được để trống");
        }
        if (request.getPrice() == null || request.getPrice() <= 0) {
            throw new InvalidDataException("Giá sản phẩm phải lớn hơn 0");
        }

        // Validate coordinates (nếu có cung cấp)
        if (request.getLatitude() != null || request.getLongitude() != null) {
            if (request.getLatitude() == null || request.getLongitude() == null) {
                throw new InvalidDataException("Phải cung cấp đầy đủ cả latitude và longitude");
            }
            validateCoordinates(request.getLatitude(), request.getLongitude());
        }

        User seller = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("Người dùng không tồn tại"));

        // Parse condition
        ProductCondition condition = ProductCondition.USED;
        if (request.getCondition() != null) {
            try {
                condition = ProductCondition.valueOf(request.getCondition().toUpperCase());
            } catch (IllegalArgumentException e) {
                throw new InvalidDataException("Tình trạng sản phẩm không hợp lệ: " + request.getCondition());
            }
        }

        // Convert image URLs list to array
        String[] imageUrlsArray = null;
        if (request.getImageUrls() != null && !request.getImageUrls().isEmpty()) {
            imageUrlsArray = request.getImageUrls().toArray(new String[0]);
        }

        Product product = new Product(
                UUID.randomUUID().toString(),
                request.getTitle(),
                request.getDescription(),
                BigDecimal.valueOf(request.getPrice()),
                imageUrlsArray,
                request.getCategory(),
                condition,
                ProductStatus.available,
                request.getQuantity() != null ? request.getQuantity() : 1,
                request.getLocationName(),
                request.getLatitude(),
                request.getLongitude(),
                seller
        );

        product = productRepository.save(product);

        return getProductDetail(product.getId());
    }

    public List<ProductListResponse> getAllProducts(String search, String category,
                                                     String status, BigDecimal minPrice,
                                                     BigDecimal maxPrice) {
        // Chuẩn hóa status theo enum DB (available, sold)
        String statusParam = null;
        if (status != null && !status.isEmpty()) {
            statusParam = status.toLowerCase();
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
                product.getCondition() != null ? product.getCondition().toString() : null,
                product.getStatus() != null ? product.getStatus().toString() : "available",
                product.getQuantity() != null ? product.getQuantity() : 0,
                product.getLocationName(),
                product.getLatitude(),
                product.getLongitude(),
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
                product.getQuantity() != null ? product.getQuantity() : 0,
                imageUrls,
                product.getLocationName(),
                product.getLatitude(),
                product.getLongitude(),
                sellerInfo,
                product.getCreatedAt()
        );
    }

    /**
     * Tìm sản phẩm gần vị trí người dùng.
     *
     * @param userLat   Vĩ độ của người dùng
     * @param userLon   Kinh độ của người dùng
     * @param radiusKm  Bán kính tìm kiếm (km)
     * @return Danh sách sản phẩm kèm khoảng cách
     */
    public List<NearbyProductResponse> getNearbyProducts(Double userLat, Double userLon, Double radiusKm) {
        // Validate coordinates
        if (userLat == null || userLon == null) {
            throw new InvalidDataException("Vị trí người dùng không hợp lệ: thiếu tọa độ");
        }
        validateCoordinates(userLat, userLon);

        // Validate search radius
        if (radiusKm == null || radiusKm <= 0) {
            throw new InvalidDataException("Bán kính tìm kiếm phải lớn hơn 0");
        }
        if (radiusKm > 50) {
            throw new InvalidDataException("Bán kính tìm kiếm không được vượt quá 50km");
        }

        List<Product> products = productRepository.findNearbyProducts(userLat, userLon, radiusKm);

        return products.stream()
                .map(product -> toNearbyProductResponse(product, userLat, userLon))
                .collect(Collectors.toList());
    }

    /**
     * Chuyển đổi Product thành NearbyProductResponse kèm khoảng cách tính bằng Haversine.
     */
    private NearbyProductResponse toNearbyProductResponse(Product product, Double userLat, Double userLon) {
        double distance = calculateDistance(userLat, userLon,
                product.getLatitude(), product.getLongitude());

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

        // Làm tròn distance 2 chữ số thập phân để bảo vệ quyền riêng tư
        double roundedDistance = Math.round(distance * 100.0) / 100.0;

        return new NearbyProductResponse(
                product.getId(),
                product.getTitle() != null ? product.getTitle() : "",
                product.getDescription(),
                product.getPrice(),
                imageUrls,
                product.getCategory(),
                product.getCondition() != null ? product.getCondition().toString() : null,
                product.getStatus() != null ? product.getStatus().toString() : "available",
                product.getQuantity() != null ? product.getQuantity() : 0,
                product.getLocationName(),
                product.getLatitude(),
                product.getLongitude(),
                roundedDistance,
                sellerInfo,
                product.getCreatedAt()
        );
    }

    /**
     * Tính khoảng cách giữa hai điểm GPS bằng công thức Haversine.
     *
     * @param lat1 Vĩ độ điểm 1
     * @param lon1 Kinh độ điểm 1
     * @param lat2 Vĩ độ điểm 2
     * @param lon2 Kinh độ điểm 2
     * @return Khoảng cách tính bằng km
     */
    private double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
        final int EARTH_RADIUS_KM = 6371;

        double latDistance = Math.toRadians(lat2 - lat1);
        double lonDistance = Math.toRadians(lon2 - lon1);

        double a = Math.sin(latDistance / 2) * Math.sin(latDistance / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                * Math.sin(lonDistance / 2) * Math.sin(lonDistance / 2);

        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

        return EARTH_RADIUS_KM * c;
    }

    /**
     * Validate tọa độ GPS.
     */
    private void validateCoordinates(Double latitude, Double longitude) {
        if (latitude == null || longitude == null) {
            throw new InvalidDataException("Thiếu tọa độ vị trí");
        }
        if (latitude < -90 || latitude > 90) {
            throw new InvalidDataException("Latitude không hợp lệ: phải nằm trong khoảng -90 đến 90");
        }
        if (longitude < -180 || longitude > 180) {
            throw new InvalidDataException("Longitude không hợp lệ: phải nằm trong khoảng -180 đến 180");
        }
    }
}
