FROM python:3.12-alpine AS builder
WORKDIR /build
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

FROM python:3.12-alpine
WORKDIR /app
RUN apk upgrade --no-cache \
    && apk add --no-cache ca-certificates \
    && addgroup -g 10001 -S app \
    && adduser -u 10001 -S -G app -s /sbin/nologin app
COPY --from=builder /install/ /usr/local/
COPY --chown=app:app . .
USER app
ENV CART_PERSISTENCE_PROVIDER=in-memory
ENV PORT=8080
EXPOSE 8080
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port $PORT"]
