import sys
import os
sys.path.insert(0, 'E:\\flutter\\test\\rubik\\Rubik3Dapp\\backend')
os.chdir('E:\\flutter\\test\\rubik\\Rubik3Dapp\\backend')

import uvicorn

if __name__ == "__main__":
    print("🚀 Starting Rubik Master Backend")
    print("📍 Server: http://0.0.0.0:8000")
    print("📖 API Docs: http://localhost:8000/docs")
    print("Press Ctrl+C to stop\n")
    try:
        # Use string import to avoid module loading issues
        uvicorn.run(
            "app.main:app",
            host="0.0.0.0",
            port=8000,
            log_level="info",
            reload=False
        )
    except KeyboardInterrupt:
        print("\n\n👋 Server stopped by user")
    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback
        traceback.print_exc()
