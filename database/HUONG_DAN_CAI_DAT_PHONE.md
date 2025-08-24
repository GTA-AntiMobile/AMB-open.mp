# Hướng dẫn cài đặt hệ thống Phone với bảng DanhBa

## 1. Tạo bảng database

Chạy file `phone_contacts.sql` trong database MySQL để tạo bảng `DanhBa`:

```sql
-- Import file: database/phone_contacts.sql
```

## 2. Cấu trúc bảng DanhBa

```sql
CREATE TABLE `DanhBa` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `sqlID` int(11) NOT NULL,                    -- ID của player
  `TenLienHe` varchar(32) NOT NULL DEFAULT '', -- Tên người lưu
  `SoDienThoai` varchar(16) NOT NULL DEFAULT '', -- Số điện thoại
  `NgayTao` timestamp DEFAULT CURRENT_TIMESTAMP, -- Thời gian tạo
  `NgayCapNhat` datetime DEFAULT NULL,           -- Thời gian cập nhật
  PRIMARY KEY (`id`),
  KEY `sqlID` (`sqlID`)
);
```

## 3. Tích hợp vào gamemode

File `phone.pwn` đã được tích hợp sẵn với YSI hooks:

- ✅ `hook OnPlayerSpawn` - Tự động load danh bạ
- ✅ `hook OnPlayerDisconnect` - Tự động save danh bạ

## 4. Sử dụng

### Lệnh chính:
- `/phone` - Mở điện thoại

### Tính năng:
- **Dịch vụ**: Gọi cảnh sát/bác sĩ/taxi đang on duty
- **Danh bạ**: Thêm/Gọi/SMS/Xóa liên hệ
- **Database**: Tự động lưu/load từ bảng `DanhBa`

## 5. Thread IDs sử dụng

```pawn
#define LOAD_DANHBA_THREAD      100
#define SAVE_DANHBA_THREAD      101  
#define DELETE_DANHBA_THREAD    102
```

## 6. Lưu ý

- Bảng `DanhBa` hoàn toàn độc lập với bảng `contacts` cũ
- Hỗ trợ tối đa 50 liên hệ mỗi player
- Tự động backup khi player disconnect
- Có timestamp để theo dõi thời gian tạo (NgayTao tự động, NgayCapNhat thủ công)
