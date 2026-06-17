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
    private CartService cartService;

    @Transactional
    public OrderResponse createOrder(User buyer, CreateOrderRequest request) {
        // Lấy giỏ hàng của user (flat cart: list Cart rows)
        List<Cart> cartItems = cartRepository.findByUser(buyer);

        // Kiểm tra giỏ hàng có rỗng không
        if (cartItems.isEmpty()) {
            throw new InvalidDataException("Giỏ hàng trống, không thể tạo đơn hàng");
        }

        // Kiểm tra tất cả sản phẩm còn tồn tại và có trạng thái AVAILABLE
        for (Cart item : cartItems) {
            Product product = item.getProduct();
            if (product.getStatus() != ProductStatus.available) {
                throw new InvalidDataException("Sản phẩm " + product.getTitle() + " không còn sẵn");
            }
        }

        // Validate payment method
        PaymentMethod paymentMethod = validatePaymentMethod(request.getPaymentMethod());

        // Validate delivery info
        validateDeliveryInfo(request.getDeliveryInfo());

        // Tính tổng tiền
        BigDecimal totalAmount = cartItems.stream()
                .map(item -> item.getProduct().getPrice().multiply(BigDecimal.valueOf(item.getQuantity())))
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        // Lấy seller từ sản phẩm đầu tiên (giả định 1 đơn hàng chỉ mua từ 1 seller)
        User seller = cartItems.get(0).getProduct().getSeller();

        // Tạo Order
        String orderId = UUID.randomUUID().toString();
        Order order = new Order(orderId, buyer, seller, totalAmount,
                OrderStatus.PENDING, paymentMethod, request.getDeliveryInfo().getNotes());
        order = orderRepository.save(order);

        // Tạo OrderItems từ CartItems
        for (Cart cartItem : cartItems) {
            BigDecimal unitPrice = cartItem.getProduct().getPrice();
            BigDecimal subtotal = unitPrice.multiply(BigDecimal.valueOf(cartItem.getQuantity()));

            OrderItem orderItem = new OrderItem(
                    UUID.randomUUID().toString(),
                    order,
                    cartItem.getProduct(),
                    cartItem.getQuantity(),
                    unitPrice,      // price
                    unitPrice,      // unit_price
                    subtotal
            );
            orderItemRepository.save(orderItem);
        }

        // Xóa giỏ hàng
        cartService.clearCart(buyer);

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

        // Kiểm tra xem đơn hàng có thuộc user này không
        if (!order.getBuyer().getId().equals(user.getId())) {
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

    // Convert Order to OrderResponse
    private OrderResponse getOrderResponse(Order order) {
        var items = orderItemRepository.findByOrder(order).stream()
                .map(item -> new OrderItemResponse(
                        item.getId(),
                        item.getProduct().getId(),
                        item.getProduct().getTitle(),
                        item.getQuantity(),
                        item.getUnitPrice(),
                        item.getSubtotal()
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