package market.campus.com.repository;

import market.campus.com.model.Order;
import market.campus.com.model.OrderItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface OrderItemRepository extends JpaRepository<OrderItem, String> {
    List<OrderItem> findByOrder(Order order);

    List<OrderItem> findByOrder_Id(String orderId);
}
