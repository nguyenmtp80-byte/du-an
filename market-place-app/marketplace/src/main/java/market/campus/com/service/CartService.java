package market.campus.com.service;

import market.campus.com.dto.request.AddToCartRequest;
import market.campus.com.dto.request.UpdateCartItemRequest;
import market.campus.com.dto.response.CartItemResponse;
import market.campus.com.dto.response.CartResponse;
import market.campus.com.exception.InvalidDataException;
import market.campus.com.exception.ResourceNotFoundException;
import market.campus.com.model.*;
import market.campus.com.model.enums.ProductStatus;
import market.campus.com.repository.CartItemRepository;
import market.campus.com.repository.CartRepository;
import market.campus.com.repository.ProductRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.math.BigDecimal;
import java.util.stream.Collectors;

@Service
public class CartService {

    @Autowired
    private CartRepository cartRepository;

    @Autowired
    private CartItemRepository cartItemRepository;

    @Autowired
    private ProductRepository productRepository;

    // Tạo giỏ hàng mới cho user
    public Cart getOrCreateCart(User user) {
        return cartRepository.findByUser(user)
                .orElseGet(() -> {
                    Cart newCart = new Cart(user);
                    return cartRepository.save(newCart);
                });
    }

    // Thêm sản phẩm vào giỏ hàng
    @Transactional
    public CartResponse addToCart(User user, AddToCartRequest request) {
        validateQuantity(request.getQuantity());

        Product product = productRepository.findById(request.getProductId())
                .orElseThrow(() -> new ResourceNotFoundException("Sản phẩm không tồn tại"));

        // Kiểm tra sản phẩm có sẵn hay không
        if (product.getStatus() == ProductStatus.SOLD_OUT) {
            throw new InvalidDataException("Sản phẩm đã hết hàng");
        }

        Cart cart = getOrCreateCart(user);

        // Kiểm tra sản phẩm đã trong giỏ chưa
        CartItem existingItem = cartItemRepository.findByCartAndProduct(cart, product)
                .orElse(null);

        if (existingItem != null) {
            // Tăng số lượng nếu sản phẩm đã tồn tại
            int newQuantity = existingItem.getQuantity() + request.getQuantity();
            existingItem.setQuantity(newQuantity);
            BigDecimal newSubtotal = product.getPrice().multiply(BigDecimal.valueOf(newQuantity));
            existingItem.setSubtotal(newSubtotal);
            cartItemRepository.save(existingItem);
        } else {
            // Tạo item mới
            BigDecimal subtotal = product.getPrice().multiply(BigDecimal.valueOf(request.getQuantity()));
            CartItem cartItem = new CartItem(cart, product, request.getQuantity(), subtotal);
            cartItemRepository.save(cartItem);
        }

        // Cập nhật tổng tiền giỏ hàng
        updateCartTotal(cart);
        return getCartResponse(cart);
    }

    // Cập nhật số lượng sản phẩm
    @Transactional
    public CartResponse updateCartItem(User user, UpdateCartItemRequest request) {
        validateQuantity(request.getQuantity());

        CartItem cartItem = cartItemRepository.findById(request.getCartItemId())
                .orElseThrow(() -> new ResourceNotFoundException("Sản phẩm trong giỏ không tồn tại"));

        // Kiểm tra item này thuộc giỏ của user hiện tại
        if (!cartItem.getCart().getUser().getId().equals(user.getId())) {
            throw new InvalidDataException("Không có quyền cập nhật");
        }

        Product product = cartItem.getProduct();
        cartItem.setQuantity(request.getQuantity());
        BigDecimal newSubtotal = product.getPrice().multiply(BigDecimal.valueOf(request.getQuantity()));
        cartItem.setSubtotal(newSubtotal);
        cartItemRepository.save(cartItem);

        // Cập nhật tổng tiền giỏ hàng
        updateCartTotal(cartItem.getCart());
        return getCartResponse(cartItem.getCart());
    }

    // Xóa sản phẩm khỏi giỏ hàng
    @Transactional
    public CartResponse removeFromCart(User user, String cartItemId) {
        CartItem cartItem = cartItemRepository.findById(cartItemId)
                .orElseThrow(() -> new ResourceNotFoundException("Sản phẩm trong giỏ không tồn tại"));

        // Kiểm tra item này thuộc giỏ của user hiện tại
        if (!cartItem.getCart().getUser().getId().equals(user.getId())) {
            throw new InvalidDataException("Không có quyền xóa");
        }

        Cart cart = cartItem.getCart();
        cartItemRepository.delete(cartItem);

        // Cập nhật tổng tiền giỏ hàng
        updateCartTotal(cart);
        return getCartResponse(cart);
    }

    // Lấy giỏ hàng
    public CartResponse getCart(User user) {
        Cart cart = getOrCreateCart(user);
        return getCartResponse(cart);
    }

    // Cập nhật tổng tiền giỏ hàng
    private void updateCartTotal(Cart cart) {
        BigDecimal total = cart.getItems().stream()
                .map(CartItem::getSubtotal)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        cart.setTotalAmount(total);
        cartRepository.save(cart);
    }

    // Convert Cart to CartResponse
    private CartResponse getCartResponse(Cart cart) {
        var items = cart.getItems().stream()
                .map(item -> new CartItemResponse(
                        item.getId(),
                        item.getProduct().getId(),
                        item.getProduct().getName(),
                        item.getProduct().getPrice(),
                        item.getProduct().getImages().isEmpty() ? null : 
                            item.getProduct().getImages().get(0).getImageUrl(),
                        item.getQuantity(),
                        item.getSubtotal()
                ))
                .collect(Collectors.toList());

        return new CartResponse(
                cart.getId(),
                items,
                items.size(),
                cart.getTotalAmount()
        );
    }

    // Validate quantity
    private void validateQuantity(Integer quantity) {
        if (quantity == null || quantity <= 0) {
            throw new InvalidDataException("Số lượng phải lớn hơn 0");
        }
    }

    // Xóa toàn bộ giỏ hàng (dùng cho checkout)
    @Transactional
    public void clearCart(Cart cart) {
        cart.getItems().clear();
        cart.setTotalAmount(BigDecimal.ZERO);
        cartRepository.save(cart);
    }
}
