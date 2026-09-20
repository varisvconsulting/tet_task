# Stage 1: Rise of Dependencies
FROM python:3.12-slim AS builder

WORKDIR /build

COPY requirements.txt .

RUN pip install \
    --no-cache-dir \
    --prefix=/install \
    -r requirements.txt

# Stage 2: Return of the runtime
FROM python:3.12-slim AS runtime

# Create non-root user with known UID
RUN useradd \
    --create-home \
    --uid 10001 \
    --shell /bin/bash \
    appuser

WORKDIR /home/appuser/app

# Copy installed Python packages from builder
COPY --from=builder /install /usr/local

# Copy application
COPY --chown=10001:10001 . .

# Run as non-root
USER 10001:10001

EXPOSE 8080

CMD ["python", "app.py"]
