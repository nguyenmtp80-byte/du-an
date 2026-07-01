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

    // ==================== QR PAYMENT ====================

    /**
     * Tạo QR thanh toán cho đơn hàng
     * Chỉ áp dụng cho đơn hàng có phương thức BANK_TRANSFER_QR
     */
    public PaymentQrResponse generatePaymentQr(String orderId, User user) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new ResourceNotFoundException("Đơn hàng không tồn tại"));

        if (!order.getBuyer().getId().equals(user.getId())) {
            throw new InvalidDataException("Bạn không phải người mua của đơn hàng này");
        }

        if (order.getPaymentMethod() != PaymentMethod.BANK_TRANSFER_QR) {
            throw new InvalidDataException("Đơn hàng này không sử dụng phương thức thanh toán QR");
        }

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
     * Sandbox: Xác nhận thanh toán QR thành công
     * Chuyển PENDING → APPROVED
     */
    @Transactional
    public OrderResponse confirmQrPayment(String orderId, User user) {
        Order order = getOrderAndValidateBuyer(orderId, user);
        validatePaymentMethod(order, PaymentMethod.BANK_TRANSFER_QR);
        validateOrderStatus(order, OrderStatus.PENDING);

        order.setStatus(OrderStatus.APPROVED);
        orderRepository.save(order);

        notificationService.createNotification(
                order.getSeller(),
                "Thanh toán QR thành công",
                "Đơn hàng " + orderId + " đã được thanh toán qua QR. Vui lòng chuẩn bị hàng.",
                "order_status", orderId
        );
        notificationService.createNotification(
                order.getBuyer(),
                "Xác nhận thanh toán QR",
                "Đơn hàng " + orderId + " đã thanh toán QR thành công.",
                "order_status", orderId
        );

        return mapToOrderResponse(order);
    }

    /**
     * Sandbox: Hủy thanh toán QR
     * Chuyển PENDING → CANCELLED
     */
    @Transactional
    public OrderResponse cancelQrPayment(String orderId, User user) {
        Order order = getOrderAndValidateBuyer(orderId, user);
        validatePaymentMethod(order, PaymentMethod.BANK_TRANSFER_QR);
        validateOrderStatus(order, OrderStatus.PENDING);

        order.setStatus(OrderStatus.CANCELLED);
        orderRepository.save(order);

        notificationService.createNotification(
                order.getSeller(),
                "Thanh toán QR đã hủy",
                "Đơn hàng " + orderId + " đã bị hủy thanh toán QR.",
                "order_status", orderId
        );

        return mapToOrderResponse(order);
    }

    // ==================== CASH PAYMENT ====================

    /**
     * Buyer xác nhận đã thanh toán tiền mặt khi nhận hàng
     * Chỉ áp dụng cho đơn hàng CASH, đang ở trạng thái APPROVED
     * Chuyển APPROVED → COMPLETED
     */
    @Transactional
    public OrderResponse confirmCashPayment(String orderId, User user) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new ResourceNotFoundException("Đơn hàng không tồn tại"));

        // Cả buyer và seller đều có thể xác nhận đã nhận/thanh toán tiền mặt
        boolean isBuyer = order.getBuyer().getId().equals(user.getId());
        boolean isSeller = order.getSeller().getId().equals(user.getId());
        if (!isBuyer && !isSeller) {
            throw new InvalidDataException("Bạn không có quyền xác nhận thanh toán đơn hàng này");
        }

        validatePaymentMethod(order, PaymentMethod.CASH);
        validateOrderStatus(order, OrderStatus.APPROVED);

        order.setStatus(OrderStatus.COMPLETED);
        orderRepository.save(order);

        // Thông báo cho cả 2 bên
        notificationService.createNotification(
                order.getSeller(),
                "Đã nhận tiền mặt",
                "Đơn hàng " + orderId + " đã được thanh toán tiền mặt thành công.",
                "order_status", orderId
        );
        notificationService.createNotification(
                order.getBuyer(),
                "Thanh toán tiền mặt thành công",
                "Đơn hàng " + orderId + " đã thanh toán tiền mặt và hoàn tất.",
                "order_status", orderId
        );

        return mapToOrderResponse(order);
    }

    /**
     * Buyer hủy đơn hàng CASH khi chưa được seller xác nhận
     * Chuyển PENDING → CANCELLED
     */
    @Transactional
    public OrderResponse cancelCashOrder(String orderId, User user) {
        Order order = getOrderAndValidateBuyer(orderId, user);
        validatePaymentMethod(order, PaymentMethod.CASH);
        validateOrderStatus(order, OrderStatus.PENDING);

        order.setStatus(OrderStatus.CANCELLED);
        orderRepository.save(order);

        notificationService.createNotification(
                order.getSeller(),
                "Đơn hàng tiền mặt đã hủy",
                "Đơn hàng " + orderId + " (tiền mặt) đã bị người mua hủy.",
                "order_status", orderId
        );

        return mapToOrderResponse(order);
    }

    // ==================== GET PAYMENT INFO ====================

    /**
     * Lấy thông tin thanh toán của đơn hàng
     * Trả về phương thức, trạng thái, hướng dẫn thanh toán
     */
    public PaymentInfoResponse getPaymentInfo(String orderId, User user) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new ResourceNotFoundException("Đơn hàng không tồn tại"));

        boolean isBuyer = order.getBuyer().getId().equals(user.getId());
        boolean isSeller = order.getSeller().getId().equals(user.getId());
        if (!isBuyer && !isSeller) {
            throw new InvalidDataException("Bạn không có quyền xem thông tin thanh toán");
        }

        String instructions;
        switch (order.getPaymentMethod()) {
            case CASH:
                instructions = "Khi gặp mặt nhận hàng, vui lòng thanh toán tiền mặt cho người bán. "
                        + "Sau khi nhận hàng và thanh toán, xác nhận tại mục thanh toán.";
                break;
            case BANK_TRANSFER:
                instructions = "Vui lòng chuyển khoản đến số tài khoản bên dưới. "
                        + "Sau khi chuyển khoản, gửi ảnh biên lai cho người bán qua chat.";
                break;
            case BANK_TRANSFER_QR:
                instructions = "Quét mã QR bên dưới bằng app ngân hàng để thanh toán. "
                        + "Sau khi thanh toán, nhấn 'Xác nhận thanh toán' để hoàn tất.";
                break;
            default:
                instructions = "";
        }

        return new PaymentInfoResponse(
                order.getId(),
                order.getPaymentMethod().toString(),
                order.getStatus().toString(),
                order.getTotalAmount(),
                instructions
        );
    }

    // ==================== VALIDATION HELPERS ====================

    private Order getOrderAndValidateBuyer(String orderId, User user) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new ResourceNotFoundException("Đơn hàng không tồn tại"));
        if (!order.getBuyer().getId().equals(user.getId())) {
            throw new InvalidDataException("Bạn không phải người mua của đơn hàng này");
        }
        return order;
    }

    private void validatePaymentMethod(Order order, PaymentMethod expected) {
        if (order.getPaymentMethod() != expected) {
            throw new InvalidDataException(
                    "Phương thức thanh toán không phù hợp. Cần: " + expected
                    + ", hiện tại: " + order.getPaymentMethod()
            );
        }
    }

    private void validateOrderStatus(Order order, OrderStatus expected) {
        if (order.getStatus() != expected) {
            throw new InvalidDataException(
                    "Trạng thái đơn hàng không hợp lệ. Cần: " + expected
                    + ", hiện tại: " + order.getStatus()
            );
        }
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
                null,
                order.getCreatedAt()
        );
    }

    // ==================== INNER DTO ====================

    public static class PaymentInfoResponse {
        private String orderId;
        private String paymentMethod;
        private String status;
        private Integer amount;
        private String instructions;

        public PaymentInfoResponse() {}

        public PaymentInfoResponse(String orderId, String paymentMethod, String status,
                                    Integer amount, String instructions) {
            this.orderId = orderId;
            this.paymentMethod = paymentMethod;
            this.status = status;
            this.amount = amount;
            this.instructions = instructions;
        }

        public String getOrderId() { return orderId; }
        public void setOrderId(String orderId) { this.orderId = orderId; }

        public String getPaymentMethod() { return paymentMethod; }
        public void setPaymentMethod(String paymentMethod) { this.paymentMethod = paymentMethod; }

        public String getStatus() { return status; }
        public void setStatus(String status) { this.status = status; }

        public Integer getAmount() { return amount; }
        public void setAmount(Integer amount) { this.amount = amount; }

        public String getInstructions() { return instructions; }
        public void setInstructions(String instructions) { this.instructions = instructions; }
    }
}