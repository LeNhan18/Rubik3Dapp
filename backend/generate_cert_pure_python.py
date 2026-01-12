"""
Script tự động tạo Self-Signed Certificate cho HTTPS Development
Sử dụng Python cryptography library - KHÔNG CẦN OpenSSL
Hoàn toàn miễn phí và dễ sử dụng
"""

import os
import socket
import sys
from pathlib import Path
from datetime import datetime, timedelta

try:
    from cryptography import x509
    from cryptography.x509.oid import NameOID
    from cryptography.hazmat.primitives import hashes
    from cryptography.hazmat.primitives.asymmetric import rsa
    from cryptography.hazmat.primitives import serialization
except ImportError:
    print("\n❌ Module 'cryptography' not found!")
    print("\n💡 Install it with:")
    print("   pip install cryptography")
    sys.exit(1)

def get_local_ip():
    """Lấy IP address của máy"""
    try:
        # Tạo socket để detect IP
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return "127.0.0.1"

def generate_certificate_python():
    """Generate self-signed certificate using Python cryptography library"""
    # Tạo thư mục certs nếu chưa có
    certs_dir = Path(__file__).parent / "certs"
    certs_dir.mkdir(exist_ok=True)
    
    cert_file = certs_dir / "cert.pem"
    key_file = certs_dir / "key.pem"
    
    # Lấy IP của máy
    local_ip = get_local_ip()
    
    print("=" * 60)
    print("🔒 RUBIK MASTER - HTTPS Certificate Generator")
    print("   (Pure Python - No OpenSSL required)")
    print("=" * 60)
    print(f"\n📍 Detected IP Address: {local_ip}")
    print(f"📁 Certificate location: {certs_dir}")
    
    # Kiểm tra nếu certificate đã tồn tại
    if cert_file.exists() and key_file.exists():
        response = input("\n⚠️  Certificate already exists. Regenerate? (y/N): ")
        if response.lower() != 'y':
            print("✅ Using existing certificates")
            print(f"\n📜 Certificate: {cert_file}")
            print(f"🔑 Private Key: {key_file}")
            return
    
    print("\n🔧 Generating self-signed certificate...")
    print("⏳ This may take a few seconds (generating 4096-bit RSA key)...")
    
    try:
        # Generate private key
        private_key = rsa.generate_private_key(
            public_exponent=65537,
            key_size=4096,
        )
        
        # Create certificate subject
        subject = issuer = x509.Name([
            x509.NameAttribute(NameOID.COUNTRY_NAME, "VN"),
            x509.NameAttribute(NameOID.STATE_OR_PROVINCE_NAME, "HaNoi"),
            x509.NameAttribute(NameOID.LOCALITY_NAME, "HaNoi"),
            x509.NameAttribute(NameOID.ORGANIZATION_NAME, "RubikMasterDev"),
            x509.NameAttribute(NameOID.COMMON_NAME, local_ip),
        ])
        
        # Create certificate
        cert = x509.CertificateBuilder().subject_name(
            subject
        ).issuer_name(
            issuer
        ).public_key(
            private_key.public_key()
        ).serial_number(
            x509.random_serial_number()
        ).not_valid_before(
            datetime.utcnow()
        ).not_valid_after(
            datetime.utcnow() + timedelta(days=365)
        ).add_extension(
            x509.SubjectAlternativeName([
                x509.DNSName("localhost"),
                x509.DNSName("*.localhost"),
                x509.IPAddress(socket.inet_aton(local_ip)),
            ]),
            critical=False,
        ).sign(private_key, hashes.SHA256())
        
        # Write private key to file
        with open(key_file, "wb") as f:
            f.write(private_key.private_bytes(
                encoding=serialization.Encoding.PEM,
                format=serialization.PrivateFormat.TraditionalOpenSSL,
                encryption_algorithm=serialization.NoEncryption()
            ))
        
        # Write certificate to file
        with open(cert_file, "wb") as f:
            f.write(cert.public_bytes(serialization.Encoding.PEM))
        
        print("\n✅ Certificate generated successfully!")
        print(f"\n📜 Certificate: {cert_file}")
        print(f"🔑 Private Key: {key_file}")
        print(f"🌐 Valid for IP: {local_ip}")
        print(f"🌐 Also valid for: localhost")
        print(f"⏰ Valid for: 365 days")
        
        print("\n" + "=" * 60)
        print("📋 NEXT STEPS:")
        print("=" * 60)
        print("\n1. Cập nhật file .env (nếu chưa có):")
        print("   HTTPS_ENABLED=true")
        print("   SSL_CERT_FILE=certs/cert.pem")
        print("   SSL_KEY_FILE=certs/key.pem")
        print(f"   BACKEND_URL=https://{local_ip}:8000")
        
        print("\n2. Chạy backend với HTTPS:")
        print("   python run_https.py")
        print("   hoặc:")
        print(f"   python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --ssl-keyfile {key_file} --ssl-certfile {cert_file}")
        
        print("\n3. Trong Flutter app:")
        print(f"   - Đổi URL từ http:// sang https://")
        print(f"   - URL mới: https://{local_ip}:8000")
        print("   - Code đã có HttpOverrides, không cần config thêm!")
        
        print("\n4. Test:")
        print(f"   Truy cập: https://{local_ip}:8000/docs")
        print("   (Browser sẽ cảnh báo - bình thường, nhấn 'Advanced' -> 'Proceed')")
        print("=" * 60)
        
        # Tạo file .env.https mẫu
        env_sample = certs_dir.parent / ".env.https.sample"
        with open(env_sample, "w") as f:
            f.write(f"""# HTTPS Configuration Sample
# Copy these settings to your .env file

HTTPS_ENABLED=true
SSL_CERT_FILE=certs/cert.pem
SSL_KEY_FILE=certs/key.pem
BACKEND_URL=https://{local_ip}:8000

# Database settings (giữ nguyên từ .env hiện tại)
# DATABASE_URL=mysql+pymysql://user:password@host:3306/rubik_master

# Remember to update your Flutter app with the new HTTPS URL!
""")
        print(f"\n💡 Sample config saved to: {env_sample}")
        print(f"   Copy settings to your .env file")
        
    except Exception as e:
        print(f"\n❌ Error generating certificate: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    try:
        generate_certificate_python()
    except KeyboardInterrupt:
        print("\n\n⚠️  Cancelled by user")
        sys.exit(0)
    except Exception as e:
        print(f"\n❌ Unexpected error: {e}")
        sys.exit(1)
