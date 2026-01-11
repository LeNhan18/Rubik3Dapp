# 🚀 Hướng dẫn chạy dự án - Multi-Machine Setup

## 📋 Kiến trúc

```
┌─────────────┐          ┌─────────────┐
│   SERVER    │          │  CLIENT 1   │
│  (Backend)  │◄────────►│  (Flutter)  │
│             │          └─────────────┘
│ MySQL + API │          
│             │          ┌─────────────┐
│             │◄────────►│  CLIENT 2   │
└─────────────┘          │  (Flutter)  │
                         └─────────────┘
```

---

## 🖥️ Setup MÁY SERVER (Backend)

### 1. Cài đặt yêu cầu
- Python 3.10+
- XAMPP (MySQL)
- Git

### 2. Clone và setup

```bash
git clone <repository-url>
cd Rubik3Dapp/backend

# Tạo virtual environment
python -m venv .venv
.venv\Scripts\activate

# Cài dependencies
pip install -r requirements.txt
pip install email-validator bcrypt
```

### 3. Cấu hình Database

1. Khởi động XAMPP → Start MySQL
2. Tạo database:
   ```bash
   mysql -u root < database_schema.sql
   ```
3. Import RBAC:
   ```bash
   mysql -u root < migration_add_rbac.sql
   ```

### 4. Cấu hình .env

```bash
# Copy template
cp .env.example .env

# Generate SECRET_KEY mới
python -c "import secrets; print(secrets.token_urlsafe(64))"

# Paste vào .env
```

**File .env:**
```env
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=
DB_NAME=rubik_master

SECRET_KEY=<PASTE_KEY_Ở_ĐÂY>
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=10080

CORS_ORIGINS=["*"]
WS_HEARTBEAT_INTERVAL=30
```

### 5. Chạy Backend

```bash
cd backend
.venv\Scripts\activate
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

✅ Backend chạy tại: `http://0.0.0.0:8000`
✅ API Docs: `http://<IP-MÁY-NÀY>:8000/docs`

### 6. Lấy IP máy server

```bash
ipconfig
```

→ Ghi lại IP (VD: `192.168.1.100`)

---

## 📱 Setup MÁY CLIENT (Flutter)

### 1. Cài đặt yêu cầu
- Flutter SDK 3.5.4+
- Git

### 2. Clone và setup

```bash
git clone <repository-url>
cd Rubik3Dapp
flutter pub get
```

### 3. Cấu hình Server IP

**Mở file:** `lib/config/api_config.dart`

**Sửa dòng này:**
```dart
static const String SERVER_IP = '192.168.1.100';  // ← Thay bằng IP máy server
```

### 4. Chạy App

```bash
# Trên Windows Desktop
flutter run -d windows

# Trên điện thoại Android
flutter run -d <device-id>

# List devices
flutter devices
```

✅ App sẽ kết nối đến backend tại IP đã config

---

## 🔧 Troubleshooting

### ❌ Lỗi: "Connection refused"

**Nguyên nhân:** Firewall chặn port 8000

**Giải pháp:**
1. Tắt Windows Firewall tạm thời
2. Hoặc mở port 8000:
   ```powershell
   # Run as Administrator
   netsh advfirewall firewall add rule name="Backend 8000" dir=in action=allow protocol=TCP localport=8000
   ```

### ❌ Lỗi: "SECRET_KEY is not set"

**Giải pháp:** 
- Generate key mới và paste vào `.env`
- Restart backend

### ❌ Lỗi: "Cannot connect to MySQL"

**Giải pháp:**
- Kiểm tra XAMPP MySQL đang chạy
- Kiểm tra DB_PASSWORD trong `.env`

---

## 📊 Checklist

### Server Machine:
- [ ] XAMPP MySQL running
- [ ] Database `rubik_master` created
- [ ] `.env` file configured with SECRET_KEY
- [ ] Backend running on port 8000
- [ ] Firewall allows port 8000
- [ ] IP address noted down

### Client Machine:
- [ ] Flutter SDK installed
- [ ] Project cloned
- [ ] `flutter pub get` completed
- [ ] Server IP updated in `api_config.dart`
- [ ] Device connected (or desktop mode)
- [ ] App running successfully

---

## 🌐 Network Requirements

- Server và Client phải **cùng mạng WiFi/LAN**
- Server cần IP tĩnh hoặc cố định (DHCP reservation)
- Router không chặn port 8000

---

## 🔐 Bảo mật

### Production Deployment:
1. ✅ Dùng HTTPS thay vì HTTP
2. ✅ Set MySQL password
3. ✅ Restrict CORS_ORIGINS (không dùng `["*"]`)
4. ✅ Implement rate limiting
5. ✅ Backup database định kỳ

---

## 📞 Support

Nếu gặp vấn đề, kiểm tra:
1. Backend logs (terminal chạy uvicorn)
2. Flutter logs (`flutter logs`)
3. API docs: `http://<SERVER-IP>:8000/docs`
