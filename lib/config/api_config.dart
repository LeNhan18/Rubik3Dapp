/// API Configuration
/// Sửa SERVER_IP thành IP máy chạy backend
class ApiConfig {
  // ============================================
  // THAY ĐỔI IP NÀY THÀNH IP MÁY CHẠY BACKEND
  // ============================================
  static const String SERVER_IP =
      'app-falling-wind-2135.fly.dev'; // ← ĐÃ SỬA THÀNH FLY.IO
  static const String SERVER_PORT = ''; // Không cần port với Fly.io

  // ============================================
  // KHÔNG CẦN SỬA PHẦN DƯỚI
  // ============================================

  // HTTPS API Base URL (sử dụng HTTPS cho production)
  static String get baseUrl => SERVER_PORT.isEmpty
      ? 'https://$SERVER_IP/api'
      : 'https://$SERVER_IP:$SERVER_PORT/api';

  // WebSocket URL (wss cho HTTPS)
  static String wsUrl(int userId, String token) => SERVER_PORT.isEmpty
      ? 'wss://$SERVER_IP/ws/$userId?token=$token'
      : 'wss://$SERVER_IP:$SERVER_PORT/ws/$userId?token=$token';

  // API Documentation (chạy trên server)
  static String get docsUrl => SERVER_PORT.isEmpty
      ? 'https://$SERVER_IP/docs'
      : 'http://$SERVER_IP:$SERVER_PORT/docs';

  // Quick presets
  static const Map<String, String> presets = {
    'localhost': '127.0.0.1',
    'samsung': '10.120.151.149', // IP hiện tại
    'production': 'api.yourdomain.com',
  };

  // Switch preset (để debug)
  static void usePreset(String name) {
    // Trong production, có thể implement hot-switch
    print('Current server: $SERVER_IP:$SERVER_PORT');
    print('Available presets: ${presets.keys.join(", ")}');
  }
}
