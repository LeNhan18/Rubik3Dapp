# Hướng dẫn cài đặt HTTPS với Self-Signed Certificate (MIỄN PHÍ)

## 🔒 Tổng quan
- **Chi phí**: HOÀN TOÀN MIỄN PHÍ
- **Phù hợp cho**: Development và testing
- **Kịch bản**: 1 máy chạy backend server, nhiều máy client chạy Flutter app

## 📋 Các bước thực hiện

### Bước 1: Tạo Self-Signed Certificate trên máy Backend

#### Option A: Sử dụng OpenSSL (Recommended)

```powershell
# Tạo thư mục chứa certificates
cd backend
mkdir certs
cd certs

# Tạo private key và certificate (valid 365 ngày)
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes
```

**Khi chạy lệnh trên, nhập thông tin:**
- Country Name: VN
- State: Ha Noi (hoặc tỉnh của bạn)
- Locality: Ha Noi
- Organization: Rubik Master Dev
- Common Name: **QUAN TRỌNG** - nhập IP của máy backend (VD: 192.168.1.100)
- Email: để trống hoặc email của bạn

#### Option B: Script tự động (Windows)

Chạy script `generate_cert.py` (đã tạo sẵn trong thư mục backend):

```powershell
cd backend
python generate_cert.py
```

Script sẽ tự động:
- Tạo thư mục `certs/`
- Generate certificate với IP của máy
- Lưu `cert.pem` và `key.pem`

### Bước 2: Cấu hình Backend để sử dụng HTTPS

File `.env` của backend đã được cập nhật với:
```
HTTPS_ENABLED=true
SSL_CERT_FILE=certs/cert.pem
SSL_KEY_FILE=certs/key.pem
```

Để bật HTTPS, chỉ cần set `HTTPS_ENABLED=true` trong file `.env`

### Bước 3: Chạy Backend với HTTPS

```powershell
cd backend
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --ssl-keyfile certs/key.pem --ssl-certfile certs/cert.pem
```

Hoặc sử dụng script `run_https.py`:
```powershell
python run_https.py
```

Backend sẽ chạy tại: `https://192.168.1.100:8000` (thay bằng IP máy bạn)

### Bước 4: Cấu hình Flutter Client

#### 4.1 Chỉ cần đổi URL trong config
Trong file Flutter config, đổi:
- Từ: `http://192.168.1.100:8000`
- Sang: `https://192.168.1.100:8000`

#### 4.2 Xử lý Self-Signed Certificate trong Flutter

**Option A: Cho phép tất cả certificates (CHỈ CHO DEV)**

Tạo file `lib/utils/http_overrides.dart`:
```dart
import 'dart:io';

class DevHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = 
          (X509Certificate cert, String host, int port) => true;
  }
}
```

Trong `main.dart`, thêm:
```dart
import 'dart:io';
import 'utils/http_overrides.dart';

void main() {
  // CHỈ CHO DEVELOPMENT - cho phép self-signed certificates
  HttpOverrides.global = DevHttpOverrides();
  
  runApp(MyApp());
}
```

**Option B: Trust specific certificate (An toàn hơn)**

Copy file `cert.pem` vào `assets/certificates/` của Flutter project và load nó:

```dart
import 'dart:io';
import 'package:flutter/services.dart';

Future<SecurityContext> getSecurityContext() async {
  final context = SecurityContext(withTrustedRoots: false);
  final certBytes = await rootBundle.load('assets/certificates/cert.pem');
  context.setTrustedCertificatesBytes(certBytes.buffer.asUint8List());
  return context;
}
```

### Bước 5: Deploy trên các máy Client

**Các máy client CHỈ CẦN:**
1. Clone/copy project Flutter
2. Chạy `flutter pub get`
3. Chỉnh sửa backend URL trong config (nếu cần)
4. Chạy `flutter run`

**KHÔNG CẦN** cài certificate vào hệ thống!

## 🔧 Troubleshooting

### Lỗi "Certificate verify failed"
✅ **Giải pháp**: Đảm bảo đã thêm `HttpOverrides.global = DevHttpOverrides()` trong `main.dart`

### Backend không start được
✅ **Kiểm tra**:
- File `cert.pem` và `key.pem` có trong thư mục `certs/`
- Port 8000 chưa bị sử dụng
- Chạy với quyền admin nếu cần

### Client không kết nối được
✅ **Kiểm tra**:
- Firewall cho phép port 8000
- IP address trong Flutter config đúng với IP máy backend
- Backend đang chạy và accessible

## 📌 Lưu ý quan trọng

### ✅ Ưu điểm
- **Hoàn toàn miễn phí**
- Dễ setup và maintain
- Client chỉ cần thay đổi code Flutter (không cần cài certificate vào OS)
- Mã hóa traffic giữa client và server

### ⚠️ Hạn chế
- Chỉ dùng cho **development/testing**
- Browser sẽ cảnh báo "Not Secure" (nhưng Flutter app không bị)
- Mỗi khi đổi IP máy backend phải generate lại certificate
- **KHÔNG DÙNG CHO PRODUCTION**

### 🚀 Cho Production
Khi deploy production, sử dụng:
- **Let's Encrypt** (miễn phí, trusted certificate)
- **Cloudflare** (miễn phí, có SSL/TLS)
- Certificate từ nhà cung cấp tin cậy

## 📝 Checklist

Backend Server:
- [ ] Generate certificate với IP đúng
- [ ] File `cert.pem` và `key.pem` trong `backend/certs/`
- [ ] File `.env` có `HTTPS_ENABLED=true`
- [ ] Chạy backend với SSL parameters
- [ ] Test truy cập `https://YOUR_IP:8000/docs`

Flutter Client:
- [ ] Thêm `DevHttpOverrides` vào project
- [ ] Update `main.dart` với `HttpOverrides.global`
- [ ] Đổi URL từ `http://` sang `https://`
- [ ] Test kết nối từ client tới backend

## 🎯 Kết quả

Sau khi hoàn thành:
- ✅ Backend chạy với HTTPS
- ✅ Traffic được mã hóa
- ✅ Client Flutter kết nối thành công
- ✅ Không cần cài certificate vào máy client
- ✅ **CHI PHÍ: 0 VNĐ**
