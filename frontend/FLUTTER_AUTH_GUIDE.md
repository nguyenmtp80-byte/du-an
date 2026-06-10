# Hướng dẫn Flutter — Tính năng Login / Register / Logout

Tài liệu này giải thích code Flutter trong dự án **Student Marketplace** cho người mới học Flutter.

---

## 1. Flutter hoạt động như thế nào?

Flutter dùng ngôn ngữ **Dart**. Mọi thứ hiển thị trên màn hình đều là **Widget** (nút, text, form, màn hình...).

```
main() → runApp() → MaterialApp → Màn hình (Screen)
```

- **`main.dart`**: Điểm bắt đầu của app.
- **`MaterialApp`**: Khung app (theme, routing, title).
- **Screen**: Mỗi màn hình là một widget lớn.

### StatefulWidget vs StatelessWidget

| Loại | Khi nào dùng |
|------|--------------|
| **StatelessWidget** | UI không đổi theo thời gian (nút, text tĩnh) |
| **StatefulWidget** | UI thay đổi (form nhập, loading, toggle) |

Ví dụ `LoginScreen` là **StatefulWidget** vì có `TextEditingController` lưu text người dùng gõ.

---

## 2. Cấu trúc thư mục `lib/`

```
lib/
├── main.dart                 # Khởi chạy app
├── config/
│   └── api_config.dart       # URL backend Spring Boot
├── models/
│   ├── user.dart             # Model người dùng
│   └── auth_response.dart    # Model phản hồi login/register
├── providers/
│   └── auth_provider.dart    # Quản lý trạng thái đăng nhập
├── repositories/
│   └── auth_repository.dart  # Gọi API + lưu session
├── services/
│   ├── api_client.dart       # HTTP client
│   └── auth_api_service.dart # Endpoint auth Spring Boot
├── screens/
│   ├── auth/
│   │   ├── auth_gate.dart    # Chọn màn Login hay Home
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   └── home/
│       └── home_screen.dart  # Màn tạm sau đăng nhập
├── theme/
│   └── app_theme.dart        # Màu sắc, theme
├── utils/
│   └── validators.dart       # Validate form
└── widgets/                  # Component dùng lại
```

**Tương đương React:**

| Flutter | React |
|---------|-------|
| `screens/` | `pages/` |
| `widgets/` | `components/` |
| `providers/` | `Context` / Redux |
| `services/` | `api/` / `services/` |

---

## 3. State Management với Provider

React dùng `useAppContext()`. Flutter dùng **Provider**.

### Cách hoạt động

1. `AuthProvider` lưu trạng thái: đã đăng nhập chưa, user hiện tại, lỗi, loading...
2. `ChangeNotifierProvider` bọc toàn app trong `main.dart`.
3. Màn hình dùng:
   - `context.watch<AuthProvider>()` → UI tự rebuild khi state đổi
   - `context.read<AuthProvider>()` → Gọi hàm (login, logout) không cần rebuild

```dart
// main.dart
ChangeNotifierProvider(
  create: (_) => AuthProvider()..initialize(),
  child: MaterialApp(...),
)
```

### Luồng đăng nhập

```
LoginScreen bấm "Đăng nhập"
    → auth.login(email, password)
    → AuthRepository gọi API Spring Boot
        → AuthApiService gửi HTTP request
        → Lưu token + user vào SharedPreferences
    → AuthProvider cập nhật isAuthenticated = true
    → AuthGate tự chuyển sang HomeScreen
```

---

## 4. Gọi API Spring Boot (`market-place-app`)

Backend repo: `E:\Git_Push\market-place-app` — chạy tại **port 8080**.

### `api_config.dart`

URL tự chọn theo nền tảng:

| Môi trường | URL |
|------------|-----|
| Windows / iOS Simulator / Web | `http://localhost:8080/api` |
| Android Emulator | `http://10.0.2.2:8080/api` |
| Máy thật (cùng WiFi) | `http://<IP-máy-tính>:8080/api` |

### Endpoints thực tế (Spring Boot)

**POST** `/api/auth/register` → **201 Created**

```json
// Request (camelCase)
{
  "id": "uuid-do-flutter-tu-sinh",
  "email": "student@university.edu",
  "fullName": "Nguyen Van A",
  "phone": "0912345678",
  "studentId": "SV001"
}

// Response
{
  "token": "uuid-token",
  "user": {
    "id": "...",
    "email": "...",
    "fullName": "...",
    "phone": "...",
    "studentId": "...",
    "createdAt": "2026-06-10T14:30:00"
  }
}
```

**POST** `/api/auth/login` → **200 OK**

```json
// Request — backend KHÔNG có trường password
{
  "id": "user-id-hoac-email",
  "email": "student@university.edu"
}
```

**POST** `/api/auth/logout` → **204 No Content**  
Header: `Authorization: Bearer <token>`

### Lưu ý quan trọng

- Backend hiện **chưa xác thực mật khẩu** — chỉ cần `id` + `email` để login.
- Flutter **tự sinh UUID** làm `id` khi đăng ký (`uuid` package).
- Trường mật khẩu trên UI vẫn validate phía client, chờ backend bổ sung sau.
- Token là **UUID** (không phải JWT), lưu in-memory trên server — mất khi restart backend.

### Lỗi từ backend

```json
{
  "timestamp": "...",
  "status": 400,
  "error": "Bad Request",
  "message": "Email đã được sử dụng"
}
```

Flutter đọc field `message` để hiển thị SnackBar.

### `api_client.dart`

- Dùng package `http` gửi request JSON.
- Hỗ trợ response rỗng (204 logout).
- Nếu server không phản hồi → báo lỗi kết nối kèm URL.

---

## 5. Lưu trạng thái đăng nhập

Package **`shared_preferences`** lưu dữ liệu nhỏ trên thiết bị (giống `localStorage` trên web).

`AuthRepository` lưu:
- `auth_token` — token UUID từ backend
- `auth_user` — thông tin user (JSON)

Khi mở app lại:
1. `AuthProvider.initialize()` chạy
2. Kiểm tra có token không
3. Có token → vào `HomeScreen`
4. Không có → vào `LoginScreen`

---

## 6. Form và Validate

### TextEditingController

Giống `useState` cho input trong React:

```dart
final _emailController = TextEditingController();

// Trong widget
AuthTextField(controller: _emailController, ...)

// Lấy giá trị
_emailController.text

// Nhớ dispose khi hủy màn hình
@override
void dispose() {
  _emailController.dispose();
  super.dispose();
}
```

### GlobalKey<FormState>

```dart
if (!_formKey.currentState!.validate()) return;
```

Gọi tất cả `validator` của các `TextFormField`. Nếu có lỗi → dừng submit.

### Validators (`utils/validators.dart`)

| Hàm | Kiểm tra |
|-----|----------|
| `email()` | Không rỗng, đúng format email |
| `password()` | Không rỗng, tối thiểu 6 ký tự |
| `fullName()` | Không rỗng, ít nhất 2 ký tự |
| `phone()` | Số VN hợp lệ (0... hoặc +84...) |
| `confirmPassword()` | Khớp với mật khẩu |

---

## 7. Các màn hình Auth

### `auth_gate.dart`

"Người gác cổng" — quyết định hiển thị màn nào:

```
Đang khởi tạo?     → Loading spinner
Đã đăng nhập?      → HomeScreen
Chưa đăng nhập?    → LoginScreen
```

### `login_screen.dart`

UI tham khảo từ React `Login.tsx`:
- Ảnh minh họa + badge 🛍️
- Tiêu đề "Chào mừng trở lại"
- Email + Mật khẩu
- Nút Đăng nhập (có loading)
- Đăng nhập Google (placeholder — tích hợp sau)
- Link sang Register

**Không có dữ liệu mẫu** trong form — người dùng phải nhập thật.

### `register_screen.dart`

Trang riêng (không toggle như React), thêm các field:
- Họ và tên
- Email sinh viên
- Số điện thoại
- Mật khẩu
- Xác nhận mật khẩu

Đăng ký thành công → tự chuyển về Home.

### `home_screen.dart`

Màn tạm để test logout. Hiển thị tên user và nút **Đăng xuất**.

---

## 8. Widget tái sử dụng

| Widget | Vai trò |
|--------|---------|
| `AuthIllustration` | Ảnh + hiệu ứng blur + emoji |
| `AuthTextField` | Input có icon bên trái |
| `PrimaryButton` | Nút chính màu primary, hỗ trợ loading |
| `GoogleSignInButton` | Nút Google (UI only) |
| `AuthDivider` | Đường kẻ "Hoặc tiếp tục với" |

---

## 9. Theme (`app_theme.dart`)

Màu chính `primary = #4F46E5` (indigo) tương tự Tailwind `primary`.

`AppTheme.light` cấu hình:
- Bo góc input `16px` (tương đương `rounded-2xl`)
- Nền input xám nhạt `gray-50`
- Viền focus màu primary

---

## 10. Cách chạy và test

```bash
cd "e:\Flutter Project\student_marketplace"
flutter pub get
flutter run
```

### Test UI (chưa có backend)

1. Mở app → thấy Login
2. Bấm submit trống → hiện lỗi validate
3. Nhập sai email → hiện lỗi format
4. Nhập đúng form + backend chưa chạy → SnackBar "Không thể kết nối server..."

### Test với backend Spring Boot

1. Backend chạy tại port 8080
2. Sửa `api_config.dart` nếu cần
3. Đăng ký tài khoản mới → vào Home
4. Đóng app mở lại → vẫn đăng nhập (token đã lưu)
5. Bấm Đăng xuất → quay về Login

---

## 11. So sánh React → Flutter

| React (Login.tsx) | Flutter |
|-------------------|---------|
| `useState(email)` | `TextEditingController` |
| `useNavigate()` | `Navigator.push()` / AuthGate tự đổi màn |
| `useAppContext().login()` | `context.read<AuthProvider>().login()` |
| `onSubmit={handleSubmit}` | `PrimaryButton(onPressed: _handleSubmit)` |
| `className="..."` | `style`, `decoration`, `ThemeData` |
| `required` trên input | `validator` trong `TextFormField` |
| `isRegister` toggle | Trang `RegisterScreen` riêng |

---

## 12. Bước tiếp theo

Khi backend ổn định, nhóm có thể:
1. Đồng bộ format JSON request/response nếu khác spec
2. Thêm refresh token
3. Tích hợp Google Sign-In
4. Thay `HomeScreen` bằng `ProductListScreen`

Nếu backend dùng tên field khác (ví dụ `access_token` thay `token`), sửa trong `auth_response.dart` và `user.dart`.
