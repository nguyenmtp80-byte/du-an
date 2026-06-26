package market.campus.com.repository;

import market.campus.com.model.Product;
import market.campus.com.model.enums.ProductStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

@Repository
public interface ProductRepository extends JpaRepository<Product, String> {
    Optional<Product> findById(String id);

    List<Product> findByStatus(ProductStatus status);

    @Query(value = "SELECT p.* FROM products p LEFT JOIN users s ON s.id = p.seller_id WHERE " +
           "(cast(:search as text) IS NULL OR p.title ILIKE '%' || cast(:search as text) || '%') " +
           "AND (cast(:category as text) IS NULL OR p.category = cast(:category as text)) " +
           "AND (cast(:status as text) IS NULL OR p.status = cast(:status as text)) " +
           "AND (cast(:minPrice as text) IS NULL OR p.price >= cast(:minPrice as numeric)) " +
           "AND (cast(:maxPrice as text) IS NULL OR p.price <= cast(:maxPrice as numeric)) " +
           "ORDER BY p.created_at DESC", nativeQuery = true)
    List<Product> findFilteredProducts(
            @Param("search") String search,
            @Param("category") String category,
            @Param("status") String status,
            @Param("minPrice") BigDecimal minPrice,
            @Param("maxPrice") BigDecimal maxPrice
    );

    /**
     * Tìm sản phẩm gần vị trí người dùng bằng công thức Haversine.
     * Lọc các sản phẩm có tọa độ và status = 'available',
     * tính khoảng cách (km) từ vị trí người dùng (userLat, userLon) đến sản phẩm.
     * Chỉ trả về sản phẩm có khoảng cách <= radiusKm.
     */
    @Query(value = "SELECT p.* FROM products p " +
           "WHERE p.latitude IS NOT NULL " +
           "AND p.longitude IS NOT NULL " +
           "AND p.status = 'available' " +
           "AND (6371 * acos(cos(radians(:userLat)) * cos(radians(p.latitude)) * " +
           "cos(radians(p.longitude) - radians(:userLon)) + " +
           "sin(radians(:userLat)) * sin(radians(p.latitude)))) <= :radiusKm " +
           "ORDER BY (6371 * acos(cos(radians(:userLat)) * cos(radians(p.latitude)) * " +
           "cos(radians(p.longitude) - radians(:userLon)) + " +
           "sin(radians(:userLat)) * sin(radians(p.latitude)))) ASC", nativeQuery = true)
    List<Product> findNearbyProducts(
            @Param("userLat") Double userLat,
            @Param("userLon") Double userLon,
            @Param("radiusKm") Double radiusKm
    );
}
