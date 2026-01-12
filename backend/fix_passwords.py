"""
Script để kiểm tra và fix password hashes trong database
"""
from app.database import SessionLocal, engine
from app.models.user import User
from app.utils.security import get_password_hash
from sqlalchemy import text

def fix_passwords():
    db = SessionLocal()
    try:
        # Lấy tất cả users
        users = db.query(User).all()
        
        print(f"Found {len(users)} users in database:")
        print("-" * 60)
        
        for user in users:
            print(f"\nUser: {user.email}")
            print(f"Current password_hash: {user.password_hash[:50]}...")
            
            # Kiểm tra xem password có phải là hash không
            if not user.password_hash.startswith("$argon2") and not user.password_hash.startswith("$2b$"):
                print(f"⚠️  Password is NOT hashed (plain text or other format)")
                
                # Hỏi user có muốn hash lại không
                print(f"   Plain text password: {user.password_hash}")
                response = input(f"   Hash this password for {user.email}? (y/n): ")
                
                if response.lower() == 'y':
                    # Hash password
                    new_hash = get_password_hash(user.password_hash)
                    user.password_hash = new_hash
                    db.commit()
                    print(f"✅ Password hashed successfully!")
                    print(f"   New hash: {new_hash[:50]}...")
            else:
                print(f"✅ Password is already hashed")
        
        print("\n" + "=" * 60)
        print("Done!")
        
    except Exception as e:
        print(f"Error: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    print("=" * 60)
    print("PASSWORD HASH FIXER")
    print("=" * 60)
    fix_passwords()
