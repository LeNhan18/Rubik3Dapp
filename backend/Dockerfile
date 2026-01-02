FROM python:3.10-slim

WORKDIR /app

# Copy requirements first for better caching
COPY app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy all application code into /app/app/ directory
# This creates the structure: /app/app/main.py, /app/app/config.py, etc.
# So imports like "from app.config" will work
COPY app app/

# Set PYTHONPATH to include /app so imports work
ENV PYTHONPATH=/app

# Run uvicorn with app.main:app (module path)
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
