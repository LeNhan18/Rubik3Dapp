package com.example.rubik

import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Đảm bảo dialog quyền không bị che khuất
        // Loại bỏ FLAG_LAYOUT_NO_LIMITS nếu có để tránh che khuất system dialogs
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            // Android 11+ sử dụng WindowInsetsController
            window.insetsController?.let {
                // Không làm gì đặc biệt, để system tự xử lý
            }
        } else {
            // Android 10 trở xuống
            @Suppress("DEPRECATION")
            window.clearFlags(WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS)
        }
    }
}
