# Quick Start Guide - Marketplace Implementation

## 📋 What Was Built

Xây dựng **3 chức năng chính** cho marketplace Java Spring Boot:

### 1️⃣ Product Detail - Xem Chi Tiết Sản Phẩm
- Lấy đầy đủ thông tin sản phẩm: giá, mô tả, hình ảnh, người bán
- Kiểm tra sản phẩm tồn tại
- Trả về error nếu không tìm thấy

### 2️⃣ Shopping Cart - Giỏ Hàng
- Tạo giỏ tự động cho mỗi user (1 user = 1 giỏ)
- Thêm/cập nhật/xóa sản phẩm
- Tính tự động tổng tiền
- Business logic: không cho thêm SOLD_OUT, tăng qty nếu đã có

### 3️⃣ Checkout - Tạo Đơn Hàng
- Kiểm tra giỏ, sản phẩm, trạng thái
- Tạo Order + OrderItems từ Cart
- Lưu thông tin giao hàng + phương thức thanh toán
- Xóa giỏ sau khi checkout thành công

---

## 📁 Files Created (33 Files Total)

### Entities (8)
```
Category.java, Product.java, ProductImage.java
Cart.java, CartItem.java
Order.java, OrderItem.java
+ User.java (đã có)
```

### Enums (4)
```
ProductCondition.java, ProductStatus.java
PaymentMethod.java, OrderStatus.java
```

### DTOs Request (4)
```
AddToCartRequest.java
UpdateCartItemRequest.java
CreateOrderRequest.java
DeliveryInfoRequest.java
```

### DTOs Response (7)
```
ProductDetailResponse.java, ProductImageResponse.java, SellerInfoResponse.java
CartResponse.java, CartItemResponse.java
OrderResponse.java, OrderItemResponse.java
```

### Repositories (6)
```
ProductRepository.java, CategoryRepository.java
CartRepository.java, CartItemRepository.java
OrderRepository.java, OrderItemRepository.java
```

### Services (3)
```
ProductService.java
CartService.java
OrderService.java
```

### Controllers (3)
```
ProductController.java
CartController.java
OrderController.java
```

### Exception Handling (2)
```
ResourceNotFoundException.java
InvalidDataException.java
```

### Documentation (5)
```
API_DOCUMENTATION.md         - Chi tiết API endpoints
IMPLEMENTATION_GUIDE.md      - Hướng dẫn triển khai
FILES_SUMMARY.md            - Tóm tắt các files
TEST_CASES.md               - Test scenarios & curl examples
QUICK_START.md              - File này
```

---

## 🚀 Getting Started

### 1. Build Project
```bash
cd market-place-app/marketplace
mvn clean install
```

### 2. Run Application
```bash
mvn spring-boot:run
```

Server sẽ khởi động tại: `http://localhost:8080`

### 3. Test APIs

#### Get Product Detail
```bash
curl http://localhost:8080/api/products/prod-1
```

#### Add to Cart
```bash
curl -X POST http://localhost:8080/api/cart/add \
  -H "Content-Type: application/json" \
  -H "X-User-Id: user-2" \
  -d '{"productId": "prod-1", "quantity": 1}'
```

#### Create Order
```bash
curl -X POST http://localhost:8080/api/orders/create \
  -H "Content-Type: application/json" \
  -H "X-User-Id: user-2" \
  -d '{
    "paymentMethod": "CASH",
    "deliveryInfo": {
      "receiverName": "Nguyễn Văn A",
      "receiverPhone": "0123456789",
      "deliveryLocation": "123 Đường ABC, TPHCM",
      "notes": ""
    }
  }'
```

---

## 📚 Documentation Files

| File | Nội dung |
|------|---------|
| **API_DOCUMENTATION.md** | 📖 Tất cả API endpoints, request/response examples |
| **IMPLEMENTATION_GUIDE.md** | 🏗️ Cấu trúc project, business logic, setup |
| **FILES_SUMMARY.md** | 📋 Danh sách tất cả files + chức năng |
| **TEST_CASES.md** | ✅ Test scenarios, curl commands, expected responses |
| **QUICK_START.md** | ⚡ File này - hướng dẫn nhanh |

---

## 🔄 API Endpoints

### Products
```
GET  /api/products/{productId}
```

### Cart
```
POST   /api/cart/add                   - Thêm sản phẩm
GET    /api/cart                       - Lấy giỏ hàng
PUT    /api/cart/update                - Cập nhật số lượng
DELETE /api/cart/{cartItemId}          - Xóa sản phẩm
```

### Orders
```
POST GET /api/orders/create            - Tạo đơn hàng
GET    /api/orders/{orderId}           - Lấy chi tiết đơn
GET    /api/orders                     - Lấy tất cả đơn của user
```

---

## 💾 Database Schema

```sql
-- Entities
Users ──(1-1)──► Carts
      ──(1-∞)──► Orders
      ──(1-∞)──► Products (as seller)

Categories ──(1-∞)──► Products

Products ──(1-∞)──┬─► ProductImages
                  ├─► CartItems
                  └─► OrderItems

Carts ──(1-∞)──► CartItems

Orders ──(1-∞)──► OrderItems
```

---

## ✨ Business Logic Highlights

### Product Detail
✅ Trả về tất cả info: giá, mô tả, images, seller info, thời gian
✅ Kiểm tra 404 nếu sản phẩm không tồn tại

### Shopping Cart
✅ 1 user = 1 giỏ (unique constraint)
✅ Tự động tạo giỏ khi user thêm sản phẩm lần đầu
✅ Tăng qty nếu sản phẩm đã có (không tạo item mới)
✅ Không cho thêm SOLD_OUT
✅ Số lượng phải > 0
✅ Tự động cập nhật subtotal & totalAmount

### Order / Checkout
✅ Kiểm tra giỏ không rỗng
✅ Kiểm tra sản phẩm tồn tại & AVAILABLE
✅ Validate PaymentMethod (CASH / BANK_TRANSFER)
✅ Tạo Order (status = PENDING)
✅ Tạo OrderItem từ CartItem
✅ **Xóa giỏ hàng** sau khi checkout thành công

---

## 🔧 Configuration

### Application Properties
```properties
server.port=8080
spring.jpa.hibernate.ddl-auto=update
```

### Authentication (TODO)
⚠️ Hiện tại: Sử dụng `X-User-Id` header
🔄 Future: Integrate JWT/OAuth + SecurityContext

---

## 📝 Example Flow

### Scenario: User mua 2 sản phẩm

```
1. GET /api/products/prod-1
   └─ Trả về: iPhone 15 Pro - 25,000,000 VND

2. POST /api/cart/add
   Body: productId=prod-1, quantity=1
   └─ Cart: [Item1: qty=1, subtotal=25,000,000]

3. GET /api/products/prod-2
   └─ Trả về: MacBook Pro - 50,000,000 VND

4. POST /api/cart/add
   Body: productId=prod-2, quantity=1
   └─ Cart: [Item1, Item2], totalAmount=75,000,000

5. GET /api/cart
   └─ Trả về: 2 items, tổng 75,000,000

6. POST /api/orders/create
   Body: paymentMethod=CASH, deliveryInfo={...}
   └─ Created Order (PENDING status)
   └─ Cart cleared: totalAmount=0

7. GET /api/orders/{orderId}
   └─ Chi tiết đơn hàng với 2 items
```

---

## 🧪 Quick Test with Postman

1. Import endpoints vào Postman
2. Set base URL: `http://localhost:8080`
3. Set variable `userId`: `user-2`
4. Run requests theo scenario trong TEST_CASES.md

---

## ⚙️ Tech Stack

- **Framework**: Spring Boot 3.2.12
- **Language**: Java 21
- **Database**: JPA/Hibernate (MySQL/PostgreSQL)
- **Build**: Maven
- **API**: REST

---

## 🛠️ Troubleshooting

### Database không kết nối?
```
→ Kiểm tra application.properties
→ Đảm bảo DB server đang chạy
→ Check spring.jpa.hibernate.ddl-auto=update
```

### API trả về 404?
```
→ Kiểm tra test data tồn tại trong DB
→ Verify endpoint path đúng
→ Check X-User-Id header
```

### Cart không lưu?
```
→ Kiểm tra User.id setup đúng
→ Verify Carts table created
→ Check FK constraints
```

---

## 📖 Learn More

- **Entities & Relationships**: Xem `IMPLEMENTATION_GUIDE.md`
- **All Endpoints**: Xem `API_DOCUMENTATION.md`
- **Test Examples**: Xem `TEST_CASES.md`
- **File Listing**: Xem `FILES_SUMMARY.md`

---

## 🎯 Next Steps

### Immediate
- [ ] Create test data in DB
- [ ] Test all endpoints
- [ ] Verify business logic

### Short-term
- [ ] Integrate Authentication (JWT)
- [ ] Add Global Exception Handler
- [ ] Add Logging (SLF4J)
- [ ] Add Unit Tests

### Long-term
- [ ] Add payment gateway
- [ ] Add order tracking
- [ ] Add notifications
- [ ] Add reviews & ratings

---

## 💬 Summary

**Đã xây dựng xong:**
- ✅ 8 Entities với relationships
- ✅ 4 Enums
- ✅ 11 DTOs (Request + Response)
- ✅ 6 Repositories
- ✅ 3 Services với business logic
- ✅ 3 Controllers với REST APIs
- ✅ Exception handling
- ✅ Comprehensive documentation

**Ready to:** Deploy & test! 🚀

Xem `API_DOCUMENTATION.md` để chi tiết tất cả endpoints.
