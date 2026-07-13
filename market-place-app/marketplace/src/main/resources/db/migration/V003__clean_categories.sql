-- ============================================================
-- Migration V003: Xoá các danh mục cũ không dùng (BOOKS, ELECTRICS, FASHION, HOME)
-- và thay bằng 4 danh mục tiếng Việt: Dịch vụ, Sách giáo trình, Điện tử, Đồ dùng
-- ============================================================

-- Xoá các danh mục cũ
DELETE FROM categories WHERE name IN ('BOOKS', 'ELECTRICS', 'FASHION', 'HOME');

-- Insert 4 danh mục mới nếu chưa tồn tại
INSERT INTO categories (id, name, description, created_at)
SELECT gen_random_uuid(), 'Dịch vụ', 'Các dịch vụ sinh viên', NOW()
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name = 'Dịch vụ');

INSERT INTO categories (id, name, description, created_at)
SELECT gen_random_uuid(), 'Sách giáo trình', 'Sách giáo trình, tài liệu học tập', NOW()
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name = 'Sách giáo trình');

INSERT INTO categories (id, name, description, created_at)
SELECT gen_random_uuid(), 'Điện tử', 'Đồ điện tử, công nghệ', NOW()
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name = 'Điện tử');

INSERT INTO categories (id, name, description, created_at)
SELECT gen_random_uuid(), 'Đồ dùng', 'Đồ dùng cá nhân, dụng cụ học tập', NOW()
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name = 'Đồ dùng');