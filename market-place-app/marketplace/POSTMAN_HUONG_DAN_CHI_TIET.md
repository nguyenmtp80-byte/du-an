# 📘 Hướng Dẫn Postman Chi Tiết Từng Bước

## 📌 Cách tạo Request trong Postman

---

## Bước 1: Tạo Request mới

Mở **Postman** → Click nút **"New"** (hoặc **"+"** ở tab bar) → Chọn **"HTTP Request"**

---

## Bước 2: Test API danh sách sản phẩm (vừa code)

### 🟢 Test 1.1: GET tất cả sản phẩm

| Trường | Giá trị |
|--------|---------|
| **Method** | `GET` |
| **URL** | `http://localhost:8080/api/products` |
| **Headers** | Không cần |
| **Body** | none |

**Các bước làm trên Postman:**

1. **Method**: Chọn **GET**
2. **URL**: Gõ `http://localhost:8080/api/products`
3. **Headers**: Để trống
4. **Body**: Chọn **"none"**
5. Click **"Send"**

**Kết quả mong đợi (200 OK):**
```json
[
    {
        "id": "prod-1",
        "name": "iPhone 15 Pro",
        "description": "iPhone 15 Pro mới 99%",
        "price": 25000000,
        "imageUrls": ["https://example.com/iphone1.jpg", "https://example.com/iphone2.jpg"],
        "category": "Điện tử",
        "status": "AVAILABLE",
        "locationName": "Sảnh A",
        "seller": {
            "id": "user-1",
            "fullName": "Nguyễn Văn A",
            "email": "nguyenvana@fpt.edu.vn",
            "phone": "0909123456",
            "avatarUrl": null
        },
        "createdAt": "2025-06-01T10:00:00"
    }
]
```

📸 **Minh họa:**
```
[GET] ▼  http://localhost:8080/api/products                  [Send]
─────────────────────────────────────────────────────────
Params ▼  | Headers | Body (none)
```

---

### 🟢 Test 1.2: GET sản phẩm theo từ khóa (search)

| Trường | Giá trị |
|--------|---------|
| **Method** | `GET` |
| **URL** | `http://localhost:8080/api/products?search=iphone` |
| **Headers** | Không cần |
| **Body** | none |

**Cách nhập Query Params trong Postman:**
1. Click tab **"Params"** (bên dưới URL)
2. Thêm dòng sau vào bảng params:

| Key | Value | Description |
|-----|-------|-------------|
| `search` | `iphone` | Từ khóa tìm kiếm theo tên sản phẩm |

📸 **Minh họa Params:**
```
Key        Value        Description
─────────────────────────────────────
search ➡  iphone
```

> **Mẹo:** Tab Params tự động thêm `?search=iphone` vào URL cho bạn.

---

### 🟢 Test 1.3: GET sản phẩm theo danh mục (category)

| Trường | Giá trị |
|--------|---------|
| **Method** | `GET` |
| **URL** | `http://localhost:8080/api/products?category=Điện%20tử` |
| **Params** | `category` = `Điện tử` |

**Lưu ý:** Vì có dấu cách và ký tự đặc biệt, bạn nên nhập qua tab **Params** thay vì gõ trực tiếp URL. Postman sẽ tự động encode.

---

### 🟢 Test 1.4: GET sản phẩm còn hàng (status)

| Trường | Giá trị |
|--------|---------|
| **Method** | `GET` |
| **URL** | `http://localhost:8080/api/products?status=available` |
| **Params** | `status` = `available` |

**Giá trị status có thể dùng:** `available` (còn hàng), `sold` (đã bán)

---

### 🟢 Test 1.5: GET sản phẩm theo khoảng giá

| Trường | Giá trị |
|--------|---------|
| **Method** | `GET` |
| **URL** | `http://localhost:8080/api/products?minPrice=1000000&maxPrice=10000000` |
| **Params** | `minPrice` = `1000000`, `maxPrice` = `10000000` |

---

### 🟢 Test 1.6: GET sản phẩm với nhiều bộ lọc kết hợp

| Trường | Giá trị |
|--------|---------|
| **Method** | `GET` |
| **URL** | `http://localhost:8080/api/products?search=laptop&category=Điện%20tử&status=available&minPrice=5000000&maxPrice=30000000` |
| **Params** | Xem bảng dưới |

**Nhập vào tab Params:**

| Key | Value |
|-----|-------|
| `search` | `laptop` |
| `category` | `Điện tử` |
| `status` | `available` |
| `minPrice` | `5000000` |
| `maxPrice` | `30000000` |

Postman sẽ tự động tạo URL: `http://localhost:8080/api/products?search=laptop&category=%C4%90i%E1%BB%87n%20t%E1%BB%AD&status=available&minPrice=5000000&maxPrice=30000000`

---

### 🟢 Test 1.7: GET chi tiết sản phẩm (API cũ)

| Trường | Giá trị |
|--------|---------|
| **Method** | `GET` |
| **URL** | `http://localhost:8080/api/products/prod-1` |
| **Headers** | Không cần |
| **Body** | none |

---

## Bước 3: Test Cart APIs (cần Header X-User-Id)

### � Test 2.1: Thêm sản phẩm vào giỏ hàng

| Trường | Giá trị |
|--------|---------|
| **Method** | `POST` |
| **URL** | `http://localhost:8080/api/cart/add` |
| **Headers** | `Content-Type: application/json` và `X-User-Id: user-2` |
| **Body** | raw JSON như bên dưới |

**Các bước chi tiết:**

**Bước 2.1a - Chọn Method và nhập URL:**
```
[POST] ▼  http://localhost:8080/api/cart/add                [Send]
```

**Bước 2.1b - Thêm Headers:**
- Click tab **"Headers"** (bên dưới URL)
- Thêm 2 dòng:

| Key | Value |
|-----|-------|
| `Content-Type` | `application/json` |
| `X-User-Id` | `user-2` |

📸 **Minh họa Headers:**
```
Key                    Value
─────────────────────────────────────
Content-Type    ➡     application/json
X-User-Id       ➡     user-2
```

**Bước 2.1c - Nhập Body:**
- Click tab **"Body"**
- Chọn **"raw"** (radio button)
- Chọn **"JSON"** từ dropdown bên cạnh
- Copy-paste đoạn JSON sau vào ô text:

```json
{
    "productId": "prod-1",
    "quantity": 1
}
```

📸 **Minh họa Body:**
```
○ none  ○ form-data  ○ x-www-form-urlencoded  ○ raw  ○ binary
                                                       ▼ JSON ▼
{
    "productId": "prod-1",
    "quantity": 1
}
```

**Bước 2.1d - Click "Send"**

**Kết quả mong đợi (200 OK):**
```json
{
    "userId": "user-2",
    "items": [
        {
            "cartId": "cart-...",
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

---

### 🟢 Test 2.2: Thêm sản phẩm đã có (tăng quantity)

Giữ nguyên request như **2.1**, chỉ sửa **Body**:

```json
{
    "productId": "prod-1",
    "quantity": 2
}
```

Kết quả: quantity tăng từ `1` lên `3`, subtotal = `75.000.000`

---

### 🟢 Test 2.3: Thêm sản phẩm đã bán (lỗi)

Giữ nguyên Headers, chỉ sửa **Body**:

```json
{
    "productId": "prod-3",
    "quantity": 1
}
```

Kết quả: `400 Bad Request` với message `"Sản phẩm đã hết hàng"`

---

### 🟢 Test 2.6: Lấy giỏ hàng

| Trường | Giá trị |
|--------|---------|
| **Method** | `GET` |
| **URL** | `http://localhost:8080/api/cart` |
| **Headers** | `X-User-Id: user-2` |
| **Body** | none |

**Chú ý:** Header `Content-Type` không cần thiết cho GET request.

---

## Bước 4: Test Order APIs

### 🟢 Test 3.1: Tạo đơn hàng

| Trường | Giá trị |
|--------|---------|
| **Method** | `POST` |
| **URL** | `http://localhost:8080/api/orders/create` |
| **Headers** | `Content-Type: application/json` + `X-User-Id: user-2` |
| **Body** | raw JSON |

**Body:**
```json
{
    "paymentMethod": "CASH",
    "deliveryInfo": {
        "receiverName": "Nguyễn Văn Buyer",
        "receiverPhone": "0987654321",
        "deliveryLocation": "Sảnh tòa Alpha, ĐH FPT",
        "notes": "Hẹn gặp lúc 10h sáng"
    }
}
```

---

## ⚡ Mẹo: Dùng Postman Variables

Để không phải gõ URL dài mỗi lần:

1. Click **"Environments"** (bên trái) → **"Add"**
2. Tạo biến: `base_url` = `http://localhost:8080`
3. Trong request URL, gõ: `{{base_url}}/api/products/prod-1`

---

## 🎯 Tóm tắt nhanh các API để test

| STT | Method | URL | Header | Body / Ghi chú |
|-----|--------|-----|--------|----------------|
| 1 | GET | `/api/products` | — | Lấy tất cả sản phẩm |
| 2 | GET | `/api/products?search=iphone` | — | Tìm theo từ khóa |
| 3 | GET | `/api/products?category=Điện%20tử` | — | Lọc theo danh mục |
| 4 | GET | `/api/products?status=available` | — | Lọc theo trạng thái |
| 5 | GET | `/api/products?minPrice=1000000&maxPrice=10000000` | — | Lọc theo khoảng giá |
| 6 | GET | `/api/products/prod-1` | — | Chi tiết sản phẩm |
| 7 | POST | `/api/cart/add` | X-User-Id: user-2 | `{"productId":"prod-1","quantity":1}` |
| 8 | POST | `/api/cart/add` | X-User-Id: user-2 | `{"productId":"prod-1","quantity":2}` |
| 9 | POST | `/api/cart/add` | X-User-Id: user-2 | `{"productId":"prod-3","quantity":1}` (lỗi) |
| 10 | POST | `/api/cart/add` | X-User-Id: user-2 | `{"productId":"prod-2","quantity":1}` |
| 11 | GET | `/api/cart` | X-User-Id: user-2 | — |
| 12 | PUT | `/api/cart/update` | X-User-Id: user-2 | `{"cartItemId":"...","quantity":2}` |
| 13 | DELETE | `/api/cart/{cartItemId}` | X-User-Id: user-2 | — |
| 14 | POST | `/api/orders/create` | X-User-Id: user-2 | Xem ở trên |
| 15 | GET | `/api/cart` | X-User-Id: user-2 | — (kiểm tra giỏ trống) |
| 16 | GET | `/api/orders/{orderId}` | X-User-Id: user-2 | — |
| 17 | GET | `/api/orders` | X-User-Id: user-2 | — |
