# ==========================================
# Project metadata
# ==========================================
PROJECT_NAME := awx-proxy
REGISTRY ?= garnser

VERSION := $(shell cat VERSION)
GIT_SHA := $(shell git rev-parse --short HEAD 2>/dev/null || echo unknown)
BUILD_DATE := $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")

# ==========================================
# Compose
# ==========================================
COMPOSE_FILE := deploy/docker-compose.yml

# ==========================================
# Docker images
# ==========================================
API_IMAGE := $(REGISTRY)/$(PROJECT_NAME)-api
ADMIN_IMAGE := $(REGISTRY)/$(PROJECT_NAME)-admin
EXECUTOR_IMAGE := $(REGISTRY)/$(PROJECT_NAME)-executor
NGINX_IMAGE := $(REGISTRY)/$(PROJECT_NAME)-nginx

# OCI labels (applied to all images)
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
	@echo "AWX Proxy – Makefile"
	@echo ""
	@echo "Build:"
	@echo "  build              Build all images"
	@echo "  build-api          Build API image"
	@echo "  build-admin        Build Admin image"
	@echo "  build-executor     Build Executor image"
	@echo "  build-nginx        Build Nginx image"
	@echo ""
	@echo "Push / Release:"
	@echo "  push               Push all images"
	@echo "  release            Build + push all images"
	@echo ""
	@echo "Runtime:"
	@echo "  up                 Start stack"
	@echo "  down               Stop stack"
	@echo "  restart            Restart stack"
	@echo "  logs               Tail logs"
	@echo "  ps                 Show containers"
	@echo ""
	@echo "Maintenance:"
	@echo "  migrate            Run DB migrations"
	@echo "  clean              Remove containers & volumes"
	@echo ""
	@echo "Info:"
	@echo "  version            Show version info"
	@echo ""

# ==========================================
# Version info
# ==========================================
.PHONY: version
version:
	@echo "Version:     $(VERSION)"
	@echo "Git SHA:     $(GIT_SHA)"
	@echo "Build date:  $(BUILD_DATE)"
	@echo "Registry:    $(REGISTRY)"

# ==========================================
# Build targets
# ==========================================
.PHONY: build build-api build-admin build-executor build-nginx

build: build-api build-admin build-executor build-nginx

build-api:
	docker build $(DOCKER_LABELS) \
		--build-arg VERSION=$(VERSION) \
		--build-arg GIT_SHA=$(GIT_SHA) \
		--build-arg BUILD_DATE=$(BUILD_DATE) \
		-t $(API_IMAGE):$(VERSION) \
		-t $(API_IMAGE):$(VERSION)-$(GIT_SHA) \
		-t $(API_IMAGE):latest \
		app/api

build-admin:
	docker build $(DOCKER_LABELS) \
		--build-arg VERSION=$(VERSION) \
		--build-arg GIT_SHA=$(GIT_SHA) \
		--build-arg BUILD_DATE=$(BUILD_DATE) \
		-t $(ADMIN_IMAGE):$(VERSION) \
		-t $(ADMIN_IMAGE):$(VERSION)-$(GIT_SHA) \
		-t $(ADMIN_IMAGE):latest \
		app/admin

build-executor:
	docker build $(DOCKER_LABELS) \
		--build-arg VERSION=$(VERSION) \
		--build-arg GIT_SHA=$(GIT_SHA) \
		--build-arg BUILD_DATE=$(BUILD_DATE) \
		-t $(EXECUTOR_IMAGE):$(VERSION) \
		-t $(EXECUTOR_IMAGE):$(VERSION)-$(GIT_SHA) \
		-t $(EXECUTOR_IMAGE):latest \
		app/executor

build-nginx:
	docker build $(DOCKER_LABELS) \
		--build-arg VERSION=$(VERSION) \
		--build-arg GIT_SHA=$(GIT_SHA) \
		--build-arg BUILD_DATE=$(BUILD_DATE) \
		-t $(NGINX_IMAGE):$(VERSION) \
		-t $(NGINX_IMAGE):$(VERSION)-$(GIT_SHA) \
		-t $(NGINX_IMAGE):latest \
		deploy/reverse-proxy

# ==========================================
# Push targets
# ==========================================
.PHONY: push push-api push-admin push-executor push-nginx

push: push-api push-admin push-executor push-nginx

push-api:
	docker push $(API_IMAGE):$(VERSION)
	docker push $(API_IMAGE):$(VERSION)-$(GIT_SHA)
	docker push $(API_IMAGE):latest

push-admin:
	docker push $(ADMIN_IMAGE):$(VERSION)
	docker push $(ADMIN_IMAGE):$(VERSION)-$(GIT_SHA)
	docker push $(ADMIN_IMAGE):latest

push-executor:
	docker push $(EXECUTOR_IMAGE):$(VERSION)
	docker push $(EXECUTOR_IMAGE):$(VERSION)-$(GIT_SHA)
	docker push $(EXECUTOR_IMAGE):latest

push-nginx:
	docker push $(NGINX_IMAGE):$(VERSION)
	docker push $(NGINX_IMAGE):$(VERSION)-$(GIT_SHA)
	docker push $(NGINX_IMAGE):latest

# ==========================================
# Combined release
# ==========================================
.PHONY: release
release: build push

# ==========================================
# Runtime helpers
# ==========================================
.PHONY: up down restart logs ps

up:
	docker compose -f $(COMPOSE_FILE) up -d

down:
	docker compose -f $(COMPOSE_FILE) down

restart: down up

logs:
	docker compose -f $(COMPOSE_FILE) logs -f

ps:
	docker compose -f $(COMPOSE_FILE) ps

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
