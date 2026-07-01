package market.campus.com.service;

import market.campus.com.dto.response.OrderResponse;
import market.campus.com.dto.response.PaymentQrResponse;
import market.campus.com.exception.InvalidDataException;
import market.campus.com.exception.ResourceNotFoundException;
import market.campus.com.model.Order;
import market.campus.com.model.User;
import market.campus.com.model.enums.OrderStatus;
import market.campus.com.model.enums.PaymentMethod;
import market.campus.com.repository.OrderRepository;
import market.campus.com.repository.OrderItemRepository;
import market.campus.com.repository.ProductRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class PaymentService {

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private QrCodeService qrCodeService;

    @Autowired
    private NotificationService notificationService;

    /**
     * Tạo QR thanh toán cho đơn hàng
     * Chỉ áp dụng cho đơn hàng có phương thức BANK_TRANSFER_QR
     */
    public PaymentQrResponse generatePaymentQr(String orderId, User user) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new ResourceNotFoundException("Đơn hàng không tồn tại"));

        // Validate user is the buyer
        if (!order.getBuyer().getId().equals(user.getId())) {
            throw new InvalidDataException("Bạn không phải người mua của đơn hàng này");
        }

        // Validate payment method
        if (order.getPaymentMethod() != PaymentMethod.BANK_TRANSFER_QR) {
            throw new InvalidDataException("Đơn hàng này không sử dụng phương thức thanh toán QR");
        }

        // Generate QR content
        int amount = order.getTotalAmount() != null ? order.getTotalAmount() : 0;
        String qrContent = qrCodeService.generateVietQrContent(orderId, amount);
        String qrImageBase64 = qrCodeService.generateQrCodeBase64(qrContent, 400, 400);

        String transferContent = "STUDENT-MARKET-" + orderId.substring(0, Math.min(8, orderId.length()));

        return new PaymentQrResponse(
                order.getId(),
                amount,
                qrCodeService.getBankCode(),
                qrCodeService.getBankAccountNumber(),
                qrCodeService.getBankAccountName(),
                transferContent,
                qrImageBase64,
                order.getStatus().toString()
        );
    }

    /**
     * Sandbox: Xác nhận thanh toán thành công
     * Trong môi trường thật, webhook từ ngân hàng sẽ gọi API này
     * Sandbox: buyer tự confirm hoặc auto-confirm
     */
    @Transactional
    public OrderResponse confirmPayment(String orderId, User user) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new ResourceNotFoundException("Đơn hàng không tồn tại"));

        // Validate user is the buyer
        if (!order.getBuyer().getId().equals(user.getId())) {
            throw new InvalidDataException("Bạn không phải người mua của đơn hàng này");
        }

        // Validate payment method
        if (order.getPaymentMethod() != PaymentMethod.BANK_TRANSFER_QR) {
            throw new InvalidDataException("Đơn hàng này không sử dụng phương thức thanh toán QR");
        }

        // Validate order status - must be PENDING
        if (order.getStatus() != OrderStatus.PENDING) {
            throw new InvalidDataException(
                    "Đơn hàng không ở trạng thái chờ thanh toán (hiện tại: " + order.getStatus() + ")"
            );
        }

        // Mark order as payment confirmed -> change to APPROVED
        // In real system, this would happen after bank webhook verification
        order.setStatus(OrderStatus.APPROVED);
        orderRepository.save(order);

        // Thông báo cho seller
        notificationService.createNotification(
                order.getSeller(),
                "Thanh toán thành công",
                "Đơn hàng " + orderId + " đã được thanh toán qua QR. Vui lòng chuẩn bị hàng.",
                "order_status",
                orderId
        );

        // Thông báo cho buyer
        notificationService.createNotification(
                order.getBuyer(),
                "Xác nhận thanh toán",
                "Đơn hàng " + orderId + " đã thanh toán thành công.",
                "order_status",
                orderId
        );

        // Build response
        return mapToOrderResponse(order);
    }

    /**
     * Sandbox: Hủy thanh toán
     */
    @Transactional
    public OrderResponse cancelPayment(String orderId, User user) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new ResourceNotFoundException("Đơn hàng không tồn tại"));

        if (!order.getBuyer().getId().equals(user.getId())) {
            throw new InvalidDataException("Bạn không phải người mua của đơn hàng này");
        }

        if (order.getPaymentMethod() != PaymentMethod.BANK_TRANSFER_QR) {
            throw new InvalidDataException("Đơn hàng này không sử dụng phương thức thanh toán QR");
        }

        if (order.getStatus() != OrderStatus.PENDING) {
            throw new InvalidDataException("Đơn hàng không thể hủy thanh toán ở trạng thái hiện tại");
        }

        order.setStatus(OrderStatus.CANCELLED);
        orderRepository.save(order);

        notificationService.createNotification(
                order.getSeller(),
                "Thanh toán đã hủy",
                "Đơn hàng " + orderId + " đã bị hủy thanh toán.",
                "order_status",
                orderId
        );

        return mapToOrderResponse(order);
    }

    private OrderResponse mapToOrderResponse(Order order) {
        return new OrderResponse(
                order.getId(),
                order.getBuyer().getId(),
                order.getSeller().getId(),
                order.getTotalAmount(),
                order.getStatus().toString(),
                order.getPaymentMethod().toString(),
                order.getShippingNote(),
                null, // items not needed for payment response
                order.getCreatedAt()
        );
    }
}