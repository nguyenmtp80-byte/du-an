# Test Cases & API Examples

## Setup Test Data

Trước khi test, cần tạo test data:

```sql
-- Users
INSERT INTO users (id, email, full_name, avatar_url, phone, student_id, created_at)
VALUES 
  ('user-1', 'seller@example.com', 'Nguyễn Văn Seller', 'https://example.com/seller.jpg', '0123456789', 'S001', NOW()),
  ('user-2', 'buyer@example.com', 'Nguyễn Văn Buyer', 'https://example.com/buyer.jpg', '0987654321', 'S002', NOW());

-- Categories
INSERT INTO categories (id, name, description, created_at)
VALUES 
  ('cat-1', 'Điện tử', 'Các sản phẩm điện tử', NOW());

-- Products
INSERT INTO products (id, name, description, price, category_id, condition, status, seller_id, created_at, updated_at)
VALUES 
  ('prod-1', 'iPhone 15 Pro', 'iPhone 15 Pro màu đen', 25000000, 'cat-1', 'NEW', 'AVAILABLE', 'user-1', NOW(), NOW()),
  ('prod-2', 'MacBook Pro', 'MacBook Pro 14 inch', 50000000, 'cat-1', 'LIKE_NEW', 'AVAILABLE', 'user-1', NOW(), NOW()),
  ('prod-3', 'iPad Air', 'iPad Air đã sử dụng', 15000000, 'cat-1', 'USED', 'SOLD_OUT', 'user-1', NOW(), NOW());

-- Product Images
INSERT INTO product_images (id, product_id, image_url, display_order, created_at)
VALUES 
  ('img-1', 'prod-1', 'https://example.com/iphone1.jpg', 1, NOW()),
  ('img-2', 'prod-1', 'https://example.com/iphone2.jpg', 2, NOW()),
  ('img-3', 'prod-2', 'https://example.com/macbook1.jpg', 1, NOW());
```

---

## Test Cases

### 1. Product Detail API

#### Test 1.1: Get Valid Product
```bash
curl -X GET "http://localhost:8080/api/products/prod-1" \
  -H "Content-Type: application/json"
```

**Expected Response** (200 OK):
```json
{
  "id": "prod-1",
  "name": "iPhone 15 Pro",
  "description": "iPhone 15 Pro màu đen",
  "price": 25000000,
  "categoryName": "Điện tử",
  "condition": "NEW",
  "status": "AVAILABLE",
  "images": [
    {
      "id": "img-1",
      "imageUrl": "https://example.com/iphone1.jpg",
      "displayOrder": 1
    },
    {
      "id": "img-2",
      "imageUrl": "https://example.com/iphone2.jpg",
      "displayOrder": 2
    }
  ],
  "seller": {
    "id": "user-1",
    "fullName": "Nguyễn Văn Seller",
    "email": "seller@example.com",
    "phone": "0123456789",
    "avatarUrl": "https://example.com/seller.jpg"
  },
  "createdAt": "2024-06-15T10:00:00"
}
```

#### Test 1.2: Get Invalid Product
```bash
curl -X GET "http://localhost:8080/api/products/invalid-id" \
  -H "Content-Type: application/json"
```

**Expected Response** (400 Bad Request):
```json
{
  "message": "Sản phẩm không tồn tại"
}
```

---

### 2. Shopping Cart API

#### Test 2.1: Add Product to Cart
```bash
curl -X POST "http://localhost:8080/api/cart/add" \
  -H "Content-Type: application/json" \
  -H "X-User-Id: user-2" \
  -d '{
    "productId": "prod-1",
    "quantity": 1
  }'
```

**Expected Response** (200 OK):
```json
{
  "cartId": "cart-1",
  "items": [
    {
      "id": "cart-item-1",
      "productId": "prod-1",
      "productName": "iPhone 15 Pro",
      "productPrice": 25000000,
      "productImage": "https://example.com/iphone1.jpg",
      "quantity": 1,
      "subtotal": 25000000
    }
  ],
  "totalItems": 1,
  "totalAmount": 25000000
}
```

#### Test 2.2: Add Same Product Again (Should Increase Quantity)
```bash
curl -X POST "http://localhost:8080/api/cart/add" \
  -H "Content-Type: application/json" \
  -H "X-User-Id: user-2" \
  -d '{
    "productId": "prod-1",
    "quantity": 2
  }'
```

**Expected Response** (200 OK):
```json
{
  "cartId": "cart-1",
  "items": [
    {
      "id": "cart-item-1",
      "productId": "prod-1",
      "productName": "iPhone 15 Pro",
      "productPrice": 25000000,
      "productImage": "https://example.com/iphone1.jpg",
      "quantity": 3,  // 1 + 2 = 3
      "subtotal": 75000000  // 25000000 * 3
    }
  ],
  "totalItems": 1,
  "totalAmount": 75000000
}
```

#### Test 2.3: Add SOLD_OUT Product (Should Fail)
```bash
curl -X POST "http://localhost:8080/api/cart/add" \
  -H "Content-Type: application/json" \
  -H "X-User-Id: user-2" \
  -d '{
    "productId": "prod-3",
    "quantity": 1
  }'
```

**Expected Response** (400 Bad Request):
```json
{
  "message": "Sản phẩm đã hết hàng"
}
```

#### Test 2.4: Add with Invalid Quantity (Should Fail)
```bash
curl -X POST "http://localhost:8080/api/cart/add" \
  -H "Content-Type: application/json" \
  -H "X-User-Id: user-2" \
  -d '{
    "productId": "prod-2",
    "quantity": 0
  }'
```

**Expected Response** (400 Bad Request):
```json
{
  "message": "Số lượng phải lớn hơn 0"
}
```

#### Test 2.5: Add Another Product
```bash
curl -X POST "http://localhost:8080/api/cart/add" \
  -H "Content-Type: application/json" \
  -H "X-User-Id: user-2" \
  -d '{
    "productId": "prod-2",
    "quantity": 1
  }'
```

**Expected Response** (200 OK):
```json
{
  "cartId": "cart-1",
  "items": [
    {
      "id": "cart-item-1",
      "productId": "prod-1",
      "productName": "iPhone 15 Pro",
      "productPrice": 25000000,
      "productImage": "https://example.com/iphone1.jpg",
      "quantity": 3,
      "subtotal": 75000000
    },
    {
      "id": "cart-item-2",
      "productId": "prod-2",
      "productName": "MacBook Pro",
      "productPrice": 50000000,
      "productImage": "https://example.com/macbook1.jpg",
      "quantity": 1,
      "subtotal": 50000000
    }
  ],
  "totalItems": 2,
  "totalAmount": 125000000  // 75000000 + 50000000
}
```

#### Test 2.6: Get Cart
```bash
curl -X GET "http://localhost:8080/api/cart" \
  -H "X-User-Id: user-2"
```

**Expected Response** (200 OK):
```json
{
  "cartId": "cart-1",
  "items": [
    {
      "id": "cart-item-1",
      "productId": "prod-1",
      "productName": "iPhone 15 Pro",
      "productPrice": 25000000,
      "productImage": "https://example.com/iphone1.jpg",
      "quantity": 3,
      "subtotal": 75000000
    },
    {
      "id": "cart-item-2",
      "productId": "prod-2",
      "productName": "MacBook Pro",
      "productPrice": 50000000,
      "productImage": "https://example.com/macbook1.jpg",
      "quantity": 1,
      "subtotal": 50000000
    }
  ],
  "totalItems": 2,
  "totalAmount": 125000000
}
```

#### Test 2.7: Update Cart Item Quantity
```bash
curl -X PUT "http://localhost:8080/api/cart/update" \
  -H "Content-Type: application/json" \
  -H "X-User-Id: user-2" \
  -d '{
    "cartItemId": "cart-item-2",
    "quantity": 2
  }'
```

**Expected Response** (200 OK):
```json
{
  "cartId": "cart-1",
  "items": [
    {
      "id": "cart-item-1",
      "productId": "prod-1",
      "productName": "iPhone 15 Pro",
      "productPrice": 25000000,
      "productImage": "https://example.com/iphone1.jpg",
      "quantity": 3,
      "subtotal": 75000000
    },
    {
      "id": "cart-item-2",
      "productId": "prod-2",
      "productName": "MacBook Pro",
      "productPrice": 50000000,
      "productImage": "https://example.com/macbook1.jpg",
      "quantity": 2,  // Updated
      "subtotal": 100000000  // 50000000 * 2
    }
  ],
  "totalItems": 2,
  "totalAmount": 175000000  // 75000000 + 100000000
}
```

#### Test 2.8: Remove from Cart
```bash
curl -X DELETE "http://localhost:8080/api/cart/cart-item-1" \
  -H "X-User-Id: user-2"
```

**Expected Response** (200 OK):
```json
{
  "cartId": "cart-1",
  "items": [
    {
      "id": "cart-item-2",
      "productId": "prod-2",
      "productName": "MacBook Pro",
      "productPrice": 50000000,
      "productImage": "https://example.com/macbook1.jpg",
      "quantity": 2,
      "subtotal": 100000000
    }
  ],
  "totalItems": 1,
  "totalAmount": 100000000  // Updated
}
```

---

### 3. Order (Checkout) API

#### Test 3.1: Create Order (Success)
```bash
curl -X POST "http://localhost:8080/api/orders/create" \
  -H "Content-Type: application/json" \
  -H "X-User-Id: user-2" \
  -d '{
    "paymentMethod": "CASH",
    "deliveryInfo": {
      "receiverName": "Nguyễn Văn Receiver",
      "receiverPhone": "0912345678",
      "deliveryLocation": "123 Đường ABC, Quận 1, TPHCM",
      "notes": "Giao hàng vào buổi tối"
    }
  }'
```

**Expected Response** (200 OK):
```json
{
  "message": "Tạo đơn hàng thành công",
  "data": {
    "id": "order-1",
    "totalAmount": 100000000,
    "status": "PENDING",
    "paymentMethod": "CASH",
    "receiverName": "Nguyễn Văn Receiver",
    "receiverPhone": "0912345678",
    "deliveryLocation": "123 Đường ABC, Quận 1, TPHCM",
    "notes": "Giao hàng vào buổi tối",
    "items": [
      {
        "id": "order-item-1",
        "productId": "prod-2",
        "productName": "MacBook Pro",
        "quantity": 2,
        "unitPrice": 50000000,
        "subtotal": 100000000
      }
    ],
    "createdAt": "2024-06-15T15:30:00"
  }
}
```

**Side Effect**: Cart được clear
```bash
curl -X GET "http://localhost:8080/api/cart" \
  -H "X-User-Id: user-2"
```

Response sẽ trả về:
```json
{
  "cartId": "cart-1",
  "items": [],  // Empty after order
  "totalItems": 0,
  "totalAmount": 0
}
```

#### Test 3.2: Create Order with Empty Cart (Should Fail)
```bash
curl -X POST "http://localhost:8080/api/orders/create" \
  -H "Content-Type: application/json" \
  -H "X-User-Id: user-2" \
  -d '{
    "paymentMethod": "CASH",
    "deliveryInfo": {
      "receiverName": "Nguyễn Văn Receiver",
      "receiverPhone": "0912345678",
      "deliveryLocation": "123 Đường ABC, Quận 1, TPHCM",
      "notes": ""
    }
  }'
```

**Expected Response** (400 Bad Request):
```json
{
  "message": "Giỏ hàng trống, không thể tạo đơn hàng"
}
```

#### Test 3.3: Create Order with Invalid Payment Method (Should Fail)
```bash
curl -X POST "http://localhost:8080/api/orders/create" \
  -H "Content-Type: application/json" \
  -H "X-User-Id: user-2" \
  -d '{
    "paymentMethod": "CREDIT_CARD",
    "deliveryInfo": {
      "receiverName": "Nguyễn Văn Receiver",
      "receiverPhone": "0912345678",
      "deliveryLocation": "123 Đường ABC, Quận 1, TPHCM",
      "notes": ""
    }
  }'
```

**Expected Response** (400 Bad Request):
```json
{
  "message": "Phương thức thanh toán không hợp lệ"
}
```

#### Test 3.4: Get Order Detail
```bash
curl -X GET "http://localhost:8080/api/orders/order-1" \
  -H "X-User-Id: user-2"
```

**Expected Response** (200 OK):
```json
{
  "id": "order-1",
  "totalAmount": 100000000,
  "status": "PENDING",
  "paymentMethod": "CASH",
  "receiverName": "Nguyễn Văn Receiver",
  "receiverPhone": "0912345678",
  "deliveryLocation": "123 Đường ABC, Quận 1, TPHCM",
  "notes": "Giao hàng vào buổi tối",
  "items": [
    {
      "id": "order-item-1",
      "productId": "prod-2",
      "productName": "MacBook Pro",
      "quantity": 2,
      "unitPrice": 50000000,
      "subtotal": 100000000
    }
  ],
  "createdAt": "2024-06-15T15:30:00"
}
```

#### Test 3.5: Get User Orders
```bash
curl -X GET "http://localhost:8080/api/orders" \
  -H "X-User-Id: user-2"
```

**Expected Response** (200 OK):
```json
[
  {
    "id": "order-1",
    "totalAmount": 100000000,
    "status": "PENDING",
    "paymentMethod": "CASH",
    "receiverName": "Nguyễn Văn Receiver",
    "receiverPhone": "0912345678",
    "deliveryLocation": "123 Đường ABC, Quận 1, TPHCM",
    "notes": "Giao hàng vào buổi tối",
    "items": [...],
    "createdAt": "2024-06-15T15:30:00"
  }
]
```

---

## Test Scenarios

### Scenario 1: Normal Flow
1. ✅ Get product detail
2. ✅ Add product to cart
3. ✅ Add another product to cart
4. ✅ Get cart
5. ✅ Update quantity
6. ✅ Create order
7. ✅ Verify cart is empty
8. ✅ Get order detail

### Scenario 2: Error Handling
1. ✅ Get invalid product → 404
2. ✅ Add SOLD_OUT product → 400
3. ✅ Add with invalid quantity → 400
4. ✅ Create order with empty cart → 400
5. ✅ Create order with invalid payment → 400

### Scenario 3: Cart Operations
1. ✅ Add same product twice → quantity increases
2. ✅ Update quantity
3. ✅ Remove item
4. ✅ Verify total recalculated

---

## Postman Collection Format

Create a Postman collection with these endpoints:

```json
{
  "info": {
    "name": "Marketplace API",
    "description": "Product, Cart, and Order APIs"
  },
  "item": [
    {
      "name": "Product",
      "item": [
        {
          "name": "Get Product Detail",
          "request": {
            "method": "GET",
            "url": "{{base_url}}/api/products/prod-1"
          }
        }
      ]
    },
    {
      "name": "Cart",
      "item": [
        {
          "name": "Add to Cart",
          "request": {
            "method": "POST",
            "url": "{{base_url}}/api/cart/add",
            "header": [
              {"key": "X-User-Id", "value": "user-2"}
            ],
            "body": {
              "mode": "raw",
              "raw": "{\"productId\": \"prod-1\", \"quantity\": 1}"
            }
          }
        }
      ]
    },
    {
      "name": "Order",
      "item": [
        {
          "name": "Create Order",
          "request": {
            "method": "POST",
            "url": "{{base_url}}/api/orders/create",
            "header": [
              {"key": "X-User-Id", "value": "user-2"}
            ]
          }
        }
      ]
    }
  ]
}
```

---

## Notes

- Thay `{{base_url}}` bằng `http://localhost:8080`
- Header `X-User-Id` là tạm thời, sau sẽ integrate Auth
- Tất cả số tiền tính bằng VND (Đồng Việt Nam)
- Timestamps sử dụng ISO 8601 format
