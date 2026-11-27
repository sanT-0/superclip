# SupoClip Quick Start Guide

Run SupoClip with Docker in just one command!

## Prerequisites

1. **Docker Desktop** (or Docker Engine + Compose v2) installed and running
2. **API Keys** (get these from the providers):
   - [AssemblyAI API Key](https://www.assemblyai.com/) (required for transcription)
   - **Google AI API Key** (default provider for clip selection)
     - [Google AI Studio](https://makersuite.google.com/app/apikey)
   - Optional AI providers (if not using Google):
     - [OpenAI API Key](https://platform.openai.com/api-keys)
     - [Anthropic API Key](https://console.anthropic.com/)
     - [OpenRouter API Key](https://openrouter.ai/keys)

## Quick Start (Single Command)

```bash
./start.sh
```

That's it! The script will:
- Check prerequisites
- Build Docker images
- Start all services with health checks
- Show you where to access the app

## Quick Reference Card

| Task | Command |
|------|---------|
| Start SupoClip | `cd ~/projects/supoclip && make up` |
| Stop SupoClip | `cd ~/projects/supoclip && make down` |
| Restart everything | `cd ~/projects/supoclip && make restart` |
| Restart only frontend | `cd ~/projects/supoclip && make frontend-only` |
| Check health | `cd ~/projects/supoclip && make status` |
| View logs | `cd ~/projects/supoclip && make logs` |
| Check memory/processes | `cd ~/projects/supoclip && make optimize-check` |
| Open in browser | `http://localhost:3107` (or the port set by `FRONTEND_PORT` in `.env`) |

## First Time Setup

### 1. Configure Environment Variables

Copy the template and edit the `.env` file in the project root:

```bash
cp .env.example .env
# Edit .env with your API keys
```

Required keys in `.env`:

```bash
# Required for video transcription
ASSEMBLY_AI_API_KEY=your_assemblyai_key_here

# Default: Google Gemini for clip selection (requires GOOGLE_API_KEY)
GOOGLE_API_KEY=your_google_key_here
LLM=google-gla:gemini-3.8-flash

# Optional: models tried in order when the primary one fails
LLM_FALLBACK_MODELS=google-gla:gemini-3.5-flash-lite,google-gla:gemini-2.5-flash,google-gla:gemini-2.5-flash-lite

# Optional: Amazon SES for subscription lifecycle emails
# Required if you want hosted billing emails when SELF_HOST=false
# AWS_REGION=us-east-1
# AWS_ACCESS_KEY_ID=your_aws_access_key_id
# AWS_SECRET_ACCESS_KEY=your_aws_secret_access_key
# SES_FROM_EMAIL="SupoClip <onboarding@example.com>"
```

### 2. Start SupoClip

```bash
./start.sh
```

### 3. Access the Application

- **Frontend**: http://localhost:3107
- **Backend API**: http://localhost:8001
- **API Documentation**: http://localhost:8001/docs
- **MCP Server**: http://localhost:9100

These are the defaults from `.env.example`. If a port is already taken on your machine, set `FRONTEND_PORT`, `BACKEND_PORT`, `SUPOCLIP_MCP_PORT`, or `REDIS_HOST_PORT` in `.env` and use those ports instead. The containers keep listening on 3107, 8000, and 6379 internally.

## Manual Docker Commands

If you prefer to use Docker commands directly:

```bash
# Start all services
docker compose up -d

# View logs
docker compose logs -f

# Stop all services
docker compose down

# Rebuild after code changes
docker compose up -d --build

# Full reset (WARNING: deletes all data!)
docker compose down -v
docker compose up -d
```

## Environment Configuration

### Required Variables

| Variable | Description | Where to Get |
|----------|-------------|--------------|
| `ASSEMBLY_AI_API_KEY` | Speech-to-text transcription | https://www.assemblyai.com/ |
| `GOOGLE_API_KEY` | Google Gemini models (default) | https://makersuite.google.com/app/apikey |
| `LLM` | AI model identifier | e.g., `google-gla:gemini-3.8-flash` |

### Optional Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `LLM_FALLBACK_MODELS` | Gemini order | Comma-separated models tried when the primary fails |
| `WHISPER_MODEL_SIZE` | `medium` | Whisper model size (tiny/base/small/medium/large) |
| `BETTER_AUTH_SECRET` | dev secret | Auth secret (change in production!) |
| `OPENAI_API_KEY` | - | For OpenAI models |
| `ANTHROPIC_API_KEY` | - | For Claude models |
| `OPENROUTER_API_KEY` | - | For `openrouter:*` models |
| `AWS_REGION` | `us-east-1` | Optional in self-host mode, required for hosted billing emails |
| `AWS_ACCESS_KEY_ID` | - | Optional in self-host mode, required for hosted billing emails |
| `AWS_SECRET_ACCESS_KEY` | - | Optional in self-host mode, required for hosted billing emails |
| `SES_FROM_EMAIL` | `SupoClip <onboarding@example.com>` | Verified sender for backend subscription emails |

### Hosted Billing Email Setup

If you enable hosted monetization with `SELF_HOST=false`, set these as well:

| Variable | Description |
|----------|-------------|
| `BACKEND_AUTH_SECRET` | Shared secret used by frontend API routes to call the backend |
| `STRIPE_SECRET_KEY` | Stripe server-side API key |
| `STRIPE_WEBHOOK_SECRET` | Stripe webhook signing secret |
| `STRIPE_PRO_PRICE_ID` | Stripe price ID for the $9.99/month Pro subscription |
| `STRIPE_SCALE_PRICE_ID` | Stripe price ID for the $24.99/month Creator subscription |
| `STRIPE_PRO_ANNUAL_PRICE_ID` | Stripe price ID for the $99.90/year Pro subscription |
| `STRIPE_SCALE_ANNUAL_PRICE_ID` | Stripe price ID for the $249.90/year Creator subscription |
| `STRIPE_PRICE_ID` | Legacy fallback Stripe price ID for the Pro subscription |
| `PRO_PLAN_MINUTE_LIMIT` | Pro monthly allowance in minutes of source video, usually `600` |
| `SCALE_PLAN_MINUTE_LIMIT` | Creator monthly allowance in minutes of source video, usually `1500` |
| `AWS_REGION` | AWS region used for Amazon SES, default `us-east-1` |
| `AWS_ACCESS_KEY_ID` | AWS access key ID used to send subscription emails via Amazon SES |
| `AWS_SECRET_ACCESS_KEY` | AWS secret access key used to send subscription emails via Amazon SES |
| `SES_FROM_EMAIL` | Verified sender address used for subscription emails |

The billing flow sends:
- A thank-you email after `checkout.session.completed`
- A cancellation email after `customer.subscription.deleted`

## Supported AI Models

### Google (Default)
```bash
LLM=google-gla:gemini-3.8-flash
LLM_FALLBACK_MODELS=google-gla:gemini-3.5-flash-lite,google-gla:gemini-2.5-flash,google-gla:gemini-2.5-flash-lite
```
- Fast, cost-effective
- Automatic fallback chain on rate limits/outages

### OpenAI
```bash
LLM=openai:gpt-5.2
```

### Anthropic
```bash
LLM=anthropic:claude-4-sonnet
```

### OpenRouter
```bash
LLM=openrouter:anthropic/claude-sonnet-5.5
OPENROUTER_API_KEY=your_key
OPENROUTER_FALLBACK_MODEL=openai/gpt-6-luna
```

## Service Ports

| Service | Host Port | Container Port | `.env` variable | What it does |
|---------|-----------|----------------|-----------------|--------------|
| Frontend (Next.js) | 3107 | 3107 | `FRONTEND_PORT` | Web UI, auth, and the `/api/*` routes that proxy the backend |
| Backend (FastAPI) | 8001 | 8000 | `BACKEND_PORT` | REST API, `/docs`, and the media endpoints |
| MCP Server | 9100 | 9100 | `SUPOCLIP_MCP_PORT` | MCP endpoint for Claude/ChatGPT connectors and the `mcp/` client |
| PostgreSQL | internal | 5432 | – | Users, tasks, clips, billing state |
| Redis | 6379 | 6379 | `REDIS_HOST_PORT` | Job queues for the video and AI workers |
| Workers | internal | – | – | `worker`, `cron`, and `ai-worker` containers process jobs from Redis |

All services share the `supoclip-network` Docker network and have health checks.

## What Happens When You Run `./start.sh`?

1. Checks that `.env` exists and contains the required API keys
2. Verifies Docker is running
3. Builds the images (first run: about 5–10 minutes)
4. Starts PostgreSQL; on a fresh volume `init.sql` creates the schema
5. Starts Redis
6. Starts the backend, which applies its own SQL migrations and waits until healthy
7. Starts the MCP server
8. Starts the frontend, which runs `prisma generate` and `prisma migrate deploy` before `next dev`, so the Prisma schema stays in sync
9. Starts the video worker, cron worker, and AI worker
10. Prints the URLs to open

## Troubleshooting

### Services not starting?

1. **Check Docker is running**:
   ```bash
   docker info
   ```

2. **View service logs**:
   ```bash
   docker compose logs -f
   ```

3. **Check service health**:
   ```bash
   docker compose ps
   ```

### "Failed to sign in" or a 500 on `/api/auth/sign-in/email`?

This means the database schema is behind `frontend/prisma/schema.prisma` (usually a fresh volume created by an older `init.sql`). Check the frontend logs:

```bash
docker compose logs frontend | grep -i "does not exist"
```

Fix it without losing data by applying the missing migrations:

```bash
docker compose exec frontend pnpm exec prisma migrate deploy
```

If the database has no Prisma migration history, the frontend entrypoint baselines it automatically on the next start. A full reset also works but deletes all data:

```bash
docker compose down -v  # WARNING: deletes users, tasks and clips
docker compose up -d
```

### API Keys not working?

1. Verify keys are set in `.env` file
2. Ensure no extra spaces around the `=` sign
3. Restart services after changing `.env`:
   ```bash
   docker compose down
   docker compose up -d
   ```

### Database issues?

Reset the database:
```bash
docker compose down -v  # WARNING: This deletes all data!
docker compose up -d
```

### Port conflicts?

If ports 3107, 8001, 9100, or 6379 are already in use, edit `.env`:
```bash
FRONTEND_PORT=3108
BACKEND_PORT=8002
SUPOCLIP_MCP_PORT=9101
REDIS_HOST_PORT=6381
```
Also update `NEXT_PUBLIC_APP_URL`, `NEXT_PUBLIC_API_URL`, `BETTER_AUTH_URL`, `BETTER_AUTH_TRUSTED_ORIGINS`, and `CORS_ORIGINS` so they use the new host ports.

## Architecture

SupoClip runs 7 Docker containers:

1. **Frontend** (Next.js 15) - host 3107 → container 3107. Pages, Better Auth, and server routes that call the backend internally at `http://backend:8000`.
2. **Backend** (FastAPI + Python) - host 8001 → container 8000. REST API, transcription, clip generation, billing.
3. **Worker** - runs the video pipeline and scheduled cron jobs queued in Redis.
4. **AI worker** - AI editing requests.
5. **MCP server** - host 9100 → container 9100. Model Context Protocol access to the API.
6. **PostgreSQL** - durable state: users, tasks, clips, billing.
7. **Redis** - job queues and cache.

All services are connected via the `supoclip-network` Docker network with health checks and auto-restart policies.

## Production Deployment

For production use:

1. Change `BETTER_AUTH_SECRET` to a secure random string
2. Use strong database passwords (override `POSTGRES_PASSWORD` in `.env`)
3. Enable HTTPS with a reverse proxy (nginx/Caddy)
4. Set up persistent volumes for data
5. Configure backup strategies
6. Set `DISABLE_SIGN_UP=true` to lock registration

## Next Steps

- Read the full documentation in `CLAUDE.md`
- Check out the API docs at http://localhost:8001/docs
- View example clips in the frontend
- Customize fonts by adding TTF files to `backend/fonts/`
- Add transition effects by adding MP4 files to `backend/transitions/`

## Getting Help

- Check logs: `docker compose logs -f`
- View API documentation: http://localhost:8001/docs
- Report issues: Create a GitHub issue with logs and error messages