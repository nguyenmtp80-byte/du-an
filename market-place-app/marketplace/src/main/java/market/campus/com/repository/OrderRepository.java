package market.campus.com.repository;

import market.campus.com.model.Order;
import market.campus.com.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface OrderRepository extends JpaRepository<Order, String> {
    List<Order> findByBuyer(User buyer);
}
