package market.campus.com.service;

import market.campus.com.dto.request.CreateOrderRequest;
import market.campus.com.dto.response.OrderItemResponse;
import market.campus.com.dto.response.OrderResponse;
import market.campus.com.exception.InvalidDataException;
import market.campus.com.exception.ResourceNotFoundException;
import market.campus.com.model.*;
import market.campus.com.model.enums.OrderStatus;
import market.campus.com.model.enums.PaymentMethod;
import market.campus.com.model.enums.ProductStatus;
import market.campus.com.repository.CartRepository;
import market.campus.com.repository.OrderItemRepository;
import market.campus.com.repository.OrderRepository;
import market.campus.com.repository.ProductRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class OrderService {

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private OrderItemRepository orderItemRepository;

    @Autowired
    private CartRepository cartRepository;

    @Autowired
    private ProductRepository productRepository;

    @Autowired
    private CartService cartService;

    @Autowired
    private NotificationService notificationService;

    @Transactional
    public OrderResponse createOrder(User buyer, CreateOrderRequest request) {
        // Lấy giỏ hàng của user (flat cart: list Cart rows)
        List<Cart> cartItems = cartRepository.findByUser(buyer);

        // Kiểm tra giỏ hàng có rỗng không
        if (cartItems.isEmpty()) {
            throw new InvalidDataException("Giỏ hàng trống, không thể tạo đơn hàng");
        }

        // Kiểm tra tất cả sản phẩm còn tồn tại và đủ tồn kho
        for (Cart item : cartItems) {
            Product product = item.getProduct();
            if (product.getStatus() != ProductStatus.available) {
                throw new InvalidDataException("Sản phẩm " + product.getTitle() + " không còn sẵn");
            }

            int stock = product.getQuantity() != null ? product.getQuantity() : 0;
            if (item.getQuantity() > stock) {
                throw new InvalidDataException(
                        "Số lượng trong giỏ vượt quá tồn kho sản phẩm "
                                + product.getTitle() + " (còn " + stock + ")"
                );
            }
        }

        // Validate payment method
        PaymentMethod paymentMethod = validatePaymentMethod(request.getPaymentMethod());

        // Validate delivery info
        validateDeliveryInfo(request.getDeliveryInfo());

        // Tính tổng tiền
        int totalAmount = cartItems.stream()
                .mapToInt(item -> item.getProduct().getPrice().intValue() * item.getQuantity())
                .sum();

        // Lấy seller từ sản phẩm đầu tiên (giả định 1 đơn hàng chỉ mua từ 1 seller)
        User seller = cartItems.get(0).getProduct().getSeller();

        // Tạo Order
        String orderId = UUID.randomUUID().toString();
        Order order = new Order(orderId, buyer, seller, totalAmount,
                OrderStatus.PENDING, paymentMethod, request.getDeliveryInfo().getNotes());
        order = orderRepository.save(order);

        // Tạo OrderItems từ CartItems
        for (Cart cartItem : cartItems) {
            int itemPrice = cartItem.getProduct().getPrice().intValue();

            OrderItem orderItem = new OrderItem(
                    UUID.randomUUID().toString(),
                    order,
                    cartItem.getProduct(),
                    cartItem.getQuantity(),
                    itemPrice
            );
            orderItemRepository.save(orderItem);

            // Trừ tồn kho sau khi đặt hàng thành công
            Product product = cartItem.getProduct();
            int remainingQuantity = (product.getQuantity() != null ? product.getQuantity() : 0)
                    - cartItem.getQuantity();
            product.setQuantity(Math.max(remainingQuantity, 0));
            if (product.getQuantity() <= 0) {
                product.setStatus(ProductStatus.sold);
            }
            productRepository.save(product);
        }

        // Xóa giỏ hàng
        cartService.clearCart(buyer);

        // Thông báo cho seller có đơn hàng mới cần xác nhận
        notificationService.createNotification(
                seller,
                "Đơn hàng mới",
                "Bạn có đơn hàng mới " + orderId + " cần xác nhận.",
                "order_status",
                orderId
        );

        return getOrderResponse(order);
    }

    // Validate payment method
    private PaymentMethod validatePaymentMethod(String paymentMethod) {
        try {
            return PaymentMethod.valueOf(paymentMethod.toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new InvalidDataException("Phương thức thanh toán không hợp lệ");
        }
    }

    // Validate delivery info
    private void validateDeliveryInfo(Object deliveryInfo) {
        if (deliveryInfo == null) {
            throw new InvalidDataException("Thông tin giao hàng không được trống");
        }
    }

    // Lấy chi tiết đơn hàng
    public OrderResponse getOrderDetail(String orderId, User user) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new ResourceNotFoundException("Đơn hàng không tồn tại"));

        boolean isBuyer = order.getBuyer().getId().equals(user.getId());
        boolean isSeller = order.getSeller().getId().equals(user.getId());

        if (!isBuyer && !isSeller) {
            throw new InvalidDataException("Không có quyền xem đơn hàng này");
        }

        return getOrderResponse(order);
    }

    // Lấy danh sách đơn hàng của user
    public List<OrderResponse> getUserOrders(User user) {
        return orderRepository.findByBuyer(user).stream()
                .map(this::getOrderResponse)
                .collect(Collectors.toList());
    }

    /**
     * Seller accepts/approves an order - updates status to APPROVED and sends notification to buyer.
     * Entire operation is wrapped in @Transactional so if notification creation fails, status update is rolled back.
     */
    @Transactional
    public OrderResponse acceptOrder(String orderId, User seller) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new ResourceNotFoundException("Đơn hàng không tồn tại: " + orderId));

        // Validate that the requester is the seller of this order
        if (!order.getSeller().getId().equals(seller.getId())) {
            throw new InvalidDataException("Bạn không phải người bán của đơn hàng này");
        }

        // Validate current status allows acceptance
        if (order.getStatus() != OrderStatus.PENDING) {
            throw new InvalidDataException(
                    "Đơn hàng không ở trạng thái chờ xác nhận (trạng thái hiện tại: " + order.getStatus() + ")"
            );
        }

        // Update order status
        order.setStatus(OrderStatus.APPROVED);
        orderRepository.save(order);

        // Create notification for buyer
        notificationService.createNotification(
                order.getBuyer(),
                "Xác nhận đơn hàng",
                "Đơn hàng " + orderId + " của bạn đã được người bán xác nhận.",
                "order_status",
                orderId
        );

        return getOrderResponse(order);
    }

    /**
     * Seller completes an order - updates status to COMPLETED and sends notification to buyer.
     * Entire operation is wrapped in @Transactional for rollback safety.
     */
    @Transactional
    public OrderResponse completeOrder(String orderId, User seller) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new ResourceNotFoundException("Đơn hàng không tồn tại: " + orderId));

        // Validate that the requester is the seller of this order
        if (!order.getSeller().getId().equals(seller.getId())) {
            throw new InvalidDataException("Bạn không phải người bán của đơn hàng này");
        }

        // Validate current status allows completion
        if (order.getStatus() != OrderStatus.APPROVED) {
            throw new InvalidDataException(
                    "Đơn hàng phải được xác nhận trước khi hoàn tất (trạng thái hiện tại: " + order.getStatus() + ")"
            );
        }

        // Update order status
        order.setStatus(OrderStatus.COMPLETED);
        orderRepository.save(order);

        // Create notification for buyer
        notificationService.createNotification(
                order.getBuyer(),
                "Đơn hàng hoàn thành",
                "Đơn hàng " + orderId + " của bạn đã hoàn tất. Cảm ơn bạn!",
                "order_status",
                orderId
        );

        return getOrderResponse(order);
    }

    // Lấy danh sách đơn hàng của seller
    public List<OrderResponse> getSellerOrders(User seller) {
        return orderRepository.findBySeller(seller).stream()
                .map(this::getOrderResponse)
                .collect(Collectors.toList());
    }

    // Convert Order to OrderResponse
    private OrderResponse getOrderResponse(Order order) {
        var items = orderItemRepository.findByOrder(order).stream()
                .map(item -> new OrderItemResponse(
                        item.getId(),
                        item.getProduct().getId(),
                        item.getProduct().getTitle(),
                        item.getQuantity(),
                        item.getPrice(),
                        item.getQuantity() * item.getPrice()
                ))
                .collect(Collectors.toList());

        return new OrderResponse(
                order.getId(),
                order.getBuyer().getId(),
                order.getSeller().getId(),
                order.getTotalAmount(),
                order.getStatus().toString(),
                order.getPaymentMethod().toString(),
                order.getShippingNote(),
                items,
                order.getCreatedAt()
        );
    }
}