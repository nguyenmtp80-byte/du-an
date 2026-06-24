package market.campus.com.repository;

import market.campus.com.model.ChatRoom;
import market.campus.com.model.Product;
import market.campus.com.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ChatRoomRepository extends JpaRepository<ChatRoom, String> {
    Optional<ChatRoom> findByProductAndBuyer(Product product, User buyer);
    List<ChatRoom> findByBuyerOrSellerOrderByUpdatedAtDesc(User buyer, User seller);

    @Query("SELECT cr FROM ChatRoom cr WHERE cr.buyer.id = :userId OR cr.seller.id = :userId ORDER BY cr.updatedAt DESC")
    List<ChatRoom> findByUserIdOrderByUpdatedAtDesc(@Param("userId") String userId);
}