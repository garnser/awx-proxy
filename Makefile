# ==========================================
# Project metadata
# ==========================================
PROJECT_NAME := awx-proxy
REGISTRY ?= local

VERSION := $(shell cat VERSION)
GIT_SHA := $(shell git rev-parse --short HEAD 2>/dev/null || echo unknown)
BUILD_DATE := $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")

# ==========================================
# Compose
# ==========================================
COMPOSE_FILE := deploy/docker-compose.yml

# ==========================================
# Images
# ==========================================
API_IMAGE := $(REGISTRY)/$(PROJECT_NAME)-api
ADMIN_IMAGE := $(REGISTRY)/$(PROJECT_NAME)-admin
EXECUTOR_IMAGE := $(REGISTRY)/$(PROJECT_NAME)-executor
NGINX_IMAGE := $(REGISTRY)/$(PROJECT_NAME)-nginx

# Common docker labels
DOCKER_LABELS := \
	--label org.opencontainers.image.title=$(PROJECT_NAME) \
	--label org.opencontainers.image.version=$(VERSION) \
	--label org.opencontainers.image.revision=$(GIT_SHA) \
	--label org.opencontainers.image.created=$(BUILD_DATE)

# ==========================================
# Help
# ==========================================
.PHONY: help
help:
	@echo ""
	@echo "Targets:"
	@echo "  build            Build all images (versioned)"
	@echo "  build-api        Build API image"
	@echo "  build-admin      Build Admin image"
	@echo "  build-executor   Build Executor image"
	@echo "  build-nginx      Build Nginx image"
	@echo ""
	@echo "  up               Start stack"
	@echo "  down             Stop stack"
	@echo "  restart          Restart stack"
	@echo "  logs             Tail logs"
	@echo ""
	@echo "  migrate          Run DB migrations"
	@echo "  version          Show version info"
	@echo "  clean            Remove containers & volumes"
	@echo ""

# ==========================================
# Version helpers
# ==========================================
.PHONY: version
version:
	@echo "Version:     $(VERSION)"
	@echo "Git SHA:     $(GIT_SHA)"
	@echo "Build date:  $(BUILD_DATE)"

# ==========================================
# Build targets
# ==========================================
.PHONY: build build-api build-admin build-executor build-nginx

build: build-api build-admin build-executor build-nginx

build-api:
	docker build \
		$(DOCKER_LABELS) \
		--build-arg VERSION=$(VERSION) \
		--build-arg GIT_SHA=$(GIT_SHA) \
		-t $(API_IMAGE):$(VERSION) \
		-t $(API_IMAGE):$(VERSION)-$(GIT_SHA) \
		-t $(API_IMAGE):latest \
		app/api

build-admin:
	docker build \
		$(DOCKER_LABELS) \
		--build-arg VERSION=$(VERSION) \
		--build-arg GIT_SHA=$(GIT_SHA) \
		-t $(ADMIN_IMAGE):$(VERSION) \
		-t $(ADMIN_IMAGE):$(VERSION)-$(GIT_SHA) \
		-t $(ADMIN_IMAGE):latest \
		app/admin

build-executor:
	docker build \
		$(DOCKER_LABELS) \
		--build-arg VERSION=$(VERSION) \
		--build-arg GIT_SHA=$(GIT_SHA) \
		-t $(EXECUTOR_IMAGE):$(VERSION) \
		-t $(EXECUTOR_IMAGE):$(VERSION)-$(GIT_SHA) \
		-t $(EXECUTOR_IMAGE):latest \
		app/executor

build-nginx:
	docker build \
		$(DOCKER_LABELS) \
		-t $(NGINX_IMAGE):$(VERSION) \
		-t $(NGINX_IMAGE):$(VERSION)-$(GIT_SHA) \
		-t $(NGINX_IMAGE):latest \
		deploy/reverse-proxy

# ==========================================
# Runtime
# ==========================================
.PHONY: up down restart ps logs

up:
	docker compose -f $(COMPOSE_FILE) up -d

down:
	docker compose -f $(COMPOSE_FILE) down

restart: down up

ps:
	docker compose -f $(COMPOSE_FILE) ps

logs:
	docker compose -f $(COMPOSE_FILE) logs -f

# ==========================================
# Database
# ==========================================
.PHONY: migrate

migrate:
	docker compose -f $(COMPOSE_FILE) run --rm api alembic upgrade head

# ==========================================
# Cleanup
# ==========================================
.PHONY: clean

clean:
	docker compose -f $(COMPOSE_FILE) down -v
