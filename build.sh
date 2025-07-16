#!/bin/bash

# Build script for AzCopy Docker image
# Author: Diogo Fernandes <dfs@outlook.com.br>

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REGISTRY="docker.io"
IMAGE_NAME="dfsrj/docker-azcopy"
BUILD_CONTEXT="."
DOCKERFILE="Dockerfile"

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" >&2
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" >&2
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Get latest AzCopy version
get_latest_version() {
    log_info "Getting latest AzCopy version..."
    local version=$(curl -sL https://api.github.com/repos/Azure/azure-storage-azcopy/releases/latest | \
        jq -r '.tag_name' | sed 's/^v//')
    
    if [ -z "$version" ]; then
        log_error "Failed to get latest AzCopy version"
        exit 1
    fi
    
    log_success "Latest AzCopy version: $version"
    echo "$version"
}

# Build image
build_image() {
    local version=$1
    local tags=("$IMAGE_NAME:$version" "$IMAGE_NAME:latest")
    
    log_info "Building Docker image for AzCopy $version..."
    
    # Build arguments for tags
    local tag_args=()
    for tag in "${tags[@]}"; do
        tag_args+=("--tag" "$tag")
    done
    
    # Use buildx explicitly since docker build is aliased to buildx
    docker buildx build \
        "${tag_args[@]}" \
        --file "$DOCKERFILE" \
        --push \
        "$BUILD_CONTEXT"
    
    log_success "Image built and pushed successfully!"
}

# Test image
test_image() {
    local version=$1
    
    log_info "Testing Docker image..."
    
    # Test version command
    log_info "Testing version command..."
    docker run --rm "$IMAGE_NAME:$version" --version
    
    # Test help command
    log_info "Testing help command..."
    docker run --rm "$IMAGE_NAME:$version" --help > /dev/null
    
    log_success "Image tests passed!"
}

# Main function
main() {
    case "${1:-help}" in
        build)
            VERSION=$(get_latest_version)
            build_image "$VERSION"
            test_image "$VERSION"
            ;;
        build-only)
            VERSION=$(get_latest_version)
            build_image "$VERSION"
            ;;
        test)
            if [ $# -ne 2 ]; then
                log_error "Usage: $0 test <version>"
                exit 1
            fi
            test_image "$2"
            ;;
        version)
            get_latest_version
            ;;
        login)
            log_info "Logging into Docker Hub..."
            docker login
            ;;
        help|--help|-h)
            cat << EOF
Usage: $0 [COMMAND]

Commands:
    build       Build, push and test Docker image with latest AzCopy version
    build-only  Build and push without testing
    test <ver>  Test specific image version
    version     Show latest AzCopy version
    login       Login to Docker Hub
    help        Show this help message

Examples:
    $0 build
    $0 build-only
    $0 test 10.26.0
    $0 version
    $0 login
EOF
            ;;
        *)
            log_error "Unknown command: $1"
            log_info "Use '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Check dependencies
check_dependencies() {
    local deps=("docker" "jq" "curl")
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            log_error "$dep is required but not installed"
            exit 1
        fi
    done
    
    log_info "All dependencies are available"
}

# Initialize
check_dependencies
main "$@"
