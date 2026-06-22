package market.campus.com.service;

import market.campus.com.dto.request.AddToCartRequest;
import market.campus.com.dto.request.UpdateCartItemRequest;
import market.campus.com.dto.response.CartItemResponse;
import market.campus.com.dto.response.CartResponse;
import market.campus.com.exception.InvalidDataException;
import market.campus.com.exception.ResourceNotFoundException;
import market.campus.com.model.*;
import market.campus.com.model.enums.ProductStatus;
import market.campus.com.repository.CartRepository;
import market.campus.com.repository.ProductRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class CartService {

    @Autowired
    private CartRepository cartRepository;

    @Autowired
    private ProductRepository productRepository;

    // Thêm sản phẩm vào giỏ hàng
    @Transactional
    public CartResponse addToCart(User user, AddToCartRequest request) {
        validateQuantity(request.getQuantity());

        Product product = productRepository.findById(request.getProductId())
                .orElseThrow(() -> new ResourceNotFoundException("Sản phẩm không tồn tại"));

        validateProductAvailability(product);

        // Kiểm tra sản phẩm đã trong giỏ chưa (flat cart: mỗi user-product là 1 row)
        Cart existingCart = cartRepository.findByUserAndProduct(user, product)
                .orElse(null);

        if (existingCart != null) {
            int newQuantity = existingCart.getQuantity() + request.getQuantity();
            validateStockQuantity(product, newQuantity);
            existingCart.setQuantity(newQuantity);
            cartRepository.save(existingCart);
        } else {
            validateStockQuantity(product, request.getQuantity());
            Cart cartItem = new Cart();
            cartItem.setId(UUID.randomUUID().toString());
            cartItem.setUser(user);
            cartItem.setProduct(product);
            cartItem.setQuantity(request.getQuantity());
            cartRepository.save(cartItem);
        }

        return getCartResponse(user);
    }

    // Cập nhật số lượng sản phẩm
    @Transactional
    public CartResponse updateCartItem(User user, UpdateCartItemRequest request) {
        validateQuantity(request.getQuantity());

        Cart cartItem = cartRepository.findById(request.getCartItemId())
                .orElseThrow(() -> new ResourceNotFoundException("Sản phẩm trong giỏ không tồn tại"));

        if (!cartItem.getUser().getId().equals(user.getId())) {
            throw new InvalidDataException("Không có quyền cập nhật");
        }

        Product product = cartItem.getProduct();
        validateProductAvailability(product);
        validateStockQuantity(product, request.getQuantity());

        cartItem.setQuantity(request.getQuantity());
        cartRepository.save(cartItem);

        return getCartResponse(user);
    }

    // Xóa sản phẩm khỏi giỏ hàng
    @Transactional
    public CartResponse removeFromCart(User user, String cartItemId) {
        Cart cartItem = cartRepository.findById(cartItemId)
                .orElseThrow(() -> new ResourceNotFoundException("Sản phẩm trong giỏ không tồn tại"));

        // Kiểm tra item này thuộc user hiện tại
        if (!cartItem.getUser().getId().equals(user.getId())) {
            throw new InvalidDataException("Không có quyền xóa");
        }

        cartRepository.delete(cartItem);
        return getCartResponse(user);
    }

    // Lấy giỏ hàng
    public CartResponse getCart(User user) {
        return getCartResponse(user);
    }

    // Convert List<Cart> to CartResponse
    private CartResponse getCartResponse(User user) {
        List<Cart> cartItems = cartRepository.findByUser(user);

        var items = cartItems.stream()
                .map(item -> new CartItemResponse(
                        item.getId(),
                        item.getProduct().getId(),
                        item.getProduct().getTitle(),
                        item.getProduct().getPrice(),
                        item.getProduct().getFirstImageUrl(),
                        item.getQuantity(),
                        item.getProduct().getPrice().multiply(BigDecimal.valueOf(item.getQuantity()))
                ))
                .collect(Collectors.toList());

        BigDecimal totalAmount = items.stream()
                .map(CartItemResponse::getSubtotal)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        return new CartResponse(
                user.getId(),
                items,
                items.size(),
                totalAmount
        );
    }

    private void validateQuantity(Integer quantity) {
        if (quantity == null || quantity <= 0) {
            throw new InvalidDataException("Số lượng phải lớn hơn 0");
        }
    }

    private void validateProductAvailability(Product product) {
        int stock = getStockQuantity(product);

        if (product.getStatus() == ProductStatus.sold || stock <= 0) {
            throw new InvalidDataException("Sản phẩm " + product.getTitle() + " đã hết hàng");
        }
    }

    private void validateStockQuantity(Product product, int requestedQuantity) {
        int stock = getStockQuantity(product);

        if (requestedQuantity > stock) {
            throw new InvalidDataException(
                    "Số lượng trong giỏ vượt quá tồn kho sản phẩm "
                            + product.getTitle() + " (còn " + stock + ")"
            );
        }
    }

    private int getStockQuantity(Product product) {
        return product.getQuantity() != null ? product.getQuantity() : 0;
    }

    // Xóa toàn bộ giỏ hàng của user (dùng cho checkout)
    @Transactional
    public void clearCart(User user) {
        List<Cart> cartItems = cartRepository.findByUser(user);
        cartRepository.deleteAll(cartItems);
    }
}
