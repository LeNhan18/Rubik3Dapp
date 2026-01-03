# Hướng dẫn sửa lỗi Image Picker

## Lỗi: "Unable to establish connection on channel"

Lỗi này xảy ra khi native code chưa được rebuild sau khi thêm package `image_picker`.

## Các bước khắc phục:

### 1. **Dừng app hoàn toàn**
- Đóng app trên thiết bị/emulator
- Hoặc chạy: `adb shell am force-stop com.example.rubik`

### 2. **Xóa app cũ (quan trọng!)**
```bash
# Xóa app cũ trên thiết bị
adb uninstall com.example.rubik
```

Hoặc xóa thủ công trên thiết bị: Settings → Apps → Rubik Master → Uninstall

### 3. **Clean project**
```bash
cd android
./gradlew clean
cd ..
flutter clean
```

### 4. **Cài lại dependencies**
```bash
flutter pub get
```

### 5. **Rebuild và chạy lại**
```bash
flutter run
```

Hoặc trong Android Studio:
- Build → Clean Project
- Build → Rebuild Project
- Run → Run 'app'

## Lưu ý quan trọng:

⚠️ **KHÔNG dùng Hot Reload/Hot Restart** - Phải rebuild lại app hoàn toàn!

- Hot Reload chỉ reload Dart code, không rebuild native code
- Phải uninstall app cũ và cài lại app mới

## Đã thêm vào project:

✅ Permissions trong AndroidManifest.xml
✅ FileProvider configuration
✅ file_paths.xml cho FileProvider
✅ Queries cho image picker intents

## Nếu vẫn lỗi:

1. Kiểm tra Android SDK version (minSdk 28+)
2. Kiểm tra xem có đủ permissions khi chạy app không
3. Thử trên emulator khác hoặc thiết bị thật
4. Kiểm tra logcat: `adb logcat | grep -i image_picker`

