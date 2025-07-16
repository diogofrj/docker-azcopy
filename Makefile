# Makefile for AzCopy Docker image
# Author: Diogo Fernandes <dfs@outlook.com.br>

# Variables
IMAGE_NAME := dfsrj/azcopy-sync
DOCKERFILE := Dockerfile
BUILD_CONTEXT := .

# Colors
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m

# Default target
.PHONY: help
help: ## Show this help message
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2}'

.PHONY: version
version: ## Show latest AzCopy version
	@./build.sh version

.PHONY: build
build: ## Build and test Docker image
	@./build.sh build

.PHONY: build-only
build-only: ## Build Docker image without testing
	@./build.sh build-only

.PHONY: test
test: ## Test Docker image (requires version parameter: make test VERSION=10.26.0)
	@if [ -z "$(VERSION)" ]; then echo "$(RED)Error: VERSION parameter is required$(NC)"; exit 1; fi
	@./build.sh test $(VERSION)

.PHONY: login
login: ## Login to Docker Hub
	@./build.sh login

.PHONY: clean
clean: ## Remove local Docker images
	@echo "$(YELLOW)Removing local images...$(NC)"
	@docker rmi $(IMAGE_NAME):latest || true
	@docker rmi $$(docker images $(IMAGE_NAME) -q) || true
	@docker system prune -f

.PHONY: inspect
inspect: ## Inspect the latest Docker image
	@echo "$(YELLOW)Inspecting $(IMAGE_NAME):latest...$(NC)"
	@docker inspect $(IMAGE_NAME):latest

.PHONY: run
run: ## Run AzCopy container interactively
	@echo "$(YELLOW)Running $(IMAGE_NAME):latest...$(NC)"
	@docker run --rm -it $(IMAGE_NAME):latest

.PHONY: shell
shell: ## Get shell access to the container
	@echo "$(YELLOW)Opening shell in $(IMAGE_NAME):latest...$(NC)"
	@docker run --rm -it --entrypoint /bin/bash $(IMAGE_NAME):latest

.PHONY: size
size: ## Show image size
	@echo "$(YELLOW)Image size information:$(NC)"
	@docker images $(IMAGE_NAME) --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"

.PHONY: history
history: ## Show image layer history
	@echo "$(YELLOW)Image layer history:$(NC)"
	@docker history $(IMAGE_NAME):latest

.PHONY: security-scan
security-scan: ## Run security scan with trivy (requires trivy to be installed)
	@echo "$(YELLOW)Running security scan...$(NC)"
	@trivy image $(IMAGE_NAME):latest

.PHONY: quick-test
quick-test: ## Quick test of the image
	@echo "$(YELLOW)Testing AzCopy version...$(NC)"
	@docker run --rm $(IMAGE_NAME):latest --version
	@echo "$(GREEN)Quick test passed!$(NC)"

.PHONY: all
all: build test quick-test ## Build, test and quick-test (full pipeline)

# Advanced targets
.PHONY: buildx-setup
buildx-setup: ## Setup Docker buildx for multi-platform builds
	@echo "$(YELLOW)Setting up Docker buildx...$(NC)"
	@docker buildx create --use --name multiarch-builder || docker buildx use multiarch-builder
	@docker buildx inspect --bootstrap

.PHONY: buildx-build
buildx-build: buildx-setup ## Build multi-platform image using buildx
	@echo "$(YELLOW)Building multi-platform image...$(NC)"
	@VERSION=$$(./build.sh version) && \
	docker buildx build \
		--platform linux/amd64,linux/arm64 \
		--tag $(IMAGE_NAME):$$VERSION \
		--tag $(IMAGE_NAME):latest \
		--push \
		$(BUILD_CONTEXT)

.PHONY: update-readme
update-readme: ## Update README with latest version
	@echo "$(YELLOW)Updating README with latest version...$(NC)"
	@VERSION=$$(./build.sh version) && \
	sed -i.bak "s/azcopy version [0-9]\+\.[0-9]\+\.[0-9]\+/azcopy version $$VERSION/g" README.md && \
	sed -i.bak "s/Latest AzCopy: [0-9]\+\.[0-9]\+\.[0-9]\+/Latest AzCopy: $$VERSION/g" README.md && \
	rm README.md.bak && \
	echo "$(GREEN)README updated with version $$VERSION$(NC)"

# Development targets
.PHONY: dev-build
dev-build: ## Build image for development (no cache)
	@echo "$(YELLOW)Building development image...$(NC)"
	@VERSION=$$(./build.sh version) && \
	docker build --no-cache \
		--tag $(IMAGE_NAME):dev \
		--tag $(IMAGE_NAME):$$VERSION-dev \
		--file $(DOCKERFILE) \
		$(BUILD_CONTEXT)

.PHONY: dev-test
dev-test: ## Test development image
	@echo "$(YELLOW)Testing development image...$(NC)"
	@docker run --rm $(IMAGE_NAME):dev --version
	@docker run --rm $(IMAGE_NAME):dev --help > /dev/null
	@echo "$(GREEN)Development image tests passed!$(NC)"

.PHONY: watch
watch: ## Watch for changes and rebuild (requires entr)
	@echo "$(YELLOW)Watching for changes... (requires 'entr' command)$(NC)"
	@find . -name "*.dockerfile" -o -name "Dockerfile*" | entr -c make dev-build dev-test
