"""
Script để reset password cho user
"""
from app.database import SessionLocal
from app.models.user import User
from app.utils.security import get_password_hash

def reset_password(email: str, new_password: str):
    db = SessionLocal()
    try:
        user = db.query(User).filter(User.email == email).first()
        
        if not user:
            print(f"❌ User {email} not found!")
            return
        
        # Hash và update password
        user.password_hash = get_password_hash(new_password)
        db.commit()
        
        print(f"✅ Password reset successfully for {email}")
        print(f"   New password: {new_password}")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    email = input("Enter email: ")
    new_password = input("Enter new password: ")
    reset_password(email, new_password)
