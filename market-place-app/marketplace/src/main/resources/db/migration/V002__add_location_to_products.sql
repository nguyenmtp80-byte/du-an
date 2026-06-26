-- ============================================================
-- Migration V002: Add location fields (latitude, longitude)
-- to products table for Map feature
-- ============================================================
-- Nếu Hibernate ddl-auto=update, các cột này sẽ được tự động thêm.
-- Script này dành cho trường hợp chạy migration thủ công.

ALTER TABLE products
ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION;

-- Index cho tìm kiếm sản phẩm gần vị trí (tăng tốc truy vấn Haversine)
CREATE INDEX IF NOT EXISTS idx_products_location
    ON products (latitude, longitude)
    WHERE latitude IS NOT NULL AND longitude IS NOT NULL;

-- Index cho status để filter nhanh sản phẩm available
CREATE INDEX IF NOT EXISTS idx_products_status_location
    ON products (status)
    WHERE status = 'available';