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
}
