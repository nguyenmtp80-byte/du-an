package market.campus.com.repository;

import market.campus.com.model.Cart;
import market.campus.com.model.Product;
import market.campus.com.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface CartRepository extends JpaRepository<Cart, String> {
    List<Cart> findByUser(User user);
    Optional<Cart> findByUserAndProduct(User user, Product product);
    void deleteByUser(User user);
}