# Marketplace - Backend Implementation

## Overview
Xây dựng 3 chức năng chính cho marketplace:
1. **Product Detail** - Xem chi tiết sản phẩm
2. **Shopping Cart** - Giỏ hàng
3. **Checkout/Order** - Tạo đơn hàng

---

## Project Structure

```
marketplace/
├── src/main/java/market/campus/com/
│   ├── model/
│   │   ├── User.java
│   │   ├── Category.java
│   │   ├── Product.java
│   │   ├── ProductImage.java
│   │   ├── Cart.java
│   │   ├── CartItem.java
│   │   ├── Order.java
│   │   ├── OrderItem.java
│   │   └── enums/
│   │       ├── ProductCondition.java
│   │       ├── ProductStatus.java
│   │       ├── PaymentMethod.java
│   │       └── OrderStatus.java
│   │
│   ├── dto/
│   │   ├── request/
│   │   │   ├── AddToCartRequest.java
│   │   │   ├── UpdateCartItemRequest.java
│   │   │   ├── CreateOrderRequest.java
│   │   │   └── DeliveryInfoRequest.java
│   │   └── response/
│   │       ├── ProductDetailResponse.java
│   │       ├── SellerInfoResponse.java
│   │       ├── ProductImageResponse.java
│   │       ├── CartResponse.java
│   │       ├── CartItemResponse.java
│   │       ├── OrderResponse.java
│   │       └── OrderItemResponse.java
│   │
│   ├── repository/
│   │   ├── ProductRepository.java
│   │   ├── CategoryRepository.java
│   │   ├── CartRepository.java
│   │   ├── CartItemRepository.java
│   │   ├── OrderRepository.java
│   │   └── OrderItemRepository.java
│   │
│   ├── service/
│   │   ├── ProductService.java
│   │   ├── CartService.java
│   │   └── OrderService.java
│   │
│   ├── controller/
│   │   ├── ProductController.java
│   │   ├── CartController.java
│   │   └── OrderController.java
│   │
│   ├── exception/
│   │   ├── ResourceNotFoundException.java
│   │   ├── InvalidDataException.java
│   │   └── GlobalExceptionHandler.java
│   │
│   ├── config/
│   │   └── (Configuration files)
│   │
│   └── MarketplaceApplication.java
│
├── API_DOCUMENTATION.md
├── pom.xml
└── README.md
```

---

## Entity Relationships

### Database Diagram
```
┌──────────┐     ┌────────────┐
│  User    │────▶│  Category  │
└──────────┘     └────────────┘
    ▲                 ▲
    │                 │ 1
    │ 1               │
    │                 │ ∞
    │            ┌─────────────┐
    │            │   Product   │
    │            └─────────────┘
    │                 │ 1
    │                 │ ∞
    │                 └─────┬─────┐
    │                       │     │
    │               ┌───────────────────────┐
    │               │  ProductImage         │
    │               ├───────────────────────┤
    │               │ - id                  │
    │               │ - imageUrl            │
    │               │ - displayOrder        │
    │               └───────────────────────┘
    │
    ├──────────────────┬──────────────────┐
    │ 1                │ 1                │ 1
    │ ∞                │ ∞                │ ∞
┌────────┐      ┌──────────┐        ┌────────┐
│ Cart   │      │  Order   │        │ Cart   │
│        │      │          │        │        │
│ 1-1    │      │ 1-∞      │        │ 1-1    │
└────────┘      └──────────┘        └────────┘
    │                 │ 1               │ 1
    │ 1               │                 │
    │ ∞               │ ∞               │ ∞
┌──────────┐     ┌──────────┐     ┌──────────┐
│CartItem  │     │OrderItem │     │CartItem  │
│          │     │          │     │          │
│ - product│     │ - product│     │ - product│
│ - qty    │     │ - qty    │     │ - qty    │
└──────────┘     └──────────┘     └──────────┘
```

---

## Key Features Implementation

### 1. Product Detail

**File**: `ProductService.java`, `ProductController.java`

**Features**:
- Lấy chi tiết sản phẩm theo ID
- Trả về tất cả thông tin: giá, mô tả, hình ảnh, thông tin người bán, thời gian tạo
- Kiểm tra sản phẩm tồn tại
- Tách riêng Entity và Response DTO

**API Endpoint**:
```
GET /api/products/{productId}
```

---

### 2. Shopping Cart

**Files**: `Cart.java`, `CartItem.java`, `CartService.java`, `CartController.java`

**Features**:

#### a. Tạo giỏ hàng
- Mỗi user chỉ có 1 giỏ hàng
- Tự động tạo khi user lần đầu thêm sản phẩm
- Relationship: `User 1-1 Cart` (unique)

#### b. Thêm sản phẩm
- Kiểm tra sản phẩm tồn tại
- Kiểm tra sản phẩm không SOLD_OUT
- Nếu sản phẩm đã trong giỏ → tăng số lượng
- Nếu sản phẩm mới → tạo CartItem mới
- Cập nhật subtotal = price × quantity
- Cập nhật totalAmount của Cart

#### c. Cập nhật số lượng
- Kiểm tra CartItem tồn tại
- Kiểm tra quyền sở hữu
- Số lượng phải > 0
- Cập nhật subtotal và totalAmount

#### d. Xóa sản phẩm
- Kiểm tra CartItem tồn tại
- Kiểm tra quyền sở hữu
- Xóa CartItem
- Cập nhật totalAmount

#### e. Lấy giỏ hàng
- Trả về danh sách CartItem + tổng tiền
- Tính totalItems từ số lượng cartItems
- Trả về thông tin chi tiết mỗi sản phẩm

**Business Logic Validation**:
```java
// Không thêm sản phẩm SOLD_OUT
if (product.getStatus() == ProductStatus.SOLD_OUT)
    throw new InvalidDataException("Sản phẩm đã hết hàng");

// Số lượng phải > 0
if (quantity <= 0)
    throw new InvalidDataException("Số lượng phải lớn hơn 0");

// Không tạo CartItem mới nếu đã tồn tại
CartItem existingItem = findByCartAndProduct(cart, product);
if (existingItem != null)
    existingItem.quantity += newQuantity;  // Tăng số lượng
```

**API Endpoints**:
```
POST   /api/cart/add              - Thêm sản phẩm
GET    /api/cart                  - Lấy giỏ hàng
PUT    /api/cart/update           - Cập nhật số lượng
DELETE /api/cart/{cartItemId}     - Xóa sản phẩm
```

---

### 3. Checkout / Create Order

**Files**: `Order.java`, `OrderItem.java`, `OrderService.java`, `OrderController.java`

**Process Flow**:
```
1. User gọi POST /api/orders/create
   │
2. Service kiểm tra:
   ├─ Giỏ hàng có rỗng?
   ├─ Sản phẩm còn tồn tại?
   └─ Sản phẩm còn AVAILABLE?
   │
3. Validate dữ liệu:
   ├─ PaymentMethod hợp lệ?
   └─ DeliveryInfo đầy đủ?
   │
4. Tính tổng tiền từ CartItems
   │
5. Tạo Order (status = PENDING)
   │
6. Tạo OrderItems từ CartItems
   │
7. Xóa giỏ hàng
   │
8. Trả về OrderResponse
```

**Features**:

#### a. Tạo đơn hàng
- Lấy toàn bộ CartItem
- Kiểm tra giỏ không rỗng
- Kiểm tra sản phẩm còn AVAILABLE
- Xác thực PaymentMethod (CASH, BANK_TRANSFER)
- Xác thực DeliveryInfo (không rỗng)

#### b. Tạo OrderItem
- Mỗi CartItem → 1 OrderItem
- Lưu unitPrice, quantity, subtotal
- Tính tổng tiền đơn = Σ subtotal

#### c. Lưu thông tin giao hàng
- receiverName (bắt buộc)
- receiverPhone (bắt buộc)
- deliveryLocation (bắt buộc)
- notes (tùy chọn)

#### d. Trạng thái đơn hàng
- Default: PENDING
- Có thể chuyển sang: CONFIRMED, SHIPPED, DELIVERED, CANCELLED

#### e. Dọn dẹp
- Xóa toàn bộ CartItem
- Reset Cart.totalAmount = 0

**Business Logic Validation**:
```java
// Kiểm tra giỏ không rỗng
if (cart.getItems().isEmpty())
    throw new InvalidDataException("Giỏ hàng trống");

// Kiểm tra tất cả sản phẩm AVAILABLE
for (CartItem item : cart.getItems()) {
    if (item.getProduct().getStatus() != ProductStatus.AVAILABLE)
        throw new InvalidDataException("Sản phẩm không còn sẵn");
}

// Validate PaymentMethod
if (!isValidPaymentMethod(paymentMethod))
    throw new InvalidDataException("Phương thức thanh toán không hợp lệ");

// Xóa giỏ sau khi tạo đơn thành công
cartService.clearCart(cart);
```

**API Endpoints**:
```
POST GET /api/orders/create           - Tạo đơn hàng
GET  /api/orders/{orderId}           - Lấy chi tiết đơn
GET  /api/orders                     - Lấy danh sách đơn của user
```

---

## Technology Stack

- **Framework**: Spring Boot 3.2.12
- **Language**: Java 21
- **Database**: JPA/Hibernate
- **Build**: Maven
- **API**: REST

---

## Configuration

### Application Properties

```properties
# Database (configure based on your setup)
spring.datasource.url=jdbc:mysql://localhost:3306/marketplace
spring.datasource.username=root
spring.datasource.password=
spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=true

# Server
server.port=8080
```

---

## How to Build & Run

### 1. Build Project
```bash
cd marketplace
mvn clean build
```

### 2. Run Application
```bash
mvn spring-boot:run
```

### 3. Test API

#### Product Detail
```bash
curl -X GET http://localhost:8080/api/products/product-123
```

#### Add to Cart
```bash
curl -X POST http://localhost:8080/api/cart/add \
  -H "Content-Type: application/json" \
  -H "X-User-Id: user-1" \
  -d '{
    "productId": "product-123",
    "quantity": 1
  }'
```

#### Create Order
```bash
curl -X POST http://localhost:8080/api/orders/create \
  -H "Content-Type: application/json" \
  -H "X-User-Id: user-1" \
  -d '{
    "paymentMethod": "CASH",
    "deliveryInfo": {
      "receiverName": "Nguyễn Văn B",
      "receiverPhone": "0987654321",
      "deliveryLocation": "123 Đường ABC, TPHCM",
      "notes": "Giao vào buổi tối"
    }
  }'
```

---

## Next Steps

### TODO - Integration
- [ ] Integrate with Authentication (JWT/OAuth)
- [ ] Add User context from Security (instead of X-User-Id header)
- [ ] Add Global Exception Handler
- [ ] Add Logging

### TODO - Features
- [ ] Add product search & filter
- [ ] Add order status tracking
- [ ] Add payment gateway integration
- [ ] Add reviews & ratings
- [ ] Add order cancellation
- [ ] Add pagination

### TODO - Testing
- [ ] Unit tests for Services
- [ ] Integration tests for Controllers
- [ ] API tests

---

## Notes

⚠️ **Current Limitation**: User context từ `X-User-Id` header. Cần integrate authentication để lấy user từ JWT token.

```java
// Hiện tại
User user = new User();
user.setId(userId);  // Từ header

// Tương lai
User user = getCurrentUser();  // Từ SecurityContext
```

---

## Support

Xem file `API_DOCUMENTATION.md` để chi tiết các endpoint và response examples.
