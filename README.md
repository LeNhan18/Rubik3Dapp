<div align="center">

<img src="assets/images/logo.png" alt="Rubik Record 3D Logo" width="400"/>

<br/>
<br/>

# Rubik Record 3D

### Ứng dụng Rubik's Cube toàn diện với Timer, 3D Cube, AI Solver và Camera Scanner

<br/>

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
[![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://python.org)

[![OpenCV](https://img.shields.io/badge/OpenCV-5C3EE8?style=for-the-badge&logo=opencv&logoColor=white)](https://opencv.org)
[![SQLAlchemy](https://img.shields.io/badge/SQLAlchemy-D71F00?style=for-the-badge&logo=sqlalchemy&logoColor=white)](https://www.sqlalchemy.org)
[![MySQL](https://img.shields.io/badge/MySQL-4479A1?style=for-the-badge&logo=mysql&logoColor=white)](https://www.mysql.com)

<br/>

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](https://opensource.org/licenses/MIT)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](http://makeapullrequest.com)
[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg?style=flat-square)](https://github.com/yourusername/rubik-record-3d/graphs/commit-activity)

</div>

---

## Mục lục

- [Giới thiệu](#giới-thiệu)
- [Tính năng](#tính-năng)
- [Công nghệ sử dụng](#công-nghệ-sử-dụng)
- [Kiến trúc hệ thống](#kiến-trúc-hệ-thống)
- [Yêu cầu hệ thống](#yêu-cầu-hệ-thống)
- [Cài đặt](#cài-đặt)
- [Cấu trúc thư mục](#cấu-trúc-thư-mục)
- [API Documentation](#api-documentation)
- [Platform hỗ trợ](#platform-hỗ-trợ)
- [Roadmap](#roadmap)
- [Đóng góp](#đóng-góp)
- [License](#license)
- [Liên hệ](#liên-hệ)

---

## Giới thiệu

**Rubik Record 3D** là ứng dụng Rubik's Cube hoàn chỉnh được phát triển bằng Flutter và FastAPI, cung cấp trải nghiệm học tập và giải Rubik toàn diện. Ứng dụng tích hợp công nghệ Computer Vision để quét màu Rubik qua camera và sử dụng thuật toán Kociemba để tìm lời giải tối ưu.

---

## Tính năng

### Timer chuyên nghiệp (WCA-compliant)

- Timer chính xác đến từng millisecond
- Hỗ trợ thời gian quan sát (8s/15s hoặc tắt)
- Công cụ thống kê chi tiết (best, average, ao5, ao12)
- Lưu trữ lịch sử giải không giới hạn

### Cube 3D tương tác

- Mô phỏng Rubik 3D chân thực với WebGL
- Tương tác bằng cử chỉ vuốt
- Animation mượt mà khi xoay
- Hỗ trợ nhiều góc nhìn

### AI Solver - Giải Rubik thông minh

- Bộ giải Rubik tự động sử dụng thuật toán Kociemba
- Giao diện chọn màu 54 sticker trực quan
- Animation hiển thị từng bước giải
- Lời giải tối ưu dưới 20 bước

### Camera Scanner - Quét màu Rubik

- Nhận diện màu tự động qua camera
- Xử lý ảnh với OpenCV và Machine Learning
- Hỗ trợ điều kiện ánh sáng đa dạng
- Calibration màu tùy chỉnh

### Hướng dẫn từng bước

- Phương pháp giải Layer-by-Layer (7 bước)
- Phương pháp CFOP cho người nâng cao
- Hướng dẫn chi tiết bằng tiếng Việt
- Animation minh họa cho từng thuật toán

### Trình tạo Scramble WCA

- Thuật toán scramble chuẩn WCA
- Scramble ngẫu nhiên chất lượng cao
- Tùy chỉnh độ dài scramble (15-30 moves)
- Hiển thị trực quan trên cube 3D

### Cá nhân hóa

- Chủ đề sáng/tối/tự động
- Bộ màu cube (Classic/GAN/Moyu)
- Cài đặt âm thanh
- Đa ngôn ngữ (Tiếng Việt/Tiếng Anh)

---

## Công nghệ sử dụng

### Frontend - Mobile Application

<table>
  <tr>
    <td align="center" width="96">
      <a href="https://flutter.dev">
        <img src="https://raw.githubusercontent.com/devicons/devicon/master/icons/flutter/flutter-original.svg" width="48" height="48" alt="Flutter" />
      </a>
      <br>Flutter
    </td>
    <td align="center" width="96">
      <a href="https://dart.dev">
        <img src="https://raw.githubusercontent.com/devicons/devicon/master/icons/dart/dart-original.svg" width="48" height="48" alt="Dart" />
      </a>
      <br>Dart
    </td>
    <td align="center" width="96">
      <a href="https://riverpod.dev">
        <img src="https://riverpod.dev/img/logo.png" width="48" height="48" alt="Riverpod" />
      </a>
      <br>Riverpod
    </td>
    <td align="center" width="96">
      <a href="https://pub.dev/packages/go_router">
        <img src="https://raw.githubusercontent.com/devicons/devicon/master/icons/flutter/flutter-original.svg" width="48" height="48" alt="GoRouter" />
      </a>
      <br>GoRouter
    </td>
    <td align="center" width="96">
      <a href="https://docs.hivedb.dev">
        <img src="https://raw.githubusercontent.com/hivedb/hive/master/.github/logo_transparent.svg" width="48" height="48" alt="Hive" />
      </a>
      <br>Hive DB
    </td>
  </tr>
</table>

| Package | Version | Mục đích |
|---------|---------|----------|
| flutter_riverpod | ^2.5.1 | State Management |
| go_router | ^14.2.7 | Navigation & Routing |
| hive_flutter | ^1.1.0 | Local Database |
| flutter_cube | ^0.1.1 | 3D Cube Rendering |
| camera | ^0.10.5+9 | Camera Access |
| image_picker | ^1.0.7 | Image Selection |
| lottie | ^3.1.2 | Vector Animations |
| confetti | ^0.7.0 | Celebration Effects |
| google_fonts | ^6.2.1 | Typography |
| http | ^1.2.0 | HTTP Client |
| web_socket_channel | ^2.4.0 | WebSocket Connection |

### Backend - API Server

<table>
  <tr>
    <td align="center" width="96">
      <a href="https://python.org">
        <img src="https://raw.githubusercontent.com/devicons/devicon/master/icons/python/python-original.svg" width="48" height="48" alt="Python" />
      </a>
      <br>Python
    </td>
    <td align="center" width="96">
      <a href="https://fastapi.tiangolo.com">
        <img src="https://raw.githubusercontent.com/devicons/devicon/master/icons/fastapi/fastapi-original.svg" width="48" height="48" alt="FastAPI" />
      </a>
      <br>FastAPI
    </td>
    <td align="center" width="96">
      <a href="https://opencv.org">
        <img src="https://raw.githubusercontent.com/devicons/devicon/master/icons/opencv/opencv-original.svg" width="48" height="48" alt="OpenCV" />
      </a>
      <br>OpenCV
    </td>
    <td align="center" width="96">
      <a href="https://numpy.org">
        <img src="https://raw.githubusercontent.com/devicons/devicon/master/icons/numpy/numpy-original.svg" width="48" height="48" alt="NumPy" />
      </a>
      <br>NumPy
    </td>
    <td align="center" width="96">
      <a href="https://scikit-learn.org">
        <img src="https://raw.githubusercontent.com/devicons/devicon/master/icons/scikitlearn/scikitlearn-original.svg" width="48" height="48" alt="scikit-learn" />
      </a>
      <br>scikit-learn
    </td>
  </tr>
</table>

| Package | Version | Mục đích |
|---------|---------|----------|
| fastapi | 0.115.0 | Web Framework |
| uvicorn | 0.32.0 | ASGI Server |
| sqlalchemy | 2.0.36 | ORM Database |
| pymysql | 1.1.0 | MySQL Driver |
| opencv-python | 4.9.0.80 | Computer Vision |
| numpy | 1.26.4 | Numerical Computing |
| scikit-learn | 1.4.0 | Machine Learning |
| pillow | 10.2.0 | Image Processing |
| python-jose | 3.3.0 | JWT Authentication |
| pydantic | 2.9.2 | Data Validation |

### Database & Infrastructure

<table>
  <tr>
    <td align="center" width="96">
      <a href="https://www.mysql.com">
        <img src="https://raw.githubusercontent.com/devicons/devicon/master/icons/mysql/mysql-original.svg" width="48" height="48" alt="MySQL" />
      </a>
      <br>MySQL
    </td>
    <td align="center" width="96">
      <a href="https://www.docker.com">
        <img src="https://raw.githubusercontent.com/devicons/devicon/master/icons/docker/docker-original.svg" width="48" height="48" alt="Docker" />
      </a>
      <br>Docker
    </td>
    <td align="center" width="96">
      <a href="https://www.koyeb.com">
        <img src="https://www.koyeb.com/static/images/logo.svg" width="48" height="48" alt="Koyeb" />
      </a>
      <br>Koyeb
    </td>
  </tr>
</table>

---

## Kiến trúc hệ thống

```
                    ┌─────────────────────────────────────────────────────────┐
                    │                   RUBIK RECORD 3D                         │
                    └─────────────────────────────────────────────────────────┘
                                              │
              ┌───────────────────────────────┼───────────────────────────────┐
              │                               │                               │
              ▼                               ▼                               ▼
    ┌─────────────────┐             ┌─────────────────┐             ┌─────────────────┐
    │   Mobile App    │             │    Web App      │             │   Desktop App   │
    │   (Flutter)     │             │   (Flutter)     │             │   (Flutter)     │
    └────────┬────────┘             └────────┬────────┘             └────────┬────────┘
              │                               │                               │
              └───────────────────────────────┼───────────────────────────────┘
                                              │
                                              ▼
                               ┌──────────────────────────┐
                               │      REST API / WS       │
                               │        (FastAPI)         │
                               └────────────┬─────────────┘
                                              │
              ┌───────────────────────────────┼───────────────────────────────┐
              │                               │                               │
              ▼                               ▼                               ▼
    ┌─────────────────┐             ┌─────────────────┐             ┌─────────────────┐
    │  Color Detection│             │   Cube Solver   │             │  User Service   │
    │    (OpenCV)     │             │   (Kociemba)    │             │  (SQLAlchemy)   │
    └─────────────────┘             └─────────────────┘             └────────┬────────┘
                                                                              │
                                                                              ▼
                                                                   ┌─────────────────┐
                                                                   │     MySQL       │
                                                                   │    Database     │
                                                                   └─────────────────┘
```

---

## Yêu cầu hệ thống

### Frontend Requirements

| Requirement | Minimum Version |
|-------------|-----------------|
| Flutter SDK | 3.5.4 |
| Dart SDK | 3.5.0 |
| Android | API 28 (Android 9.0) |
| iOS | 12.0 |

### Backend Requirements

| Requirement | Minimum Version |
|-------------|-----------------|
| Python | 3.10 |
| MySQL | 8.0 |
| RAM | 2GB |
| Storage | 500MB |

---

## Cài đặt

### Clone Repository

```bash
git clone https://github.com/yourusername/rubik-record-3d.git
cd rubik-record-3d
```

### Frontend Setup

```bash
# Cài đặt Flutter dependencies
flutter pub get

# Chạy code generation (Riverpod, Hive)
dart run build_runner build --delete-conflicting-outputs

# Chạy ứng dụng
flutter run
```

### Backend Setup

```bash
# Di chuyển vào thư mục backend
cd backend

# Tạo virtual environment
python -m venv venv

# Kích hoạt virtual environment
# Windows
venv\Scripts\activate
# Linux/macOS
source venv/bin/activate

# Cài đặt dependencies
pip install -r requirements.txt

# Cấu hình environment variables
cp .env.example .env
# Chỉnh sửa file .env với thông tin database

# Chạy server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### Docker Deployment

```bash
# Build và chạy với Docker Compose
docker-compose up -d

# Hoặc build riêng backend
cd backend
docker build -t rubik-master-api .
docker run -d -p 8000:8000 rubik-master-api
```

---

## Cấu trúc thư mục

```
rubik-record-3d/
├── lib/                          # Flutter source code
│   ├── config/                   # App configuration
│   ├── core/                     # Core utilities
│   │   ├── theme/               # App theme & styling
│   │   └── providers/           # Global Riverpod providers
│   ├── models/                   # Data models
│   ├── screens/                  # UI screens
│   │   ├── home_screen.dart
│   │   ├── timer_screen.dart
│   │   ├── solver_screen.dart
│   │   ├── cube_scan_screen.dart
│   │   ├── tutorial_screen.dart
│   │   └── settings_screen.dart
│   ├── services/                 # API & business logic services
│   ├── widgets/                  # Reusable widgets
│   ├── solver/                   # Rubik solving algorithms
│   └── main.dart                # Entry point
│
├── backend/                      # FastAPI backend
│   ├── app/
│   │   ├── routers/             # API endpoints
│   │   │   ├── rubik.py         # Rubik solver API
│   │   │   ├── admin.py         # Admin API
│   │   │   └── auth.py          # Authentication API
│   │   ├── services/            # Business logic
│   │   │   └── color_detection_service.py
│   │   ├── models/              # Database models
│   │   ├── schemas/             # Pydantic schemas
│   │   └── main.py              # FastAPI app
│   ├── requirements.txt
│   └── Dockerfile
│
├── assets/                       # Static assets
│   ├── animations/              # Lottie animations
│   ├── images/                  # Image assets
│   └── models/                  # 3D model files (.glb)
│
├── test/                         # Test files
├── android/                      # Android platform files
├── ios/                          # iOS platform files
├── web/                          # Web platform files
├── windows/                      # Windows platform files
├── macos/                        # macOS platform files
├── linux/                        # Linux platform files
│
├── pubspec.yaml                  # Flutter dependencies
├── analysis_options.yaml         # Dart analyzer config
└── README.md                     # This file
```

---

## API Documentation

API documentation có sẵn tại endpoint `/docs` khi chạy backend server.

### Endpoints chính

| Method | Endpoint | Mô tả |
|--------|----------|-------|
| POST | `/api/rubik/solve` | Giải Rubik từ chuỗi màu |
| POST | `/api/rubik/detect-colors` | Nhận diện màu từ ảnh |
| POST | `/api/rubik/validate` | Kiểm tra trạng thái cube hợp lệ |
| GET | `/api/rubik/scramble` | Tạo scramble ngẫu nhiên |
| POST | `/api/auth/login` | Đăng nhập |
| POST | `/api/auth/register` | Đăng ký tài khoản |
| GET | `/api/user/profile` | Lấy thông tin user |
| GET | `/api/user/history` | Lịch sử giải cube |

### Example Request

```bash
curl -X POST "http://localhost:8000/api/rubik/solve" \
  -H "Content-Type: application/json" \
  -d '{"cube_state": "UUUUUUUUURRRRRRRRRFFFFFFFFFDDDDDDDDDLLLLLLLLLBBBBBBBBB"}'
```

### Example Response

```json
{
  "success": true,
  "solution": "R U R' U' R' F R2 U' R' U' R U R' F'",
  "move_count": 14,
  "execution_time": 0.023
}
```

---

## Platform hỗ trợ

| Platform | Status | Minimum Version |
|----------|--------|-----------------|
| Android | Supported | Android 9.0 (API 28) |
| iOS | Supported | iOS 12.0 |
| Web | Supported | Chrome, Firefox, Safari, Edge |
| Windows | Supported | Windows 10 |
| macOS | Supported | macOS 10.14 |
| Linux | Supported | Ubuntu 18.04+ |

---

## Roadmap

| Version | Tính năng | Trạng thái |
|---------|-----------|------------|
| v1.0 | Core features (Timer, 3D Cube, Solver, Scanner) | Completed |
| v1.1 | Thêm puzzle 2x2, 4x4, Pyraminx | Planned |
| v1.2 | Multiplayer Online | Planned |
| v1.3 | AI Training Mode | Planned |
| v1.4 | Augmented Reality (AR) | Planned |
| v1.5 | Tournament Mode | Planned |

---

## Đóng góp

Chúng tôi hoan nghênh mọi đóng góp từ cộng đồng.

### Quy trình đóng góp

1. Fork repository
2. Tạo branch mới (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Mở Pull Request

### Coding Standards

- Tuân thủ Dart style guide
- Viết unit tests cho features mới
- Cập nhật documentation khi cần thiết
- Đảm bảo CI/CD pass trước khi merge

---

## License

Dự án này được phân phối dưới giấy phép MIT. Xem file [LICENSE](LICENSE) để biết thêm chi tiết.

```
MIT License

Copyright (c) 2024 Rubik Record 3D

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## Liên hệ

| Channel | Link |
|---------|------|
| Email | support@rubikmaster.com |
| Website | https://rubikmaster.com |
| GitHub Issues | https://github.com/yourusername/rubik-record-3d/issues |

---

<div align="center">

### Nếu bạn thấy dự án hữu ích, hãy cho chúng tôi một Star

[![GitHub stars](https://img.shields.io/github/stars/yourusername/rubik-record-3d?style=social)](https://github.com/yourusername/rubik-record-3d)

Made with Flutter and FastAPI

</div>
