# Rubik Master Backend API

Backend API cho ứng dụng Rubik Master sử dụng FastAPI và MySQL.

## Cài đặt

### 1. Cài đặt dependencies

```bash
pip install -r requirements.txt
```

### 2. Cấu hình database

Tạo file `.env` từ `.env.example` và cập nhật thông tin database:

```env
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=your_password
DB_NAME=rubik_master
SECRET_KEY=your-secret-key-here
```

### 3. Tạo database

Chạy script SQL để tạo database và tables:

```bash
mysql -u root -p < database_schema.sql
```

Hoặc import vào MySQL Workbench/phpMyAdmin.

### 4. Chạy server

```bash
python -m app.main
```

Hoặc sử dụng uvicorn:

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

API sẽ chạy tại: `http://localhost:8000`

Documentation: `http://localhost:8000/docs`

## API Endpoints

### Authentication
- `POST /api/auth/register` - Đăng ký
- `POST /api/auth/login` - Đăng nhập

### Users
- `GET /api/users/me` - Thông tin user hiện tại
- `GET /api/users/online` - Danh sách user online
- `GET /api/users/search/{username}` - Tìm kiếm user

### Matches
- `POST /api/matches/create` - Tạo match với bạn bè
- `POST /api/matches/find-opponent` - Tìm đối thủ ngẫu nhiên
- `GET /api/matches/{match_id}` - Lấy thông tin match
- `POST /api/matches/{match_id}/start` - Bắt đầu match
- `POST /api/matches/{match_id}/submit-result` - Nộp kết quả
- `GET /api/matches/` - Lấy danh sách matches của user

### Chat
- `POST /api/chat/send` - Gửi tin nhắn
- `GET /api/chat/{match_id}/messages` - Lấy tin nhắn

### Friends
- `POST /api/friends/request` - Gửi lời mời kết bạn
- `POST /api/friends/{friendship_id}/accept` - Chấp nhận lời mời
- `GET /api/friends/` - Danh sách bạn bè
- `GET /api/friends/pending` - Lời mời đang chờ

## WebSocket

Kết nối WebSocket tại: `ws://localhost:8000/ws/{user_id}?token={access_token}`

### Message Types

**Gửi:**
- `{"type": "join_match", "match_id": "..."}` - Tham gia match room
- `{"type": "chat", "match_id": "...", "content": "..."}` - Gửi tin nhắn
- `{"type": "leave_match", "match_id": "..."}` - Rời match room

**Nhận:**
- `{"type": "chat", "sender_id": 1, "content": "...", "timestamp": "..."}` - Tin nhắn mới
- `{"type": "joined_match", "match_id": "..."}` - Xác nhận tham gia

## Cấu trúc Project

```
backend/
├── app/
│   ├── main.py              # FastAPI app
│   ├── config.py            # Configuration
│   ├── database.py          # Database connection
│   ├── models/              # SQLAlchemy models
│   ├── schemas/             # Pydantic schemas
│   ├── services/            # Business logic
│   ├── routers/             # API routes
│   └── utils/               # Utilities
├── requirements.txt
├── database_schema.sql
└── README.md
```

