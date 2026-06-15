# API Documentation - Marketplace Features

## 1. Product Detail API

### Endpoint
```
GET /api/products/{productId}
```

### Description
Lấy chi tiết sản phẩm bao gồm tất cả thông tin: giá, mô tả, hình ảnh, thông tin người bán, etc.

### Response Example
```json
{
  "id": "product-123",
  "name": "iPhone 15 Pro",
  "description": "iPhone 15 Pro màu đen chưa sử dụng",
  "price": 25000000,
  "categoryName": "Điện tử",
  "condition": "NEW",
  "status": "AVAILABLE",
  "images": [
    {
      "id": "img-1",
      "imageUrl": "https://example.com/image1.jpg",
      "displayOrder": 1
    }
  ],
  "seller": {
    "id": "user-1",
    "fullName": "Nguyễn Văn A",
    "email": "a@example.com",
    "phone": "0123456789",
    "avatarUrl": "https://example.com/avatar.jpg"
  },
  "createdAt": "2024-06-15T10:00:00"
}
```

### Error Responses
- **404**: Sản phẩm không tồn tại
  ```json
  {
    "message": "Sản phẩm không tồn tại"
  }
  ```

---

## 2. Shopping Cart API

### 2.1 Thêm sản phẩm vào giỏ hàng

#### Endpoint
```
POST /api/cart/add
Header: X-User-Id: <userId>
```

#### Request Body
```json
{
  "productId": "product-123",
  "quantity": 1
}
```

#### Response
```json
{
  "cartId": "cart-1",
  "items": [
    {
      "id": "cart-item-1",
      "productId": "product-123",
      "productName": "iPhone 15 Pro",
      "productPrice": 25000000,
      "productImage": "https://example.com/image1.jpg",
      "quantity": 1,
      "subtotal": 25000000
    }
  ],
  "totalItems": 1,
  "totalAmount": 25000000
}
```

#### Business Logic
- Nếu sản phẩm đã SOLD_OUT → lỗi
- Nếu sản phẩm đã có trong giỏ → tăng số lượng thay vì tạo item mới
- Số lượng phải > 0

#### Error Responses
- **400**: Sản phẩm hết hàng
  ```json
  {
    "message": "Sản phẩm đã hết hàng"
  }
  ```
- **400**: Số lượng không hợp lệ
  ```json
  {
    "message": "Số lượng phải lớn hơn 0"
  }
  ```

---

### 2.2 Lấy giỏ hàng

#### Endpoint
```
GET /api/cart
Header: X-User-Id: <userId>
```

#### Response
```json
{
  "cartId": "cart-1",
  "items": [
    {
      "id": "cart-item-1",
      "productId": "product-123",
      "productName": "iPhone 15 Pro",
      "productPrice": 25000000,
      "productImage": "https://example.com/image1.jpg",
      "quantity": 1,
      "subtotal": 25000000
    }
  ],
  "totalItems": 1,
  "totalAmount": 25000000
}
```

---

### 2.3 Cập nhật số lượng sản phẩm

#### Endpoint
```
PUT /api/cart/update
Header: X-User-Id: <userId>
```

#### Request Body
```json
{
  "cartItemId": "cart-item-1",
  "quantity": 2
}
```

#### Response
- Trả về CartResponse toàn bộ giỏ hàng sau khi cập nhật

#### Business Logic
- Số lượng phải > 0
- Kiểm tra quyền sở hữu item

---

### 2.4 Xóa sản phẩm khỏi giỏ hàng

#### Endpoint
```
DELETE /api/cart/{cartItemId}
Header: X-User-Id: <userId>
```

#### Response
- Trả về CartResponse toàn bộ giỏ hàng sau khi xóa

---

## 3. Order (Checkout) API

### 3.1 Tạo đơn hàng

#### Endpoint
```
POST /api/orders/create
Header: X-User-Id: <userId>
```

#### Request Body
```json
{
  "paymentMethod": "CASH",
  "deliveryInfo": {
    "receiverName": "Nguyễn Văn B",
    "receiverPhone": "0987654321",
    "deliveryLocation": "123 Đường ABC, Quận 1, TPHCM",
    "notes": "Giao hàng vào buổi tối"
  }
}
```

#### Response
```json
{
  "message": "Tạo đơn hàng thành công",
  "data": {
    "id": "order-1",
    "totalAmount": 50000000,
    "status": "PENDING",
    "paymentMethod": "CASH",
    "receiverName": "Nguyễn Văn B",
    "receiverPhone": "0987654321",
    "deliveryLocation": "123 Đường ABC, Quận 1, TPHCM",
    "notes": "Giao hàng vào buổi tối",
    "items": [
      {
        "id": "order-item-1",
        "productId": "product-123",
        "productName": "iPhone 15 Pro",
        "quantity": 2,
        "unitPrice": 25000000,
        "subtotal": 50000000
      }
    ],
    "createdAt": "2024-06-15T15:30:00"
  }
}
```

#### Business Logic
- **Kiểm tra giỏ hàng**:
  - Giỏ không được rỗng
  - Tất cả sản phẩm phải tồn tại
  - Tất cả sản phẩm phải có trạng thái AVAILABLE

- **Xác thực dữ liệu**:
  - paymentMethod phải là CASH hoặc BANK_TRANSFER
  - deliveryInfo bắt buộc

- **Tạo đơn hàng**:
  - OrderStatus mặc định: PENDING
  - Tạo OrderItem tương ứng mỗi CartItem
  - Lưu thông tin giao hàng

- **Dọn dẹp**:
  - Xóa toàn bộ dữ liệu giỏ hàng sau khi tạo đơn thành công

#### Error Responses
- **400**: Giỏ hàng trống
  ```json
  {
    "message": "Giỏ hàng trống, không thể tạo đơn hàng"
  }
  ```
- **400**: Sản phẩm không sẵn
  ```json
  {
    "message": "Sản phẩm iPhone 15 Pro không còn sẵn"
  }
  ```
- **400**: Phương thức thanh toán không hợp lệ
  ```json
  {
    "message": "Phương thức thanh toán không hợp lệ"
  }
  ```

---

### 3.2 Lấy chi tiết đơn hàng

#### Endpoint
```
GET /api/orders/{orderId}
Header: X-User-Id: <userId>
```

#### Response
- Trả về OrderResponse chi tiết

---

### 3.3 Lấy danh sách đơn hàng của user

#### Endpoint
```
GET /api/orders
Header: X-User-Id: <userId>
```

#### Response
```json
[
  {
    "id": "order-1",
    "totalAmount": 50000000,
    "status": "PENDING",
    "paymentMethod": "CASH",
    "receiverName": "Nguyễn Văn B",
    "receiverPhone": "0987654321",
    "deliveryLocation": "123 Đường ABC, Quận 1, TPHCM",
    "notes": "Giao hàng vào buổi tối",
    "items": [...],
    "createdAt": "2024-06-15T15:30:00"
  }
]
```

---

## Enums

### PaymentMethod
- `CASH` - Thanh toán bằng tiền mặt
- `BANK_TRANSFER` - Chuyển khoản ngân hàng

### OrderStatus
- `PENDING` - Chờ xác nhận
- `CONFIRMED` - Đã xác nhận
- `SHIPPED` - Đang giao
- `DELIVERED` - Đã giao
- `CANCELLED` - Đã hủy

### ProductCondition
- `NEW` - Mới
- `LIKE_NEW` - Như mới
- `USED` - Đã sử dụng

### ProductStatus
- `AVAILABLE` - Có sẵn
- `SOLD_OUT` - Hết hàng

---

## Database Schema

### Tables
1. **products** - Sản phẩm
2. **categories** - Danh mục sản phẩm
3. **product_images** - Hình ảnh sản phẩm
4. **carts** - Giỏ hàng (1 giỏ/user)
5. **cart_items** - Chi tiết giỏ hàng
6. **orders** - Đơn hàng
7. **order_items** - Chi tiết đơn hàng

### Relationships
```
User 1---∞ Cart (1-1, unique)
User 1---∞ Order
Cart 1---∞ CartItem
Product 1---∞ CartItem
Product 1---∞ OrderItem
Order 1---∞ OrderItem
Category 1---∞ Product
User 1---∞ Product (as seller)
Product 1---∞ ProductImage
```

---

## Future Enhancements
1. Integration with Authentication & Authorization
2. Add pagination for orders and cart items
3. Add product search and filter
4. Add order status tracking and notifications
5. Add payment gateway integration (Stripe, Zalopay, etc.)
6. Add reviews and ratings
7. Add order cancellation and return management
8. Add inventory management
