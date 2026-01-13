"""
Production start script for Koyeb deployment
Runs the backend with HTTP (Koyeb handles HTTPS termination)
"""

import os
import sys

def main():
    print("=" * 60)
    print(" RUBIK MASTER BACKEND - Koyeb Production Server")
    print("=" * 60)
    
    # Get port from environment (Koyeb sets this)
    port = os.environ.get("PORT", "8000")
    host = "0.0.0.0"
    
    print(f"\n Starting server on {host}:{port}")
    print(f" Environment: {os.environ.get('KOYEB_ENVIRONMENT', 'production')}")
    print("=" * 60)
    
    # Run uvicorn without SSL (Koyeb handles HTTPS)
    # Use exec to replace the process (better for containers)
    cmd = [
        "python", "-m", "uvicorn", 
        "app.main:app",
        "--host", host,
        "--port", port,
        "--workers", "1"  # Single worker for small instances
    ]
    
    print(f"Command: {' '.join(cmd)}")
    
    # Use os.execvp instead of os.system for better process management
    os.execvp("python", cmd)

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n Server stopped")
        sys.exit(0)