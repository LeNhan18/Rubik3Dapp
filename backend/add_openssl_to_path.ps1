# Script để thêm Git OpenSSL vào PATH (Windows)
# Chạy với PowerShell as Administrator

$gitPath = "E:\Program Files\Git\usr\bin"

# Kiểm tra Git path có tồn tại không
if (Test-Path $gitPath) {
    Write-Host "✅ Found Git OpenSSL at: $gitPath" -ForegroundColor Green
    
    # Lấy PATH hiện tại
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    
    # Kiểm tra đã có trong PATH chưa
    if ($currentPath -like "*$gitPath*") {
        Write-Host "✅ OpenSSL already in PATH" -ForegroundColor Green
    } else {
        Write-Host "➕ Adding OpenSSL to PATH..." -ForegroundColor Yellow
        
        # Thêm vào PATH
        $newPath = "$gitPath;$currentPath"
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
        
        Write-Host "✅ OpenSSL added to PATH successfully!" -ForegroundColor Green
        Write-Host "⚠️  Restart your PowerShell/Terminal to apply changes" -ForegroundColor Yellow
    }
    
    # Test OpenSSL
    Write-Host "`n🔍 Testing OpenSSL..." -ForegroundColor Cyan
    & "$gitPath\openssl.exe" version
    
} else {
    Write-Host "❌ Git not found at: $gitPath" -ForegroundColor Red
    Write-Host "💡 Please install Git for Windows from: https://git-scm.com/download/win" -ForegroundColor Yellow
}

Write-Host "`n📖 After restarting terminal, you can run:" -ForegroundColor Cyan
Write-Host "   openssl version" -ForegroundColor White
