FROM rust:1.86 AS builder
WORKDIR /app
RUN apt-get update && apt-get install -y cmake nasm && rm -rf /var/lib/apt/lists/*
COPY Cargo.toml ./
RUN mkdir src && echo "fn main() {}" > src/main.rs
RUN cargo build --release
RUN rm -f target/release/deps/linguagem*
COPY src ./src
RUN cargo build --release

FROM debian:bookworm-slim
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=builder /app/target/release/linguagem .
EXPOSE 3000
CMD ["./linguagem"]
