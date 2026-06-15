# File Summary & Architecture

## Files Created

### 1. Enums (4 files)
```
model/enums/
├── ProductCondition.java    - NEW, LIKE_NEW, USED
├── ProductStatus.java       - AVAILABLE, SOLD_OUT
├── PaymentMethod.java       - CASH, BANK_TRANSFER
└── OrderStatus.java         - PENDING, CONFIRMED, SHIPPED, DELIVERED, CANCELLED
```

### 2. Entities (8 files)
```
model/
├── Category.java            - Danh mục sản phẩm (1-∞ Product)
├── Product.java             - Sản phẩm
│   ├─ category_id (FK)
│   ├─ seller_id (FK → User)
│   └─ relationships: images, cartItems, orderItems
│
├── ProductImage.java        - Hình ảnh sản phẩm (1 Product - ∞ Images)
│
├── Cart.java                - Giỏ hàng (1 User - 1 Cart, unique)
│   ├─ user_id (FK, unique)
│   └─ totalAmount
│
├── CartItem.java            - Chi tiết giỏ hàng (1 Cart - ∞ Items)
│   ├─ cart_id (FK)
│   ├─ product_id (FK)
│   ├─ quantity
│   └─ subtotal
│
├── Order.java               - Đơn hàng
│   ├─ buyer_id (FK → User)
│   ├─ status (enum)
│   ├─ paymentMethod (enum)
│   ├─ receiverName, receiverPhone, deliveryLocation, notes
│   └─ totalAmount
│
└── OrderItem.java           - Chi tiết đơn hàng (1 Order - ∞ Items)
    ├─ order_id (FK)
    ├─ product_id (FK)
    ├─ quantity, unitPrice, subtotal
```

### 3. Request DTOs (4 files)
```
dto/request/
├── AddToCartRequest.java
│   ├─ productId
│   └─ quantity
│
├── UpdateCartItemRequest.java
│   ├─ cartItemId
│   └─ quantity
│
├── CreateOrderRequest.java
│   ├─ paymentMethod
│   └─ deliveryInfo (DeliveryInfoRequest)
│
└── DeliveryInfoRequest.java
    ├─ receiverName
    ├─ receiverPhone
    ├─ deliveryLocation
    └─ notes
```

### 4. Response DTOs (7 files)
```
dto/response/
├── ProductDetailResponse.java
│   ├─ id, name, description, price
│   ├─ categoryName
│   ├─ condition, status
│   ├─ images (ProductImageResponse[])
│   ├─ seller (SellerInfoResponse)
│   └─ createdAt
│
├── ProductImageResponse.java
│   ├─ id, imageUrl, displayOrder
│
├── SellerInfoResponse.java
│   ├─ id, fullName, email, phone, avatarUrl
│
├── CartItemResponse.java
│   ├─ id, productId, productName, productPrice
│   ├─ productImage, quantity, subtotal
│
├── CartResponse.java
│   ├─ cartId
│   ├─ items (CartItemResponse[])
│   ├─ totalItems
│   └─ totalAmount
│
├── OrderItemResponse.java
│   ├─ id, productId, productName
│   ├─ quantity, unitPrice, subtotal
│
└── OrderResponse.java
    ├─ id, totalAmount, status, paymentMethod
    ├─ receiverName, receiverPhone, deliveryLocation, notes
    ├─ items (OrderItemResponse[])
    └─ createdAt
```

### 5. Repositories (6 files)
```
repository/
├── ProductRepository.java        extends JpaRepository<Product, String>
├── CategoryRepository.java       extends JpaRepository<Category, String>
├── CartRepository.java           extends JpaRepository<Cart, String>
│   └─ findByUser(User user)
│
├── CartItemRepository.java       extends JpaRepository<CartItem, String>
│   └─ findByCartAndProduct(Cart, Product)
│
├── OrderRepository.java          extends JpaRepository<Order, String>
│   └─ findByBuyer(User buyer)
│
└── OrderItemRepository.java      extends JpaRepository<OrderItem, String>
    └─ findByOrder(Order order)
```

### 6. Services (3 files)
```
service/
├── ProductService.java
│   └─ getProductDetail(String productId) → ProductDetailResponse
│
├── CartService.java
│   ├─ getOrCreateCart(User) → Cart
│   ├─ addToCart(User, AddToCartRequest) → CartResponse
│   ├─ updateCartItem(User, UpdateCartItemRequest) → CartResponse
│   ├─ removeFromCart(User, String) → CartResponse
│   ├─ getCart(User) → CartResponse
│   ├─ clearCart(Cart) → void
│   └─ Private helpers:
│       ├─ updateCartTotal(Cart)
│       ├─ getCartResponse(Cart)
│       └─ validateQuantity(Integer)
│
└── OrderService.java
    ├─ createOrder(User, CreateOrderRequest) → OrderResponse
    ├─ getOrderDetail(String, User) → OrderResponse
    ├─ getUserOrders(User) → List<OrderResponse>
    └─ Private helpers:
        ├─ validatePaymentMethod(String)
        ├─ validateDeliveryInfo(Object)
        └─ getOrderResponse(Order)
```

### 7. Controllers (3 files)
```
controller/
├── ProductController.java
│   └─ GET /api/products/{productId}
│
├── CartController.java
│   ├─ POST /api/cart/add
│   ├─ GET /api/cart
│   ├─ PUT /api/cart/update
│   └─ DELETE /api/cart/{cartItemId}
│
└── OrderController.java
    ├─ POST /api/orders/create
    ├─ GET /api/orders/{orderId}
    └─ GET /api/orders
```

### 8. Exception Classes (2 files)
```
exception/
├── ResourceNotFoundException.java
│   └─ extends RuntimeException
│
└── InvalidDataException.java
    └─ extends RuntimeException
```

### 9. Documentation (2 files)
```
├── API_DOCUMENTATION.md
│   ├─ Product Detail API
│   ├─ Shopping Cart API (Add, Get, Update, Delete)
│   ├─ Order API (Create, Get Detail, Get List)
│   ├─ Enums description
│   ├─ Database Schema
│   └─ Relationships diagram
│
└── IMPLEMENTATION_GUIDE.md
    ├─ Project Structure
    ├─ Entity Relationships Diagram
    ├─ Key Features Implementation Details
    ├─ Technology Stack
    ├─ Configuration
    ├─ How to Build & Run
    ├─ Next Steps (TODO)
    └─ Notes on User Context
```

---

## Business Logic Summary

### Product Detail
- ✅ Lấy sản phẩm theo ID
- ✅ Kiểm tra tồn tại (404 nếu không)
- ✅ Trả về đầy đủ info: giá, mô tả, hình ảnh, thông tin seller, thời gian

### Shopping Cart
- ✅ Tạo giỏ tự động cho user
- ✅ 1 user = 1 giỏ (unique)
- ✅ Thêm sản phẩm:
  - ✅ Kiểm tra sản phẩm tồn tại
  - ✅ Kiểm tra SOLD_OUT
  - ✅ Nếu đã có → tăng qty (không tạo mới)
  - ✅ Cập nhật subtotal & totalAmount
- ✅ Cập nhật số lượng:
  - ✅ Kiểm tra qty > 0
  - ✅ Cập nhật subtotal & totalAmount
- ✅ Xóa sản phẩm:
  - ✅ Cập nhật totalAmount
- ✅ Lấy giỏ:
  - ✅ Trả về danh sách items + tổng tiền
  - ✅ Tính totalItems từ số CartItem

### Order / Checkout
- ✅ Kiểm tra giỏ không rỗng
- ✅ Kiểm tra sản phẩm tồn tại & AVAILABLE
- ✅ Validate PaymentMethod (CASH, BANK_TRANSFER)
- ✅ Validate DeliveryInfo
- ✅ Tính tổng tiền từ CartItems
- ✅ Tạo Order (status = PENDING)
- ✅ Tạo OrderItem từ CartItem
- ✅ Xóa giỏ hàng sau checkout
- ✅ Trả về OrderResponse

---

## Database Design

### Entities & Relationships
```
Users (1) ──┬─→ (∞) Carts
            ├─→ (∞) Orders
            └─→ (∞) Products (as Seller)

Categories (1) ──→ (∞) Products

Products (1) ──┬─→ (∞) ProductImages
               ├─→ (∞) CartItems
               └─→ (∞) OrderItems

Carts (1) ──→ (∞) CartItems

Orders (1) ──→ (∞) OrderItems
```

### Constraints
- User.id: PK, UUID
- Cart.user_id: FK (UNIQUE) - 1 cart per user
- Product.category_id: FK (NOT NULL)
- Product.seller_id: FK (NOT NULL)
- CartItem.cart_id, product_id: FK (NOT NULL)
- OrderItem.order_id, product_id: FK (NOT NULL)

---

## Testing Checklist

### Product Detail ✅
- [ ] GET /api/products/valid-id → 200 + ProductDetail
- [ ] GET /api/products/invalid-id → 404 + error message
- [ ] Response includes: name, price, description, images, seller info

### Shopping Cart ✅
- [ ] POST /api/cart/add → CartResponse with new item
- [ ] POST /api/cart/add (duplicate product) → qty increased
- [ ] POST /api/cart/add (SOLD_OUT) → 400 error
- [ ] POST /api/cart/add (qty ≤ 0) → 400 error
- [ ] GET /api/cart → current cart with totalAmount
- [ ] PUT /api/cart/update → updated cart
- [ ] PUT /api/cart/update (qty ≤ 0) → 400 error
- [ ] DELETE /api/cart/{id} → item removed, total recalculated

### Order ✅
- [ ] POST /api/orders/create (valid) → 201 + OrderResponse
- [ ] POST /api/orders/create (empty cart) → 400 error
- [ ] POST /api/orders/create (SOLD_OUT product) → 400 error
- [ ] POST /api/orders/create (invalid payment method) → 400 error
- [ ] Cart cleared after successful order
- [ ] GET /api/orders/{id} → OrderResponse
- [ ] GET /api/orders → List of user's orders

---

## Deployment Notes

1. **Database Setup**: Run migration scripts để tạo tables
2. **User Context**: TODO - Integrate with Auth (JWT/OAuth)
3. **Error Handling**: Global exception handler cần config
4. **Logging**: Add SLF4J logging
5. **Security**: Add @PreAuthorize, @Secured annotations
