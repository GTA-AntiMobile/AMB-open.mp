-- =====================================================
-- AMB PROJECT - INVENTORY SYSTEM DATABASE UPDATE
-- Them cot InventoryData vao bang accounts
-- =====================================================

-- Kiem tra xem cot InventoryData da ton tai chua
-- Neu chua thi them vao
ALTER TABLE `accounts` 
ADD COLUMN IF NOT EXISTS `InventoryData` TEXT DEFAULT '' 
COMMENT 'Player inventory data serialized as string';

-- Cap nhat tat ca tai khoan cu co InventoryData = NULL thanh empty string
UPDATE `accounts` 
SET `InventoryData` = '' 
WHERE `InventoryData` IS NULL;

-- Hien thi thong bao hoan thanh
SELECT 'InventoryData column added successfully!' as Status;






