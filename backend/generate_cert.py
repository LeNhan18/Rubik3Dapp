"""
Script tự động tạo Self-Signed Certificate cho HTTPS Development
Tự động chọn phương thức phù hợp: OpenSSL hoặc Python cryptography
Hoàn toàn miễn phí và dễ sử dụng
"""

import os
import socket
import subprocess
import sys
from pathlib import Path

def check_openssl():
    """Kiểm tra xem OpenSSL có available không"""
    try:
        result = subprocess.run(
            ["openssl", "version"],
            capture_output=True,
            text=True,
            timeout=5
        )
        return result.returncode == 0
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return False

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

def generate_certificate():
    """Generate self-signed certificate"""
    # Tạo thư mục certs nếu chưa có
    certs_dir = Path(__file__).parent / "certs"
    certs_dir.mkdir(exist_ok=True)
    
    cert_file = certs_dir / "cert.pem"
    key_file = certs_dir / "key.pem"
    
    # Lấy IP của máy
    local_ip = get_local_ip()
    
    print("=" * 60)
    print(" RUBIK MASTER - HTTPS Certificate Generator")
    print("=" * 60)
    print(f"\n Detected IP Address: {local_ip}")
    print(f" Certificate location: {certs_dir}")
    
    # Kiểm tra nếu certificate đã tồn tại
    if cert_file.exists() and key_file.exists():
        response = input("\n  Certificate already exists. Regenerate? (y/N): ")
        if response.lower() != 'y':
            print(" Using existing certificates")
            return
    
    print("\n Generating self-signed certificate...")
    print(" This may take a few seconds...")
    
    # Tạo subject string cho certificate
    subject = f"/C=VN/ST=HaNoi/L=HaNoi/O=RubikMasterDev/CN={local_ip}"
    
    # Command để generate certificate
    cmd = [
        "openssl", "req",
        "-x509",
        "-newkey", "rsa:4096",
        "-keyout", str(key_file),
        "-out", str(cert_file),
        "-days", "365",
        "-nodes",
        "-subj", subject
    ]
    
    try:
        # Chạy openssl command
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            check=True
        )
        
        print("\n Certificate generated successfully!")
        print(f"\n Certificate: {cert_file}")
        print(f" Private Key: {key_file}")
        print(f" Valid for IP: {local_ip}")
        print(f" Valid for: 365 days")
        
        print("\n" + "=" * 60)
        print(" NEXT STEPS:")
        print("=" * 60)
        print("\n1. Cập nhật file .env:")
        print("   HTTPS_ENABLED=true")
        print("   SSL_CERT_FILE=certs/cert.pem")
        print("   SSL_KEY_FILE=certs/key.pem")
        print(f"   BACKEND_URL=https://{local_ip}:8000")
        
        print("\n2. Chạy backend với HTTPS:")
        print("   python run_https.py")
        print("   hoặc:")
        print(f"   py -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --ssl-keyfile {key_file} --ssl-certfile {cert_file}")
        
        print("\n3. Trong Flutter app:")
        print(f"   - Đổi URL: https://{local_ip}:8000")
        print("   - Thêm HttpOverrides (xem HTTPS_SETUP.md)")
        
        print("\n4. Test:")
        print(f"   Truy cập: https://{local_ip}:8000/docs")
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

# Remember to update your Flutter app with the new HTTPS URL!
""")
        print(f"\n Sample config saved to: {env_sample}")
        
    except subprocess.CalledProcessError as e:
        print("\nError generating certificate:")
        print(f"   {e.stderr}")
        return False
    except FileNotFoundError:
        return False

def generate_certificate_python():
    """Generate certificate using Python cryptography library"""
    try:
        from datetime import datetime, timedelta, timezone
        import ipaddress
        from cryptography import x509
        from cryptography.x509.oid import NameOID
        from cryptography.hazmat.primitives import hashes
        from cryptography.hazmat.primitives.asymmetric import rsa
        from cryptography.hazmat.primitives import serialization
    except ImportError:
        print("\n Python cryptography library not found!")
        print("\n Install it with:")
        print("   pip install cryptography")
        print("\n   (It should already be in requirements.txt)")
        return False
    
    # Tạo thư mục certs nếu chưa có
    certs_dir = Path(__file__).parent / "certs"
    certs_dir.mkdir(exist_ok=True)
    
    cert_file = certs_dir / "cert.pem"
    key_file = certs_dir / "key.pem"
    local_ip = get_local_ip()
    
    print("\n Using Python cryptography library...")
    print(" Generating 4096-bit RSA key (this may take 10-30 seconds)...")
    
    try:
        # Generate private key
        private_key = rsa.generate_private_key(
            public_exponent=65537,
            key_size=4096,
        )
        
        # Create certificate
        subject = issuer = x509.Name([
            x509.NameAttribute(NameOID.COUNTRY_NAME, "VN"),
            x509.NameAttribute(NameOID.STATE_OR_PROVINCE_NAME, "HaNoi"),
            x509.NameAttribute(NameOID.LOCALITY_NAME, "HaNoi"),
            x509.NameAttribute(NameOID.ORGANIZATION_NAME, "RubikMasterDev"),
            x509.NameAttribute(NameOID.COMMON_NAME, local_ip),
        ])
        
        cert = x509.CertificateBuilder().subject_name(
            subject
        ).issuer_name(
            issuer
        ).public_key(
            private_key.public_key()
        ).serial_number(
            x509.random_serial_number()
        ).not_valid_before(
            datetime.now(timezone.utc)
        ).not_valid_after(
            datetime.now(timezone.utc) + timedelta(days=365)
        ).add_extension(
            x509.SubjectAlternativeName([
                x509.DNSName("localhost"),
                x509.DNSName("*.localhost"),
                x509.IPAddress(ipaddress.IPv4Address(local_ip)),
            ]),
            critical=False,
        ).sign(private_key, hashes.SHA256())
        
        # Write files
        with open(key_file, "wb") as f:
            f.write(private_key.private_bytes(
                encoding=serialization.Encoding.PEM,
                format=serialization.PrivateFormat.TraditionalOpenSSL,
                encryption_algorithm=serialization.NoEncryption()
            ))
        
        with open(cert_file, "wb") as f:
            f.write(cert.public_bytes(serialization.Encoding.PEM))
        
        print("\n Certificate generated successfully!")
        print(f"\n Certificate: {cert_file}")
        print(f" Private Key: {key_file}")
        print(f" Valid for IP: {local_ip}")
        print(f" Also valid for: localhost")
        print(f" Valid for: 365 days")
        
        return True
        
    except Exception as e:
        print(f"\n Error: {e}")
        return False

def print_next_steps(local_ip, cert_file, key_file):
    """In hướng dẫn các bước tiếp theo"""
    print("\n" + "=" * 60)
    print(" NEXT STEPS:")
    print("=" * 60)
    print("\n1. Chạy backend với HTTPS:")
    print("   python run_https.py")
    
    print("\n2. Trong Flutter app:")
    print(f"   - Đổi URL: https://{local_ip}:8000")
    print("   - Code đã config sẵn, không cần làm gì thêm!")
    
    print("\n3. Test:")
    print(f"   https://{local_ip}:8000/docs")
    print("=" * 60)

def main():
    """Main function với fallback logic"""
    certs_dir = Path(__file__).parent / "certs"
    certs_dir.mkdir(exist_ok=True)
    
    cert_file = certs_dir / "cert.pem"
    key_file = certs_dir / "key.pem"
    local_ip = get_local_ip()
    
    print("=" * 60)
    print(" RUBIK MASTER - HTTPS Certificate Generator")
    print("=" * 60)
    print(f"\n Detected IP Address: {local_ip}")
    print(f" Certificate location: {certs_dir}")
    
    # Kiểm tra certificate đã tồn tại
    if cert_file.exists() and key_file.exists():
        response = input("\n  Certificate already exists. Regenerate? (y/N): ")
        if response.lower() != 'y':
            print(" Using existing certificates")
            print(f" Certificate: {cert_file}")
            print(f" Private Key: {key_file}")
            return
    
    print("\n Checking available methods...")
    
    # Thử OpenSSL trước
    if check_openssl():
        print(" OpenSSL found - using OpenSSL (faster)")
        success = generate_certificate_openssl()
        if success:
            print_next_steps(local_ip, cert_file, key_file)
            return
    
    # Fallback sang Python cryptography
    print("  OpenSSL not available - using Python cryptography")
    success = generate_certificate_python()
    
    if success:
        print_next_steps(local_ip, cert_file, key_file)
    else:
        print("\n All methods failed!")
        print("\n Try:")
        print("   1. pip install cryptography")
        print("   2. Install OpenSSL:")
        print("      - Git for Windows (includes OpenSSL)")
        print("      - https://slproweb.com/products/Win32OpenSSL.html")
        sys.exit(1)

def generate_certificate_openssl():
    """Generate certificate using OpenSSL command"""
    certs_dir = Path(__file__).parent / "certs"
    cert_file = certs_dir / "cert.pem"
    key_file = certs_dir / "key.pem"
    local_ip = get_local_ip()
    
    print("\n Generating with OpenSSL...")
    print(" This may take a few seconds...")
    
    subject = f"/C=VN/ST=HaNoi/L=HaNoi/O=RubikMasterDev/CN={local_ip}"
    
    cmd = [
        "openssl", "req",
        "-x509",
        "-newkey", "rsa:4096",
        "-keyout", str(key_file),
        "-out", str(cert_file),
        "-days", "365",
        "-nodes",
        "-subj", subject
    ]
    
    try:
        subprocess.run(cmd, capture_output=True, text=True, check=True)
        print(" Certificate generated successfully!")
        print(f" Certificate: {cert_file}")
        print(f" Private Key: {key_file}")
        print(f" Valid for IP: {local_ip}")
        print(f" Valid for: 365 days")
        return True
    except subprocess.CalledProcessError as e:
        print(f" OpenSSL error: {e.stderr}")
        return False

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n  Cancelled by user")
        sys.exit(0)
    except Exception as e:
        print(f"\n Unexpected error: {e}")
        sys.exit(1)
