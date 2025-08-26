# AMB Admin History Manager

## Mô tả
Ứng dụng Windows Forms để quản lý lịch sử admin của server AMB bên ngoài game, thay thế cho hệ thống panelhistory.pwn trong game.

## Tính năng chính
- 🎮 **Dashboard**: Tổng quan thống kê server
- 👥 **Players**: Quản lý danh sách người chơi
- 💀 **Death History**: Lịch sử tử vong
- 💰 **Money History**: Lịch sử tiền tệ
- 🔫 **Weapon History**: Lịch sử vũ khí
- ⚡ **Admin History**: Lịch sử hoạt động admin

## Cải tiến giao diện
- ✨ **Animations mượt mà**: Slide-in, fade-in, pulse effects
- 🎨 **Giao diện chuyên nghiệp**: Gradient backgrounds, modern UI
- 🖱️ **Sidebar tương tác**: Hover effects, selection states
- 📱 **Splash screen**: Loading animation với logo
- 🔄 **Staggered animations**: Hiệu ứng xuất hiện từng phần tử

## Cách sử dụng

### Yêu cầu hệ thống
- Windows 10/11 (64-bit)
- .NET 6.0 Runtime (tự động cài đặt nếu chưa có)
- Kết nối database MySQL đến server AMB

### Cài đặt
1. Download file `AMB-AdminHistoryManager.exe`
2. Chạy trực tiếp, không cần cài đặt thêm gì
3. Cấu hình kết nối database trong file `AdminHistoryManager.dll.config`

### Database Configuration
Cấu hình connection string trong file config:
```xml
<connectionStrings>
    <add name="DefaultConnection" 
         connectionString="Server=localhost;Database=amb;Uid=root;Pwd=your_password;" />
</connectionStrings>
```

## Tính năng kỹ thuật

### Animation System
- **AnimationHelper**: Utility class cho các hiệu ứng
- **SidebarButton**: Custom button với selection states
- **GradientPanel**: Panel với gradient background
- **StyledDataGridView**: DataGrid với theme chuyên nghiệp

### Performance Optimizations
- Single-file deployment
- Compressed executable
- No debug symbols
- Optimized animations (60fps)
- Async database operations

## File structure
```
AMB-AdminHistoryManager.exe  (76MB - Single executable)
├── Embedded .NET 6.0 Runtime
├── MySql.Data Dependencies
├── Application Resources
└── Embedded Icon & Assets
```

## Troubleshooting

### Không kết nối được database
1. Kiểm tra MySQL server đang chạy
2. Xác nhận connection string chính xác
3. Kiểm tra firewall/network settings

### Animations bị lag
1. Cập nhật driver card đồ họa
2. Đóng các ứng dụng khác để giải phóng RAM
3. Chạy với quyền Administrator

### Icon không hiển thị
- Icon được embed trong exe, không cần file .ico riêng
- Nếu vẫn không hiển thị, restart Windows Explorer

## Phiên bản
- **v1.0**: Initial release với full animations và single-file deployment
- Tương thích với AMB server database schema
- Thay thế hoàn toàn cho core/admin/panelhistory.pwn

## Liên hệ
- Developer: GitHub Copilot
- Support: Thông qua repository AMB-open.mp
- Database: Compatible với MySQL schema của AMB server

---
*Ứng dụng được tối ưu để chạy độc lập, không cần cài đặt thêm dependencies.*
