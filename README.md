# Rubik Master - Khám phá thế giới Rubik

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)

Rubik Master là ứng dụng Rubik's Cube hoàn chỉnh được phát triển bằng Flutter, cung cấp trải nghiệm học tập và giải Rubik toàn diện cho người dùng Việt Nam.

## 🎯 Tính năng chính

### ⏱️ Timer chuyên nghiệp (WCA-compliant)
- Timer chính xác đến từng millisecond
- Hỗ trợ thời gian quan sát (8s/15s hoặc tắt)
- Công cụ thống kê chi tiết (best, average, ao5, ao12)
- Lưu trữ lịch sử giải không giới hạn

### 🎲 Cube 3D tương tác
- Mô phỏng Rubik 3D chân thực
- Tương tác bằng cử chỉ vuốt
- Animation mượt mà khi xoay
- Hỗ trợ nhiều góc nhìn

### 🤖 Giải Rubik thông minh
- Bộ giải Rubik tự động
- Giao diện chọn màu 54 sticker trực quan
- Animation hiển thị từng bước giải
- Thuật toán giải tối ưu

### 📚 Hướng dẫn từng bước
- Phương pháp giải layer-by-layer (7 bước)
- Hướng dẫn chi tiết bằng tiếng Việt
- Animation minh họa cho từng thuật toán
- Phù hợp cho người mới bắt đầu

### 🎲 Trình tạo scramble WCA
- Thuật toán scramble chuẩn WCA
- Scramble ngẫu nhiên chất lượng cao
- Tùy chỉnh độ dài scramble (15-30 moves)
- Hiển thị trực quan trên cube 3D

### 🎨 Cá nhân hóa
- Chủ đề sáng/tối/tự động
- Bộ màu cube (Classic/GAN/Moyu)
- Cài đặt âm thanh
- Ngôn ngữ tiếng Việt/tiếng Anh

### 🎉 Celebrate thành tích
- Animation pháo hoa cho kỷ lục mới
- Chia sẻ thành tích lên mạng xã hội
- Trophy animation với hiệu ứng Lottie
- Thông báo "NEW BEST TIME!" ấn tượng

## 🚀 Cài đặt và chạy

### Yêu cầu hệ thống
- Flutter SDK 3.5.4 trở lên
- Dart SDK
- Android Studio hoặc VS Code
- Thiết bị Android 9+ hoặc iOS 12+

### Hướng dẫn cài đặt

1. **Clone repository:**
```bash
git clone https://github.com/yourusername/rubik_master.git
cd rubik_master
```

2. **Cài đặt dependencies:**
```bash
flutter pub get
```

3. **Chạy ứng dụng:**
```bash
# Android
flutter run

# iOS
flutter run -d ios

# Web
flutter run -d chrome
```

## 📱 Platform hỗ trợ

- ✅ **Android 9+** (API level 28+)
- ✅ **iOS 12+** 
- ✅ **Web** (Chrome, Firefox, Safari)
- ✅ **Windows** (Desktop)
- ✅ **macOS** (Desktop)
- ✅ **Linux** (Desktop)

## 🛠️ Công nghệ sử dụng

- **Flutter & Dart** - Framework chính
- **Riverpod** - Quản lý state
- **GoRouter** - Navigation
- **Hive** - Database local
- **flutter_cube** - Rendering 3D
- **Confetti** - Animation celebration
- **Lottie** - Animation vector
- **Google Fonts** - Typography

## 📖 Cấu trúc project

```
lib/
├── core/
│   ├── theme/           # App theme và styling
│   └── providers/       # Global providers (Riverpod)
├── models/              # Data models
├── screens/             # Các màn hình chính
├── widgets/             # Reusable widgets
├── solver/              # Thuật toán giải Rubik
└── main.dart           # Entry point

assets/
└── models/
    └── cubelets/       # 3D model files
```

## 🎯 Roadmap

- [ ] **v1.1**: Thêm các puzzle khác (2x2, 4x4, Pyraminx)
- [ ] **v1.2**: Multiplayer online
- [ ] **v1.3**: AI training mode
- [ ] **v1.4**: Augmented Reality (AR)
- [ ] **v1.5**: Tournament mode

## 📄 License

```
MIT License

Copyright (c) 2024 Rubik Master

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

## 👥 Đóng góp

Chúng tôi hoan nghênh mọi đóng góp! Vui lòng đọc [CONTRIBUTING.md](CONTRIBUTING.md) để biết thêm chi tiết.

## 📞 Liên hệ

- 📧 Email: support@rubikmaster.com
- 🌐 Website: https://rubikmaster.com
- 🐦 Twitter: @RubikMasterApp
- 📱 Instagram: @rubikmaster.app

---

⭐ Nếu bạn thích ứng dụng này, hãy cho chúng tôi một star trên GitHub!
