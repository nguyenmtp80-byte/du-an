package market.campus.com.repository;

import market.campus.com.model.Cart;
import market.campus.com.model.CartItem;
import market.campus.com.model.Product;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface CartItemRepository extends JpaRepository<CartItem, String> {
    Optional<CartItem> findByCartAndProduct(Cart cart, Product product);
}
