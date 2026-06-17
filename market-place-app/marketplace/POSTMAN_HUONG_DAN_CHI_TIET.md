# 📘 Hướng Dẫn Postman Chi Tiết Từng Bước

## 📌 Cách tạo Request trong Postman

---

## Bước 1: Tạo Request mới

Mở **Postman** → Click nút **"New"** (hoặc **"+"** ở tab bar) → Chọn **"HTTP Request"**

---

## Bước 2: Nhập thông tin cho API Product Detail

### 🟢 Test 1.1: GET Product Detail

| Trường | Giá trị |
|--------|---------|
| **Method** | `GET` (chọn từ dropdown) |
| **URL** | `http://localhost:8080/api/products/prod-1` |
| **Headers** | Không cần header gì thêm |

**Các bước làm trên Postman:**

1. **Method**: Click dropdown (mặc định là GET) → chọn **GET**
2. **URL**: Gõ `http://localhost:8080/api/products/prod-1` vào ô URL
3. **Headers**: Để trống, không cần thêm gì
4. **Body**: Chọn **"none"** (vì là GET request)
5. Click **"Send"**

📸 **Minh họa:**
```
[GET] ▼  http://localhost:8080/api/products/prod-1          [Send]
─────────────────────────────────────────────────────────
Headers | Body (none) | Params
```

---

## Bước 3: Test Cart APIs (cần Header X-User-Id)

### 🟢 Test 2.1: Thêm sản phẩm vào giỏ hàng

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

| STT | Method | URL | Header | Body |
|-----|--------|-----|--------|------|
| 1 | GET | `/api/products/prod-1` | — | — |
| 2 | POST | `/api/cart/add` | X-User-Id: user-2 | `{"productId":"prod-1","quantity":1}` |
| 3 | POST | `/api/cart/add` | X-User-Id: user-2 | `{"productId":"prod-1","quantity":2}` |
| 4 | POST | `/api/cart/add` | X-User-Id: user-2 | `{"productId":"prod-3","quantity":1}` (lỗi) |
| 5 | POST | `/api/cart/add` | X-User-Id: user-2 | `{"productId":"prod-2","quantity":1}` |
| 6 | GET | `/api/cart` | X-User-Id: user-2 | — |
| 7 | PUT | `/api/cart/update` | X-User-Id: user-2 | `{"cartItemId":"...","quantity":2}` |
| 8 | DELETE | `/api/cart/{cartItemId}` | X-User-Id: user-2 | — |
| 9 | POST | `/api/orders/create` | X-User-Id: user-2 | Xem ở trên |
| 10 | GET | `/api/cart` | X-User-Id: user-2 | — (kiểm tra giỏ trống) |
| 11 | GET | `/api/orders/{orderId}` | X-User-Id: user-2 | — |
| 12 | GET | `/api/orders` | X-User-Id: user-2 | — |