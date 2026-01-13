"""
Production start script for Fly.io deployment
Runs the backend with HTTP (Fly.io handles HTTPS termination)
"""

import os
import subprocess
import sys
import signal
import time

def signal_handler(signum, frame):
    print("\nReceived signal to shutdown...")
    sys.exit(0)

def main():
    # Handle graceful shutdown
    signal.signal(signal.SIGTERM, signal_handler)
    signal.signal(signal.SIGINT, signal_handler)
    
    print("=" * 60)
    print(" RUBIK MASTER BACKEND - Fly.io Production")
    print("=" * 60)
    
    # Fly.io sets PORT environment variable
    port = os.getenv("PORT", "8000")
    host = "0.0.0.0"
    
    print(f"\n Starting server on {host}:{port}")
    print(f" Environment: {os.getenv('FLY_APP_NAME', 'local')}")
    print("=" * 60)
    
    # Uvicorn command for production
    cmd = [
        "python", "-m", "uvicorn",
        "app.main:app",
        "--host", host,
        "--port", port,
        "--workers", "1",
        "--access-log"
    ]
    
    print(f"Command: {' '.join(cmd)}")
    print("=" * 60)
    
    try:
        # Start the server with proper error handling
        process = subprocess.Popen(cmd)
        process.wait()
    except KeyboardInterrupt:
        print("\nShutdown requested by user")
        if 'process' in locals():
            process.terminate()
        sys.exit(0)
    except Exception as e:
        print(f"Error starting server: {e}")
        sys.exit(1)

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n Server stopped")
        sys.exit(0)