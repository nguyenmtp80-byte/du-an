package market.campus.com.service;

import market.campus.com.dto.response.OrderResponse;
import market.campus.com.dto.response.PaymentQrResponse;
import market.campus.com.dto.response.PaymentTransactionResponse;
import market.campus.com.exception.InvalidDataException;
import market.campus.com.exception.ResourceNotFoundException;
import market.campus.com.model.Order;
import market.campus.com.model.User;
import market.campus.com.model.enums.OrderStatus;
import market.campus.com.model.enums.PaymentMethod;
import market.campus.com.repository.OrderRepository;
import market.campus.com.repository.ProductRepository;
import market.campus.com.repository.OrderItemRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Collectors;

@Service
public class PaymentService {

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private QrCodeService qrCodeService;

    @Autowired
    private NotificationService notificationService;

    @Autowired
    private OrderService orderService;

    @Autowired
    private ProductRepository productRepository;

    @Autowired
    private OrderItemRepository orderItemRepository;

    @Autowired
    private VnpayService vnpayService;

    // === LƯU TRỮ GIAO DỊCH (In-memory, khi deploy thật thì dùng DB) ===
    // key = referenceCode (VD: MARKET-abc12345), value = TransactionRecord
    private final Map<String, TransactionRecord> transactionStore = new ConcurrentHashMap<>();

    private static class TransactionRecord {
        String transactionId;
        String orderId;
        String referenceCode;
        int amount;
        String bankCode;
        String bankAccountNumber;
        String bankAccountName;
        String transferContent;
        String status; // PENDING, SUCCESS, FAILED
        String note;
        LocalDateTime createdAt;
        LocalDateTime confirmedAt;

        TransactionRecord(String transactionId, String orderId, String referenceCode,
                          int amount, String bankCode, String bankAccountNumber,
                          String bankAccountName, String transferContent) {
            this.transactionId = transactionId;
            this.orderId = orderId;
            this.referenceCode = referenceCode;
            this.amount = amount;
            this.bankCode = bankCode;
            this.bankAccountNumber = bankAccountNumber;
            this.bankAccountName = bankAccountName;
            this.transferContent = transferContent;
            this.status = "PENDING";
            this.createdAt = LocalDateTime.now();
        }
    }

    // ==================== BƯỚC 1: SINH QR ====================

    /**
     * Tạo QR thanh toán cho đơn hàng.
     * Hệ thống tạo QR chứa thông tin chuyển khoản + mã tham chiếu để đối soát.
     * Đồng thời tạo bản ghi giao dịch để chờ xác nhận.
     */
    @Transactional
    public PaymentQrResponse generatePaymentQr(String orderId, User user, String ipAddress) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new ResourceNotFoundException("Đơn hàng không tồn tại"));

        if (!order.getBuyer().getId().equals(user.getId())) {
            throw new InvalidDataException("Bạn không phải người mua của đơn hàng này");
        }

        if (order.getPaymentMethod() != PaymentMethod.BANK_TRANSFER_QR) {
            throw new InvalidDataException("Đơn hàng này không sử dụng phương thức thanh toán QR");
        }

        if (order.getStatus() != OrderStatus.PENDING) {
            throw new InvalidDataException("Đơn hàng không ở trạng thái chờ thanh toán");
        }

        int amount = order.getTotalAmount() != null ? order.getTotalAmount() : 0;
        String refCode = qrCodeService.getReferenceCode(orderId);
        String qrContent = qrCodeService.generateVietQrContent(orderId, amount);
        String qrImageBase64 = qrCodeService.generateQrCodeBase64(qrContent, 400, 400);
        String transferContent = "TT " + refCode;
        
        String paymentUrl = vnpayService.createPaymentUrl(orderId, amount, ipAddress);

        // Tạo bản ghi giao dịch
        String transactionId = UUID.randomUUID().toString();
        transactionStore.put(refCode, new TransactionRecord(
                transactionId, orderId, refCode, amount,
                qrCodeService.getBankCode(), qrCodeService.getBankAccountNumber(),
                qrCodeService.getBankAccountName(), transferContent
        ));

        return new PaymentQrResponse(
                order.getId(), amount,
                qrCodeService.getBankCode(), qrCodeService.getBankAccountNumber(),
                qrCodeService.getBankAccountName(), transferContent, refCode,
                qrImageBase64, paymentUrl, order.getStatus().toString()
        );
    }

    // ==================== BƯỚC 2: WEBHOOK NGÂN HÀNG ====================

    /**
     * *** BƯỚC QUAN TRỌNG NHẤT ***
     * 
     * Webhook mô phỏng ngân hàng báo có giao dịch đến.
     * 
     * TRONG THỰC TẾ:
     * - Ngân hàng (Vietcombank, MB Bank, etc.) gửi POST request về URL này
     *   khi có người chuyển tiền vào tài khoản của hệ thống
     * - Webhook chứa: referenceCode, amount, transactionId từ ngân hàng
     * - Hệ thống đối soát: kiểm tra referenceCode có khớp không, amount có đúng không
     * - Nếu hợp lệ -> cập nhật trạng thái giao dịch + đơn hàng thành PAID
     *
     * SANDBOX:
     * - Frontend gọi API này khi user nhấn "Tôi đã chuyển khoản"
     * - Hoặc tester gọi trực tiếp từ Postman
     */
    @Transactional
    public PaymentTransactionResponse processBankWebhook(String referenceCode, int amount, String bankTransactionId) {
        // 1. Tìm giao dịch theo mã tham chiếu
        TransactionRecord record = transactionStore.get(referenceCode);
        if (record == null) {
            throw new InvalidDataException("Không tìm thấy giao dịch với mã tham chiếu: " + referenceCode);
        }

        // 2. Kiểm tra giao dịch chưa được xử lý
        if (!"PENDING".equals(record.status)) {
            throw new InvalidDataException("Giao dịch này đã được xử lý (trạng thái: " + record.status + ")");
        }

        // 3. Kiểm tra số tiền khớp
        if (record.amount != amount) {
            // Có thể chấp nhận sai số nhỏ, nhưng ở đây yêu cầu khớp chính xác
            record.status = "FAILED";
            record.note = "Số tiền không khớp. Dự kiến: " + record.amount + ", Nhận được: " + amount;
            record.confirmedAt = LocalDateTime.now();
            return mapToTransactionResponse(record);
        }

        // 4. Cập nhật giao dịch thành SUCCESS
        record.status = "SUCCESS";
        record.note = "Giao dịch thành công. Mã giao dịch NH: " + (bankTransactionId != null ? bankTransactionId : "N/A");
        record.confirmedAt = LocalDateTime.now();

        // 5. Cập nhật đơn hàng: PENDING -> PAID (đã nhận được tiền)
        Order order = orderRepository.findById(record.orderId)
                .orElseThrow(() -> new ResourceNotFoundException("Đơn hàng không tồn tại"));

        if (order.getStatus() == OrderStatus.PENDING) {
            order.setStatus(OrderStatus.PAID);
            orderRepository.save(order);

            // 6. Gửi thông báo
            notificationService.createNotification(
                    order.getSeller(),
                    "Đã nhận được thanh toán",
                    "Đơn hàng " + record.orderId + " đã được thanh toán qua VNPay. Số tiền: " + amount + " VND.",
                    "order_status", order.getId()
            );
            notificationService.createNotification(
                    order.getBuyer(),
                    "Thanh toán VNPay thành công",
                    "Hệ thống đã nhận được thanh toán " + amount + " VND cho đơn hàng " + record.orderId + ".",
                    "order_status", order.getId()
            );
        }

        return mapToTransactionResponse(record);
    }
    
    @Transactional
    public String processVnpayIpn(Map<String, String> params) {
        if (vnpayService.verifyIpnSignature(params)) {
            if ("00".equals(params.get("vnp_ResponseCode"))) {
                String vnp_TxnRef = params.get("vnp_TxnRef");
                String vnp_Amount = params.get("vnp_Amount");
                String vnp_TransactionNo = params.get("vnp_TransactionNo");
                
                int amount = Integer.parseInt(vnp_Amount) / 100;
                
                try {
                    processBankWebhook(vnp_TxnRef, amount, vnp_TransactionNo);
                    return "{\"RspCode\":\"00\",\"Message\":\"Confirm Success\"}";
                } catch (Exception e) {
                    return "{\"RspCode\":\"99\",\"Message\":\"" + e.getMessage() + "\"}";
                }
            } else {
                return "{\"RspCode\":\"24\",\"Message\":\"Transaction Failed\"}";
            }
        } else {
            return "{\"RspCode\":\"97\",\"Message\":\"Invalid Signature\"}";
        }
    }

    // ==================== BƯỚC 3: KIỂM TRA GIAO DỊCH ====================

    /**
     * Kiểm tra trạng thái giao dịch của đơn hàng.
     * Frontend gọi API này để kiểm tra xem hệ thống đã nhận được tiền chưa.
     */
    public PaymentTransactionResponse checkTransaction(String orderId, User user) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new ResourceNotFoundException("Đơn hàng không tồn tại"));

        boolean isBuyer = order.getBuyer().getId().equals(user.getId());
        boolean isSeller = order.getSeller().getId().equals(user.getId());
        if (!isBuyer && !isSeller) {
            throw new InvalidDataException("Bạn không có quyền xem giao dịch này");
        }

        String refCode = qrCodeService.getReferenceCode(orderId);
        TransactionRecord record = transactionStore.get(refCode);
        if (record == null) {
            // Chưa có giao dịch (chưa sinh QR)
            return new PaymentTransactionResponse(
                    null, orderId, refCode,
                    order.getTotalAmount() != null ? order.getTotalAmount() : 0,
                    qrCodeService.getBankCode(), qrCodeService.getBankAccountNumber(),
                    qrCodeService.getBankAccountName(),
                    "TT " + refCode, "NO_TRANSACTION",
                    "Chưa có giao dịch thanh toán", null, null
            );
        }

        return mapToTransactionResponse(record);
    }

    // ==================== BƯỚC 4: XÁC NHẬN GIAO DỊCH + HOÀN TẤT ====================

    /**
     * Sau khi hệ thống đã nhận được tiền (PAID), seller xác nhận đã nhận được tiền
     * và chuyển đơn hàng sang APPROVED để chuẩn bị giao hàng.
     * PAID -> APPROVED
     */
    @Transactional
    public OrderResponse confirmSellerReceived(String orderId, User seller) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new ResourceNotFoundException("Đơn hàng không tồn tại"));

        if (!order.getSeller().getId().equals(seller.getId())) {
            throw new InvalidDataException("Bạn không phải người bán của đơn hàng này");
        }

        if (order.getPaymentMethod() != PaymentMethod.BANK_TRANSFER_QR) {
            throw new InvalidDataException("Đơn hàng này không sử dụng QR");
        }

        if (order.getStatus() != OrderStatus.PAID) {
            throw new InvalidDataException("Đơn hàng chưa được thanh toán (trạng thái: " + order.getStatus() + ")");
        }

        order.setStatus(OrderStatus.APPROVED);
        orderRepository.save(order);

        notificationService.createNotification(
                order.getBuyer(),
                "Đơn hàng đang được chuẩn bị",
                "Người bán đã xác nhận nhận được tiền và đang chuẩn bị hàng cho đơn " + orderId + ".",
                "order_status", orderId
        );

        return mapToOrderResponse(order);
    }

    // ==================== CÁC API HỖ TRỢ ====================

    /**
     * Lấy tất cả giao dịch QR của user (để kiểm tra lịch sử)
     */
    public List<PaymentTransactionResponse> getUserTransactions(User user) {
        List<Order> userOrders = orderRepository.findByBuyer(user);
        return userOrders.stream()
                .map(order -> {
                    String refCode = qrCodeService.getReferenceCode(order.getId());
                    TransactionRecord record = transactionStore.get(refCode);
                    if (record != null) {
                        return mapToTransactionResponse(record);
                    }
                    return null;
                })
                .filter(Objects::nonNull)
                .collect(Collectors.toList());
    }

    /**
     * Lấy thông tin thanh toán kèm hướng dẫn
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
                instructions = "Khi gặp mặt nhận hàng, thanh toán tiền mặt cho người bán.";
                break;
            case BANK_TRANSFER:
                instructions = "Vui lòng chuyển khoản và gửi ảnh biên lai cho người bán qua chat.";
                break;
            case BANK_TRANSFER_QR:
                instructions = getQrPaymentInstructions(order);
                break;
            default:
                instructions = "";
        }

        return new PaymentInfoResponse(
                order.getId(), order.getPaymentMethod().toString(),
                order.getStatus().toString(), order.getTotalAmount(), instructions
        );
    }

    private String getQrPaymentInstructions(Order order) {
        switch (order.getStatus()) {
            case PENDING:
                return "Bước 1: Tạo mã QR thanh toán.\n"
                     + "Bước 2: Dùng app ngân hàng quét mã QR.\n"
                     + "Bước 3: Kiểm tra số tiền và nội dung chuyển khoản.\n"
                     + "Bước 4: Xác nhận chuyển khoản.\n"
                     + "Bước 5: Hệ thống tự động kiểm tra và xác nhận.";
            case PAID:
                return "✅ Hệ thống đã nhận được tiền. Đợi người bán xác nhận và chuẩn bị hàng.";
            case APPROVED:
                return "📦 Đơn hàng đang được người bán chuẩn bị. Đợi nhận hàng.";
            case COMPLETED:
                return "✅ Đơn hàng hoàn tất. Cảm ơn bạn!";
            case CANCELLED:
                return "❌ Đơn hàng đã bị hủy.";
            default:
                return "";
        }
    }

    // ==================== CASH & CANCEL (GIỮ NGUYÊN) ====================

    @Transactional
    public OrderResponse confirmCashPayment(String orderId, User user) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new ResourceNotFoundException("Đơn hàng không tồn tại"));

        boolean isBuyer = order.getBuyer().getId().equals(user.getId());
        boolean isSeller = order.getSeller().getId().equals(user.getId());
        if (!isBuyer && !isSeller) {
            throw new InvalidDataException("Bạn không có quyền xác nhận thanh toán đơn hàng này");
        }

        validatePaymentMethod(order, PaymentMethod.CASH);
        validateOrderStatus(order, OrderStatus.APPROVED);

        order.setStatus(OrderStatus.COMPLETED);
        orderRepository.save(order);

        notificationService.createNotification(order.getSeller(),
                "Đã nhận tiền mặt", "Đơn hàng " + orderId + " đã thanh toán tiền mặt.",
                "order_status", orderId);
        notificationService.createNotification(order.getBuyer(),
                "Thanh toán tiền mặt thành công", "Đơn hàng " + orderId + " hoàn tất.",
                "order_status", orderId);

        return mapToOrderResponse(order);
    }

    @Transactional
    public OrderResponse cancelQrPayment(String orderId, User user) {
        Order order = getOrderAndValidateBuyer(orderId, user);
        validatePaymentMethod(order, PaymentMethod.BANK_TRANSFER_QR);
        validateOrderStatus(order, OrderStatus.PENDING);

        orderService.restoreProductStockForOrder(orderId);
        order.setStatus(OrderStatus.CANCELLED);
        orderRepository.save(order);

        // Xóa giao dịch nếu có
        String refCode = qrCodeService.getReferenceCode(orderId);
        transactionStore.remove(refCode);

        notificationService.createNotification(order.getSeller(),
                "Thanh toán QR đã hủy", "Đơn hàng " + orderId + " đã bị hủy.",
                "order_status", orderId);

        return mapToOrderResponse(order);
    }

    @Transactional
    public OrderResponse cancelCashOrder(String orderId, User user) {
        Order order = getOrderAndValidateBuyer(orderId, user);
        validatePaymentMethod(order, PaymentMethod.CASH);
        validateOrderStatus(order, OrderStatus.PENDING);

        orderService.restoreProductStockForOrder(orderId);
        order.setStatus(OrderStatus.CANCELLED);
        orderRepository.save(order);

        notificationService.createNotification(order.getSeller(),
                "Đơn hàng tiền mặt đã hủy", "Đơn hàng " + orderId + " đã bị hủy.",
                "order_status", orderId);

        return mapToOrderResponse(order);
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
            throw new InvalidDataException("Phương thức thanh toán không phù hợp. Cần: " + expected
                    + ", hiện tại: " + order.getPaymentMethod());
        }
    }

    private void validateOrderStatus(Order order, OrderStatus expected) {
        if (order.getStatus() != expected) {
            throw new InvalidDataException("Trạng thái đơn hàng không hợp lệ. Cần: " + expected
                    + ", hiện tại: " + order.getStatus());
        }
    }

    private OrderResponse mapToOrderResponse(Order order) {
        return new OrderResponse(
                order.getId(), order.getBuyer().getId(), order.getSeller().getId(),
                order.getTotalAmount(), order.getStatus().toString(),
                order.getPaymentMethod().toString(), order.getShippingNote(),
                null, order.getCreatedAt()
        );
    }

    private PaymentTransactionResponse mapToTransactionResponse(TransactionRecord record) {
        return new PaymentTransactionResponse(
                record.transactionId, record.orderId, record.referenceCode,
                record.amount, record.bankCode, record.bankAccountNumber,
                record.bankAccountName, record.transferContent, record.status,
                record.note, record.createdAt, record.confirmedAt
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
            this.orderId = orderId; this.paymentMethod = paymentMethod;
            this.status = status; this.amount = amount; this.instructions = instructions;
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