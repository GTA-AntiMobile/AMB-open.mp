# Custom Vehicle System - AMB Server

## Mo ta
He thong custom vehicle cho phep ban them cac xe tu chinh vao server open.mp. He thong nay ho tro:
- Tai custom vehicle models (.dff va .txd files)
- Spawn custom vehicles trong game
- Quan ly danh sach custom vehicles
- Reload custom vehicles ma khong can restart server

## Cach su dung

### 1. Cai dat Custom Vehicle Models

1. **Tai custom vehicle models:**
   - Tim va tai cac file .dff va .txd cho xe ban muon them
   - Dat cac file vao thu muc `scriptfiles/models/vehicle/`

2. **Cau hinh trong file `custom_vehicles.cfg`:**
   ```
   ModelID|BaseID|Name|DFF_Path|TXD_Path
   ```
   
   Vi du:
   ```
   30000|411|Lamborghini Aventador|models/vehicle/lambo_aventador.dff|models/vehicle/lambo_aventador.txd
   ```

3. **Giai thich cac tham so:**
   - `ModelID`: ID cua custom vehicle (30000-30099)
   - `BaseID`: ID cua xe goc trong SA-MP (400-611)
   - `Name`: Ten hien thi cua xe
   - `DFF_Path`: Duong dan den file .dff
   - `TXD_Path`: Duong dan den file .txd

### 2. Lenh trong Game

#### Lenh cho Admin Level 4+:
- `/reloadcustomcars` - Reload toan bo custom vehicles

#### Lenh cho Admin Level 2+:
- `/listcustomcars` - Hien thi danh sach custom vehicles
- `/customcar [model_id]` - Spawn mot custom vehicle cu the

### 3. Cach them Custom Vehicle moi

1. **Chuan bi file:**
   - Dat file .dff va .txd vao `scriptfiles/models/vehicle/`
   - Chon mot ModelID chua su dung (30000-30099)

2. **Them vao config:**
   - Mo file `scriptfiles/custom_vehicles.cfg`
   - Them dong moi theo format: `ModelID|BaseID|Name|DFF_Path|TXD_Path`

3. **Reload trong game:**
   - Su dung lenh `/reloadcustomcars` de tai xe moi

### 4. Gioi han va Loi ich

#### Gioi han:
- Toi da 99 custom vehicles
- ModelID phai trong khoang 30000-30099
- BaseID phai hop le (400-611)
- File .dff va .txd phai ton tai

#### Loi ich:
- Khong can restart server de them xe moi
- Ho tro nhieu loai xe khac nhau
- De dang quan ly va cau hinh
- Tich hop san voi he thong xe hien tai

### 5. Troubleshooting

#### Loi thuong gap:
1. **"Khong tim thay file DFF/TXD":**
   - Kiem tra duong dan file trong config
   - Dam bao file ton tai trong thu muc

2. **"Model ID khong hop le":**
   - Kiem tra ModelID co trong khoang 30000-30099
   - Dam bao khong trung voi xe khac

3. **"Khong the tao vehicle":**
   - Kiem tra gioi han xe cua server
   - Dam bao co du slot xe trong game

#### Debug:
- Kiem tra console server de xem log
- Su dung `/listcustomcars` de xem xe nao da duoc tai
- Kiem tra quyen admin khi su dung lenh

### 6. Vi du Custom Vehicles

Mot so vi du custom vehicles co san:
- Lamborghini Aventador (ID: 30000)
- McLaren P1 (ID: 30001)
- BMW M3 GTR (ID: 30002)
- Nissan Skyline R34 (ID: 30003)
- Tesla Model S (ID: 30004)
- Audi R8 (ID: 30005)

### 7. Lien he

Neu ban gap van de hoac can ho tro them, vui long lien he voi Development Team.

---
**Chu y:** He thong nay chi ho tro open.mp server. Khong ho tro SA-MP server cu.
