"""
Script để chạy backend với HTTPS
Tự động load certificate và start server
"""

import os
import sys
import socket
from pathlib import Path

def get_local_ip():
    """Lấy IP address của máy"""
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return "127.0.0.1"

def main():
    # Đường dẫn tới certificates
    certs_dir = Path(__file__).parent / "certs"
    cert_file = certs_dir / "cert.pem"
    key_file = certs_dir / "key.pem"
    
    print("=" * 60)
    print(" RUBIK MASTER BACKEND - HTTPS Server")
    print("=" * 60)
    
    # Kiểm tra certificates có tồn tại không
    if not cert_file.exists() or not key_file.exists():
        print("\n Certificates not found!")
        print("\n Generate certificates first:")
        print("   python generate_cert.py")
        sys.exit(1)
    
    local_ip = get_local_ip()
    
    print(f"\n HTTPS Enabled")
    print(f" Certificate: {cert_file}")
    print(f" Private Key: {key_file}")
    print(f" IP Address: {local_ip}")
    print(f" Port: 8000")
    print(f"\n Server URL: https://{local_ip}:8000")
    print(f" API Docs: https://{local_ip}:8000/docs")
    print(f" ReDoc: https://{local_ip}:8000/redoc")
    
    print("\n" + "=" * 60)
    print("Starting server...")
    print("Press CTRL+C to stop")
    print("=" * 60 + "\n")
    
    # Chạy uvicorn với SSL
    os.system(
        f'python -m uvicorn app.main:app '
        f'--host 0.0.0.0 '
        f'--port 8000 '
        f'--ssl-keyfile {key_file} '
        f'--ssl-certfile {cert_file} '
        f'--reload'
    )

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n Server stopped")
        sys.exit(0)
