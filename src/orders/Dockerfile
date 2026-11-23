FROM golang:1.24
WORKDIR /app
RUN groupadd --gid 10001 app && useradd --uid 10001 --gid app --shell /usr/sbin/nologin --create-home app
COPY --chown=app:app . .
RUN go mod download && go build -o orders . \
    && chown app:app orders
USER app
EXPOSE 8080
CMD ["./orders"]
