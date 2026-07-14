# Student Marketplace

Ứng dụng **mua bán đồ dành cho sinh viên** trong campus, xây dựng bằng **Flutter** (Android) và kết nối **REST API** backend Spring Boot.

**API production:** `https://marketplace-production-5909.up.railway.app/api`

---

## Thành viên

- Lê Vũ Văn
- Trương Lê Trí Nguyên
- Trần Phương Nam

---

## Cấu trúc project

```
lib/
├── main.dart                 # Entry point, MultiProvider, MaterialApp
├── core/
│   ├── constants/            # AppStrings, AppRoutes, AppSizes, AppColors, ApiConfig
│   ├── routes/               # AppRouter — điều hướng named routes
│   ├── themes/               # AppTheme
│   └── widgets/              # StateViews dùng chung (loading, empty, error)
├── models/                   # User, Product, CartItem, Order, Chat, Notification...
├── providers/                # State management (Provider)
│   ├── auth_provider.dart
│   ├── product_provider.dart
│   ├── cart_provider.dart
│   └── notification_provider.dart
├── repositories/             # Tầng trung gian gọi API + cache session
│   ├── auth_repository.dart
│   ├── product_repository.dart
│   └── order_repository.dart
├── services/                 # Gọi HTTP qua ApiClient
├── screens/                  # Màn hình theo nghiệp vụ
│   ├── auth/                 # Login, Register, Forgot/Reset password
│   ├── home/                 # Danh sách sản phẩm, search, filter
│   ├── product/              # Chi tiết sản phẩm
│   ├── cart/                 # Giỏ hàng
│   ├── checkout/             # Đặt hàng, thanh toán QR
│   ├── sell/                 # Đăng bán sản phẩm
│   ├── chat/                 # Nhắn tin mua–bán
│   ├── notifications/        # Thông báo
│   ├── profile/              # Hồ sơ, đơn hàng, listing
│   └── shell/                # Bottom navigation + FAB đăng bán
├── widgets/                  # Widget tái sử dụng (ProductCard, ScreenHeader...)
└── utils/                    # Validators, formatters, helpers
```

### Nguyên tắc tổ chức code

| Tầng | Trách nhiệm |
|------|-------------|
| **Screen** | Hiển thị UI, nhận thao tác người dùng |
| **Provider** | Quản lý state, cập nhật UI khi dữ liệu đổi |
| **Repository** | Gom logic nghiệp vụ, gọi service, lưu session |
| **Service** | Gọi REST API, parse JSON → Model |
| **Model** | Định nghĩa dữ liệu có cấu trúc |

Widget con của màn hình lớn được tách vào `screens/<feature>/widgets/` (dùng `part` file) để `build()` gọn và dễ đọc.

---

## Quy trình chạy ứng dụng

### Cài đặt

```bash
cd frontend
flutter pub get
```

### Chạy trên emulator / thiết bị thật

```bash
flutter run
```

### Build APK release (kết nối API production)

```bash
flutter build apk --release
```

File output: `build/app/outputs/flutter-apk/app-release.apk`

> App đã cấu hình sẵn URL production trong `lib/core/constants/api_config.dart`. Không cần chạy backend local khi test APK.

### Chạy trên Chrome (dev)

```bash
flutter run -d chrome --web-browser-flag=--disable-web-security --web-browser-flag=--user-data-dir=C:/temp/flutter_chrome_dev
```

---

## Nghiệp vụ chính

### 1. Xác thực (Auth)

- **Đăng nhập** email + mật khẩu, validate form, lưu session (`SharedPreferences`)
- **Đăng ký** kèm xác thực **OTP email** trước khi tạo tài khoản
- **Quên mật khẩu** → OTP → đặt lại mật khẩu
- **Đăng nhập Google** (có fallback sandbox khi SDK lỗi trên thiết bị chưa cấu hình OAuth)

### 2. Sản phẩm (Product)

- Danh sách sản phẩm từ API, hiển thị grid
- **Tìm kiếm** theo tên, **lọc** theo danh mục / giá / tình trạng
- **Chi tiết sản phẩm**: ảnh, giá, mô tả, người bán, điểm gặp
- **Yêu thích** (lưu local), **Chat** người bán, **Thêm giỏ hàng**

### 3. Đăng bán (Sell)

- Form đăng sản phẩm: ảnh (upload API), tên, giá, danh mục, tình trạng, mô tả
- Chọn **điểm giao dịch** trên bản đồ (campus location)
- Sau khi đăng, sản phẩm xuất hiện trên Home

### 4. Giỏ hàng & Đặt hàng (Cart / Checkout)

- Xem, tăng/giảm số lượng, xóa, tính tổng tiền
- Checkout: thông tin nhận hàng, điểm gặp, ghi chú
- **Thanh toán tiền mặt** hoặc **chuyển khoản QR** (VietQR demo)

### 5. Thanh toán QR

```
PENDING → (Buyer: "Tôi đã chuyển khoản") → PAID
       → (Seller: "Xác nhận đã nhận tiền") → APPROVED
       → (Seller: "Hoàn tất đơn") → COMPLETED
```

Luồng **tiền mặt**: Seller **Xác nhận đơn** trực tiếp từ `PENDING` → `APPROVED`.

Buyer có thể **huỷ đơn** khi trạng thái còn `PENDING`.

### 6. Chat

- Nhắn tin giữa người mua và người bán theo sản phẩm
- Lịch sử chat, badge tin chưa đọc

### 7. Thông báo (Notifications)

- Thông báo đơn hàng, trạng thái đã đọc/chưa đọc
- Bấm thông báo → mở chi tiết đơn hàng

### 8. Hồ sơ (Profile)

- Thống kê: đã bán, đã mua, chờ xác nhận
- **Đơn hàng mua** / **Đơn hàng đã bán** / **Sản phẩm đăng bán**
- Trung tâm trợ giúp, đăng xuất

---

## State management

Dùng **Provider** (`ChangeNotifier`):

| Provider | Quản lý |
|----------|---------|
| `AuthProvider` | Login/logout, user session |
| `ProductProvider` | Danh sách SP, search, filter, yêu thích |
| `CartProvider` | Giỏ hàng, badge số lượng |
| `NotificationProvider` | Số thông báo chưa đọc |

Ví dụ: thêm giỏ hàng → `CartProvider` cập nhật → badge bottom bar đổi ngay, không cần reload màn hình.

---

## Điều hướng (Navigation)

Named routes khai báo tại `AppRoutes`, xử lý tại `AppRouter`:

| Route | Màn hình |
|-------|----------|
| `/` | AuthGate (kiểm tra session) |
| `/login`, `/register` | Auth |
| `/main` | MainShell (Home, Cart, Chat, Profile) |
| `/sell` | Đăng bán |
| `/product-detail` | Chi tiết SP |
| `/checkout`, `/payment-qr` | Đặt hàng, QR |
| `/my-orders`, `/sold-orders` | Quản lý đơn |
| `/chat`, `/notifications` | Chat, thông báo |

---

## Backend & dữ liệu

- **Backend:** Spring Boot + PostgreSQL, deploy Railway
- **Entities:** User, Product, Cart, Order, Notification, Chat, Campus Location
- Flutter gọi REST API qua `ApiClient`, dữ liệu parse thành **Model class** (không dùng `Map` tùy tiện)

---

## Tài liệu tham khảo

- [Flutter documentation](https://docs.flutter.dev/)
