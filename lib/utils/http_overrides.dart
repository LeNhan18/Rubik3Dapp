import 'dart:io';
import 'package:flutter/services.dart';

/// HTTP Override để cho phép self-signed certificates
/// ⚠️ CHỈ SỬ DỤNG CHO DEVELOPMENT!
/// 
/// Self-signed certificates sẽ bị reject mặc định.
/// Class này override behavior để accept tất cả certificates.
/// 
/// Để sử dụng, thêm vào main.dart:
/// ```dart
/// void main() {
///   // CHỈ CHO DEVELOPMENT
///   HttpOverrides.global = DevHttpOverrides();
///   runApp(MyApp());
/// }
/// ```
class DevHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        // Accept tất cả certificates
        // ⚠️ KHÔNG DÙNG TRONG PRODUCTION!
        return true;
      };
  }
}

/// Alternative: Trust specific certificate
/// An toàn hơn cho development
/// 
/// Usage:
/// ```dart
/// import 'package:flutter/services.dart';
/// 
/// final context = await createSecurityContextWithTrustedCert();
/// // Dùng context này cho HTTP requests
/// ```
Future<SecurityContext> createSecurityContextWithTrustedCert() async {
  final context = SecurityContext(withTrustedRoots: false);
  
  // Load certificate từ assets
  // Cần copy file cert.pem từ backend vào assets/certificates/
  try {
    final certBytes = await rootBundle.load('assets/certificates/cert.pem');
    context.setTrustedCertificatesBytes(certBytes.buffer.asUint8List());
    print('✅ Loaded trusted certificate');
  } catch (e) {
    print('⚠️ Could not load certificate: $e');
    print('💡 Make sure cert.pem is in assets/certificates/');
  }
  
  return context;
}

/// Kiểm tra xem có đang chạy trong development mode không
bool get isDebugMode {
  bool debugMode = false;
  assert(() {
    debugMode = true;
    return true;
  }());
  return debugMode;
}

/// Setup HTTP overrides chỉ cho debug mode
void setupHttpOverridesForDevelopment() {
  if (isDebugMode) {
    HttpOverrides.global = DevHttpOverrides();
    print('🔓 Development mode: Self-signed certificates enabled');
  } else {
    print('🔒 Production mode: Using system certificates');
  }
}
