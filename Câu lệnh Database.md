
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS chat_messages CASCADE;
DROP TABLE IF EXISTS chat_rooms CASCADE;
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS cart CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS categories CASCADE;     -- Xóa bảng thừa này nếu lỡ tạo
DROP TABLE IF EXISTS product_images CASCADE;  -- Xóa bảng thừa này nếu lỡ tạo

-- 1. Bảng Người dùng (users)
CREATE TABLE users (
    id VARCHAR(255) PRIMARY KEY, -- UID từ Firebase Authentication
    email VARCHAR(255) UNIQUE NOT NULL, -- Email sinh viên (fpt.edu.vn)
    full_name VARCHAR(255),
    avatar_url VARCHAR(255),
    phone VARCHAR(50),
    student_id VARCHAR(50), -- Mã số sinh viên
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
 
-- 2. Tạo bảng Sản phẩm (products)
CREATE TABLE products (
    id VARCHAR(255) PRIMARY KEY,
    seller_id VARCHAR(255) REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    price INT,
    image_urls VARCHAR(255)[], -- Mảng danh sách link hình ảnh đặc trưng của Postgres
    category VARCHAR(100),
    condition VARCHAR(50), -- NEW, LIKE_NEW, USED (khớp enum BE)
    quantity INT NOT NULL DEFAULT 1, -- Số lượng tồn kho
    status VARCHAR(50) DEFAULT 'available', -- available, sold
    location_name VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
 
-- 3. Tạo bảng Giỏ hàng (cart)
CREATE TABLE cart (
    id VARCHAR(255) PRIMARY KEY,
    user_id VARCHAR(255) REFERENCES users(id) ON DELETE CASCADE,
    product_id VARCHAR(255) REFERENCES products(id) ON DELETE CASCADE,
    quantity INT DEFAULT 1,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
 
-- 4. Tạo bảng Đơn hàng (orders)
CREATE TABLE orders (
    id VARCHAR(255) PRIMARY KEY,
    buyer_id VARCHAR(255) REFERENCES users(id) ON DELETE SET NULL,
    seller_id VARCHAR(255) REFERENCES users(id) ON DELETE SET NULL,
    total_amount INT,
    payment_method VARCHAR(100), -- Trực tiếp khi nhận hàng, Chuyển khoản
    shipping_note VARCHAR(255), -- Ghi chú điểm hẹn nhận hàng
    status VARCHAR(50) DEFAULT 'pending', -- pending, approved, completed, cancelled
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
 
-- 5. Tạo bảng Chi tiết đơn hàng (order_items)
CREATE TABLE order_items (
    id VARCHAR(255) PRIMARY KEY,
    order_id VARCHAR(255) REFERENCES orders(id) ON DELETE CASCADE,
    product_id VARCHAR(255) REFERENCES products(id) ON DELETE SET NULL,
    quantity INT DEFAULT 1,
    price INT -- Giá tại thời điểm mua
);
 
-- 6. Tạo bảng Phòng Chat (chat_rooms)
CREATE TABLE chat_rooms (
    id VARCHAR(255) PRIMARY KEY,
    product_id VARCHAR(255) REFERENCES products(id) ON DELETE CASCADE,
    buyer_id VARCHAR(255) REFERENCES users(id) ON DELETE CASCADE,
    seller_id VARCHAR(255) REFERENCES users(id) ON DELETE CASCADE,
    last_message TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
 
-- 7. Tạo bảng Tin nhắn (chat_messages)
CREATE TABLE chat_messages (
    id VARCHAR(255) PRIMARY KEY,
    room_id VARCHAR(255) REFERENCES chat_rooms(id) ON DELETE CASCADE,
    sender_id VARCHAR(255) REFERENCES users(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
 
-- 8. Tạo bảng Thông báo (notifications)
CREATE TABLE notifications (
    id VARCHAR(255) PRIMARY KEY,
    receiver_id VARCHAR(255) REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    body TEXT,
    type VARCHAR(100), -- order_status, new_message, product_approved
    order_id VARCHAR(255), -- Liên kết tới đơn hàng (tuỳ chọn)
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO users (id, email, full_name, avatar_url, phone, student_id, created_at)
VALUES  
  ('user-1', 'seller@fpt.edu.vn', 'Nguyễn Văn Seller', 'https://example.com/seller.jpg', '0123456789', 'SE150001', NOW()),
  ('user-2', 'buyer@fpt.edu.vn', 'Nguyễn Văn Buyer', 'https://example.com/buyer.jpg', '0987654321', 'SE150002', NOW())
ON CONFLICT (id) DO NOTHING;

INSERT INTO products (
    id, seller_id, title, description, price, image_urls,
    category, condition, quantity, status, location_name, created_at
)
VALUES
  -- Điện tử (5)
  ('prod-1', 'user-1', 'iPhone 15 Pro', 'iPhone 15 Pro màu đen 128GB, còn mới 99%', 25000000,
    ARRAY['https://images.unsplash.com/photo-1695048133142-1a20484d2569?w=800&auto=format&fit=crop'],
    'Điện tử', 'NEW', 2, 'available', 'Sảnh tòa Alpha', NOW()),
  ('prod-2', 'user-1', 'MacBook Pro M3', 'MacBook Pro 14 inch M3/8GB/512GB', 40000000,
    ARRAY['https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=800&auto=format&fit=crop'],
    'Điện tử', 'LIKE_NEW', 1, 'available', 'Thư viện tòa Delta', NOW()),
  ('prod-3', 'user-1', 'iPad Air 5', 'iPad Air 5 Wifi 64GB màu xanh', 13500000,
    ARRAY['https://images.unsplash.com/photo-1544244015-0df4b3ffc6b0?w=800&auto=format&fit=crop'],
    'Điện tử', 'USED', 3, 'available', 'Sảnh tòa Beta', NOW()),
  ('prod-4', 'user-1', 'Tai nghe Sony WH-1000XM5', 'Tai nghe chống ồn, pin 30 giờ', 6500000,
    ARRAY['https://images.unsplash.com/photo-1618366712010-f4ae9c647dcb?w=800&auto=format&fit=crop'],
    'Điện tử', 'LIKE_NEW', 2, 'available', 'Khu ký túc xá A', NOW()),
  ('prod-5', 'user-1', 'Bàn phím cơ Keychron K2', 'Switch brown, hỗ trợ Bluetooth', 1800000,
    ARRAY['https://images.unsplash.com/photo-1587829741301-dc798b83add3?w=800&auto=format&fit=crop'],
    'Điện tử', 'USED', 4, 'available', 'Phòng lab CNTT', NOW()),

  -- Sách giáo trình (5)
  ('prod-6', 'user-1', 'Giáo trình Lập trình Java', 'Sách môn PRJ301, có ghi chú nhẹ', 120000,
    ARRAY['https://images.unsplash.com/photo-1544947950-fa07a98d237f?w=800&auto=format&fit=crop'],
    'Sách giáo trình', 'USED', 5, 'available', 'Thư viện chính', NOW()),
  ('prod-7', 'user-1', 'Sách Database System Concepts', 'Bản tiếng Anh, còn mới', 350000,
    ARRAY['https://images.unsplash.com/photo-1497633762303-f122a1ddb87b?w=800&auto=format&fit=crop'],
    'Sách giáo trình', 'LIKE_NEW', 2, 'available', 'Thư viện tòa Delta', NOW()),
  ('prod-8', 'user-1', 'Slide môn Software Architecture', 'Bộ slide + đề cương ôn thi', 80000,
    ARRAY['https://images.unsplash.com/photo-1456513088650-9b9392247375?w=800&auto=format&fit=crop'],
    'Sách giáo trình', 'NEW', 10, 'available', 'Sảnh tòa Alpha', NOW()),
  ('prod-9', 'user-1', 'Giáo trình Toán cao cấp A1', 'Có lời giải bài tập viết tay', 90000,
    ARRAY['https://images.unsplash.com/photo-1503676260728-1c00da094a0b?w=800&auto=format&fit=crop'],
    'Sách giáo trình', 'USED', 3, 'available', 'Khu ký túc xá B', NOW()),
  ('prod-10', 'user-1', 'Bộ đề IELTS Cambridge 18', 'Sách luyện thi IELTS bản in', 280000,
    ARRAY['https://images.unsplash.com/photo-1524995997913-94a52c8f0b0f?w=800&auto=format&fit=crop'],
    'Sách giáo trình', 'LIKE_NEW', 1, 'available', 'Thư viện chính', NOW()),

  -- Đồ dùng (5)
  ('prod-11', 'user-1', 'Quạt bàn mini USB', 'Quạt để bàn cho ký túc xá, 3 tốc độ', 150000,
    ARRAY['https://images.unsplash.com/photo-1585771724681-e6277d46882b?w=800&auto=format&fit=crop'],
    'Đồ dùng', 'LIKE_NEW', 6, 'available', 'Ký túc xá A', NOW()),
  ('prod-12', 'user-1', 'Bình giữ nhiệt 750ml', 'Inox, giữ nóng 8 giờ', 220000,
    ARRAY['https://images.unsplash.com/photo-1602143407151-7111542de6e8?w=800&auto=format&fit=crop'],
    'Đồ dùng', 'NEW', 4, 'available', 'Canteen trường', NOW()),
  ('prod-13', 'user-1', 'Đèn bàn LED chống cận', '3 chế độ sáng, cổng USB', 190000,
    ARRAY['https://images.unsplash.com/photo-1507473885765-e6ed057f782c?w=800&auto=format&fit=crop'],
    'Đồ dùng', 'USED', 2, 'available', 'Ký túc xá B', NOW()),
  ('prod-14', 'user-1', 'Giá treo quần áo inox', 'Giá 3 tầng cho phòng dorm', 320000,
    ARRAY['https://images.unsplash.com/photo-1556911220-bff31c812dba?w=800&auto=format&fit=crop'],
    'Đồ dùng', 'LIKE_NEW', 1, 'available', 'Ký túc xá C', NOW()),
  ('prod-15', 'user-1', 'Bộ chăn ga gối dorm', 'Gọn nhẹ, đã giặt sạch', 450000,
    ARRAY['https://images.unsplash.com/photo-1631049307264-da0ec9d70304?w=800&auto=format&fit=crop'],
    'Đồ dùng', 'USED', 2, 'available', 'Ký túc xá A', NOW()),

  -- Dịch vụ (5) — khoá học, vé, gói dịch vụ chuyển nhượng
  ('prod-16', 'user-1', 'Vé xem phim CGV 2D', 'Voucher CGV còn hạn 30 ngày', 85000,
    ARRAY['https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=800&auto=format&fit=crop'],
    'Dịch vụ', 'NEW', 8, 'available', 'Online / gặp tại cổng trường', NOW()),
  ('prod-17', 'user-1', 'Khoá học Udemy Web Dev', 'Tài khoản chuyển nhượng, full course', 399000,
    ARRAY['https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=800&auto=format&fit=crop'],
    'Dịch vụ', 'NEW', 1, 'available', 'Online', NOW()),
  ('prod-18', 'user-1', 'Gói gym campus 1 tháng', 'Thẻ tập gym nội khu còn 25 ngày', 250000,
    ARRAY['https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800&auto=format&fit=crop'],
    'Dịch vụ', 'LIKE_NEW', 1, 'available', 'Phòng gym trường', NOW()),
  ('prod-19', 'user-1', 'Vé workshop UX/UI Design', 'Vé sự kiện cuối tuần tại campus', 120000,
    ARRAY['https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=800&auto=format&fit=crop'],
    'Dịch vụ', 'NEW', 3, 'available', 'Hội trường lớn', NOW()),
  ('prod-20', 'user-1', 'Khoá luyện thi IELTS 6.5', 'Chuyển nhượng slot lớp nhóm 4 người', 1200000,
    ARRAY['https://images.unsplash.com/photo-1434030216411-0b793f4b4173?w=800&auto=format&fit=crop'],
    'Dịch vụ', 'LIKE_NEW', 2, 'available', 'Online / Thư viện', NOW())
ON CONFLICT (id) DO NOTHING;

select * from order_items
select * from products
select * from users

