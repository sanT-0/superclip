BACKEND_TEST_ENV = DATABASE_URL=$${TEST_DATABASE_URL:-$${DATABASE_URL:-postgresql+asyncpg://supoclip:supoclip_password@127.0.0.1:5432/supoclip}} REDIS_HOST=$${REDIS_HOST:-127.0.0.1} REDIS_PORT=$${REDIS_PORT:-6379}
FRONTEND_TEST_ENV = DATABASE_URL=$${TEST_DATABASE_URL:-$${DATABASE_URL:-postgresql://supoclip:supoclip_password@127.0.0.1:5432/supoclip}} BACKEND_AUTH_SECRET=$${BACKEND_AUTH_SECRET:-supoclip_test_secret} BETTER_AUTH_SECRET=$${BETTER_AUTH_SECRET:-supoclip_better_auth_test_secret} NEXT_PUBLIC_SELF_HOST=true

.PHONY: test check test-backend test-frontend test-e2e test-ci

test: test-backend test-frontend

test-backend:
	cd backend && uv sync --frozen --all-groups
	cd backend && $(BACKEND_TEST_ENV) .venv/bin/pytest

test-frontend:
	cd frontend && pnpm install --frozen-lockfile
	cd frontend && $(FRONTEND_TEST_ENV) pnpm run test:coverage

test-e2e:
	cd frontend && pnpm install --frozen-lockfile
	cd frontend && $(FRONTEND_TEST_ENV) pnpm exec playwright install --with-deps
	cd frontend && $(FRONTEND_TEST_ENV) pnpm run test:e2e

check:
	cd frontend && pnpm run lint && pnpm run typecheck

test-ci: check test-backend test-frontend test-e2e

# Docker Compose management targets
.PHONY: up down restart status logs optimize-check frontend-only

DOCKER_COMPOSE ?= docker compose

up: ## Start all SupoClip services
	$(DOCKER_COMPOSE) up -d --build

down: ## Stop all SupoClip services
	$(DOCKER_COMPOSE) down

restart: ## Restart all SupoClip services
	$(DOCKER_COMPOSE) down
	$(DOCKER_COMPOSE) up -d --build

frontend-only: ## Restart only the frontend container
	$(DOCKER_COMPOSE) stop frontend
	$(DOCKER_COMPOSE) rm -f frontend
	$(DOCKER_COMPOSE) up -d --build frontend

status: ## Show container status and health
	$(DOCKER_COMPOSE) ps
	@echo "---"
	@echo "Container health:"
	$(DOCKER_COMPOSE) ps --format "table {{.Name}}\t{{.Status}}"

logs: ## Show logs from all services
	$(DOCKER_COMPOSE) logs -f

optimize-check: ## Check for duplicate Next.js processes and memory issues
	@echo "=== Duplicate Next.js processes ==="
	@ps aux | grep next-server | grep -v grep || true
	@echo ""
	@echo "=== Docker memory usage ==="
	$(DOCKER_COMPOSE) stats --no-stream
	@echo ""
	@echo "=== System memory ==="
	free -h
	@echo ""
	@echo "=== Orphaned container processes ==="
	@docker ps -a --filter "status=exited" --format "table {{.Names}}\t{{.Status}}" || true
