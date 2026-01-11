# ⚡ Quick Start - Cho Team Members

## 🎯 Bạn là CLIENT (chỉ chạy Flutter app)

### 1️⃣ Clone project
```bash
git clone <repository-url>
cd Rubik3Dapp
```

### 2️⃣ Install Flutter dependencies
```bash
flutter pub get
```

### 3️⃣ Hỏi Team Leader lấy IP máy server
**Ví dụ:** `192.168.1.100`

### 4️⃣ Sửa IP trong file config
**Mở file:** `lib/config/api_config.dart`

**Sửa dòng 6:**
```dart
static const String SERVER_IP = '192.168.1.100';  // ← Paste IP ở đây
```
**Save file.**

### 5️⃣ Chạy app
```bash
# Desktop
flutter run -d windows

# Hoặc trên điện thoại
flutter devices  # Xem danh sách thiết bị
flutter run -d <device-id>
```

### ✅ DONE! 
App sẽ tự động kết nối đến backend server.

---

## ⚠️ LƯU Ý

- ✅ Máy bạn và máy server phải **cùng mạng WiFi**
- ✅ **KHÔNG CẦN** cài Python, MySQL, hay chạy backend
- ✅ **KHÔNG CẦN** setup file `.env`
- ✅ Chỉ cần Flutter SDK

---

## 🆘 Gặp lỗi?

### "Connection refused" hoặc "Failed to connect"
→ Hỏi Team Leader kiểm tra:
- Backend có đang chạy không?
- Firewall có block port 8000 không?
- IP có đúng không?

### "Widget not found" hoặc lỗi Flutter
→ Chạy:
```bash
flutter clean
flutter pub get
flutter run
```

---

## 📝 Để Develop

Mỗi khi Team Leader thay đổi API, bạn chỉ cần:
```bash
git pull
flutter pub get
flutter run  # Hot reload nếu đang chạy
```

**KHÔNG CẦN** restart backend hay thay đổi config gì cả!
