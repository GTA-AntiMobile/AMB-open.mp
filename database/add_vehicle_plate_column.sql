-- =====================================================
-- AMB PROJECT - VEHICLE PLATE SYSTEM DATABASE UPDATE
-- Them cot plate vao bang vehicles va cap nhat bang vehicle_plates
-- =====================================================

-- Kiem tra xem cot plate da ton tai chua
-- Neu chua thi them vao
SET @sql = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
     WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'vehicles'
     AND COLUMN_NAME = 'plate') = 0,
    'ALTER TABLE `vehicles` ADD COLUMN `plate` VARCHAR(16) DEFAULT "" COMMENT "Vehicle plate number"',
    'SELECT "Column plate already exists"'
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Cap nhat tat ca xe cu co plate = NULL thanh empty string
UPDATE `vehicles`
SET `plate` = ''
WHERE `plate` IS NULL;

-- Tao bang vehicle_plates neu chua co
CREATE TABLE IF NOT EXISTS `vehicle_plates` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `vehicle_id` INT NOT NULL,
    `plate` VARCHAR(16) NOT NULL,
    `plate_type` TINYINT DEFAULT 0 COMMENT "0=Normal, 1=VIP, 2=Police, 3=Government, 4=Emergency, 5=Faction, 6=Custom",
    `owner_id` INT NOT NULL,
    `vehicle_model` INT NOT NULL,
    `faction_id` INT DEFAULT 0 COMMENT "Faction ID if plate_type = 5",
    `created_time` INT NOT NULL,
    UNIQUE KEY `unique_vehicle` (`vehicle_id`),
    UNIQUE KEY `unique_plate` (`plate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Them cot plate_type va faction_id neu chua co
SET @sql = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
     WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'vehicle_plates'
     AND COLUMN_NAME = 'plate_type') = 0,
    'ALTER TABLE `vehicle_plates` ADD COLUMN `plate_type` TINYINT DEFAULT 0 COMMENT "0=Normal, 1=VIP, 2=Police, 3=Government, 4=Emergency, 5=Faction, 6=Custom"',
    'SELECT "Column plate_type already exists"'
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
     WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'vehicle_plates'
     AND COLUMN_NAME = 'faction_id') = 0,
    'ALTER TABLE `vehicle_plates` ADD COLUMN `faction_id` INT DEFAULT 0 COMMENT "Faction ID if plate_type = 5"',
    'SELECT "Column faction_id already exists"'
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Hien thi thong bao hoan thanh
SELECT 'Vehicle plate system database updated successfully!' as Status;
