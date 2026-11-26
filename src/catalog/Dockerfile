FROM golang:1.27.4-alpine AS builder
WORKDIR /src
RUN apk add --no-cache build-base
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN mkdir -p /out && CGO_ENABLED=1 go build -trimpath -ldflags="-s -w" -o /out/catalog .

FROM alpine:3.22
RUN apk upgrade --no-cache \
    && apk add --no-cache ca-certificates libgcc \
    && addgroup -S -g 10001 app \
    && adduser -S -u 10001 -G app app \
    && mkdir -p /app \
    && chown app:app /app
WORKDIR /app
COPY --from=builder --chown=app:app /out/catalog ./catalog
USER app
EXPOSE 8080
ENTRYPOINT ["./catalog"]
