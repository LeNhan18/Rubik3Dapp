# 🚀 QUICK START - HTTPS với Self-Signed Certificate (MIỄN PHÍ)

## 📌 TL;DR - Cách nhanh nhất

### Trên máy Backend Server:

```powershell
# Bước 1: Generate certificate (chỉ làm 1 lần)
cd backend
python generate_cert.py

# Bước 2: Chạy server với HTTPS
python run_https.py
```

Server sẽ chạy tại: `https://YOUR_IP:8000`

### Trên máy Client (Flutter):

```bash
# Chỉ cần 2 bước:
flutter pub get
flutter run
```

**Đó là tất cả!** Code đã được cấu hình sẵn.

---

## 📝 Chi tiết từng bước

### Backend (Chỉ làm 1 lần)

1. **Generate Certificate:**
   ```powershell
   cd backend
   python generate_cert.py
   ```
   
   Script sẽ:
   - Tự động detect IP của máy bạn
   - Tạo `certs/cert.pem` và `certs/key.pem`
   - In ra thông tin và hướng dẫn

2. **Chạy Server:**
   ```powershell
   python run_https.py
   ```
   
   Server khởi động tại:
   - `https://YOUR_IP:8000`
   - API Docs: `https://YOUR_IP:8000/docs`

### Flutter Client (Mỗi máy client)

1. **Cập nhật backend URL** (nếu cần):
   Tìm file config và đổi URL:
   ```dart
   // Từ:
   final baseUrl = 'http://192.168.1.100:8000';
   
   // Sang:
   final baseUrl = 'https://192.168.1.100:8000';
   ```

2. **Chạy app:**
   ```bash
   flutter pub get
   flutter run
   ```

**Xong!** App sẽ tự động accept self-signed certificate trong development mode.

---

## 🔍 Tìm file config backend URL

Có thể ở các vị trí sau:

```
lib/config/api_config.dart
lib/services/api_service.dart
lib/utils/constants.dart
lib/config/app_config.dart
```

Tìm dòng có `http://` và IP backend, đổi thành `https://`

---

## ✅ Kiểm tra

### Test Backend:
```powershell
# Từ máy backend
curl -k https://localhost:8000/docs

# Từ máy khác (thay YOUR_IP)
curl -k https://YOUR_IP:8000/docs
```

### Test Flutter:
- Chạy app
- Thử login/register
- Kiểm tra console không có lỗi SSL

---

## 🆘 Troubleshooting

### Lỗi "OpenSSL not found"
**Giải pháp:**
- Cài Git for Windows (đã bao gồm OpenSSL)
- Hoặc download OpenSSL: https://slproweb.com/products/Win32OpenSSL.html

### Flutter không kết nối được
**Kiểm tra:**
1. Backend đang chạy? → `python run_https.py`
2. IP đúng chưa? → Xem output của `generate_cert.py`
3. Firewall? → Cho phép port 8000
4. URL trong Flutter đúng chưa? → Phải là `https://` không phải `http://`

### Browser báo "Not Secure"
**Bình thường!** Self-signed cert sẽ bị browser cảnh báo.
- Nhấn "Advanced" → "Proceed anyway" để xem API docs
- Flutter app KHÔNG BỊ Ảnh hưởng (đã config sẵn)

---

## 💡 Tips

### Khi nào phải generate lại certificate?
- Đổi IP máy backend
- Certificate hết hạn (365 ngày)
- Chạy lại `python generate_cert.py` là xong

### Production thì sao?
**KHÔNG DÙNG** self-signed cert cho production!
Dùng:
- Let's Encrypt (miễn phí)
- Cloudflare (miễn phí)
- Certificate từ CA tin cậy

### Có cần config gì trên router không?
Nếu máy client và backend cùng mạng LAN → **KHÔNG CẦN**
Nếu khác mạng → Cần port forwarding port 8000

---

## 📚 Đọc thêm

- Chi tiết đầy đủ: [HTTPS_SETUP.md](HTTPS_SETUP.md)
- Lỗi và giải pháp: [HTTPS_SETUP.md#troubleshooting](HTTPS_SETUP.md#troubleshooting)
- Security best practices: [HTTPS_SETUP.md#production](HTTPS_SETUP.md#production)

---

**🎉 Done! Backend của bạn giờ đã chạy HTTPS hoàn toàn miễn phí!**
