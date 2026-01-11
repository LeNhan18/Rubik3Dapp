/// API Configuration
/// Sửa SERVER_IP thành IP máy chạy backend
class ApiConfig {
  // ============================================
  // THAY ĐỔI IP NÀY THÀNH IP MÁY CHẠY BACKEND
  // ============================================
  static const String SERVER_IP = '10.0.10.121';  // ← SỬA ĐÂY
  static const String SERVER_PORT = '8000';
  
  // ============================================
  // KHÔNG CẦN SỬA PHẦN DƯỚI
  // ============================================
  
  // HTTP API Base URL
  static String get baseUrl => 'http://$SERVER_IP:$SERVER_PORT/api';
  
  // WebSocket URL
  static String wsUrl(int userId, String token) => 
      'ws://$SERVER_IP:$SERVER_PORT/ws/$userId?token=$token';
  
  // API Documentation (chạy trên server)
  static String get docsUrl => 'http://$SERVER_IP:$SERVER_PORT/docs';
  
  // Quick presets
  static const Map<String, String> presets = {
    'localhost': '127.0.0.1',
    'samsung': '10.0.10.121',  // IP hiện tại
    'production': 'api.yourdomain.com',
  };
  
  // Switch preset (để debug)
  static void usePreset(String name) {
    // Trong production, có thể implement hot-switch
    print('Current server: $SERVER_IP:$SERVER_PORT');
    print('Available presets: ${presets.keys.join(", ")}');
  }
}
