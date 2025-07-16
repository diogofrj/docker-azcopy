# Dockerfile for AzCopy - Optimized Build
# Multi-stage build for minimal final image size
# Author: Diogo Fernandes <dfs@outlook.com.br>

ARG GO_VERSION=1.24
ARG ALPINE_VERSION=3.19
ARG TARGETARCH

# =============================================================================
# Build Stage: Compile AzCopy from source
# =============================================================================
FROM golang:${GO_VERSION}-alpine AS builder

# Install build dependencies
RUN apk add --no-cache \
    build-base \
    ca-certificates \
    git \
    curl \
    && rm -rf /var/cache/apk/*

# Set build environment
ENV GOARCH=${TARGETARCH} \
    GOOS=linux \
    CGO_ENABLED=0 \
    GO111MODULE=on

WORKDIR /build

# Get latest stable AzCopy version
RUN AZCOPY_VERSION=$(curl -sL https://api.github.com/repos/Azure/azure-storage-azcopy/releases/latest | \
    grep -o '"tag_name": "v[^"]*"' | \
    sed 's/"tag_name": "v//; s/"//' | \
    grep -v -E '(preview|Preview|beta|alpha)' | \
    head -n 1) && \
    echo "Building AzCopy version: $AZCOPY_VERSION" && \
    curl -sL "https://github.com/Azure/azure-storage-azcopy/archive/v${AZCOPY_VERSION}.tar.gz" | \
    tar -xz --strip-components=1

# Build AzCopy with optimizations
RUN go mod download && \
    go build -a -installsuffix cgo \
    -ldflags="-w -s -X main.version=$(cat VERSION)" \
    -o azcopy . && \
    chmod +x azcopy && \
    ./azcopy --version

# =============================================================================
# Release Stage: Minimal runtime image
# =============================================================================
FROM alpine:${ALPINE_VERSION} AS release

# Install runtime dependencies
RUN apk add --no-cache \
    ca-certificates \
    tzdata \
    bash \
    && rm -rf /var/cache/apk/*

# Create non-root user for security
RUN addgroup -g 1000 -S azcopy && \
    adduser -u 1000 -S azcopy -G azcopy

# Copy binary from builder stage
COPY --from=builder /build/azcopy /usr/local/bin/azcopy

# Set up working directory
WORKDIR /workspace
RUN chown -R azcopy:azcopy /workspace

# Labels for metadata
LABEL maintainer="Diogo Fernandes <dfs@outlook.com.br>" \
      org.opencontainers.image.title="AzCopy" \
      org.opencontainers.image.description="Azure Storage AzCopy tool in Alpine Linux" \
      org.opencontainers.image.vendor="iachero" \
      org.opencontainers.image.source="https://github.com/diogofrj/docker-azcopy.git" \
      org.opencontainers.image.licenses="MIT"

# Switch to non-root user
USER azcopy

# Default command
ENTRYPOINT ["/usr/local/bin/azcopy"]
CMD ["--help"]
