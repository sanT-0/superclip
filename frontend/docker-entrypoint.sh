#!/bin/sh
# Development frontend entrypoint.
#
# Fresh Docker volumes are seeded by init.sql, which mirrors the Prisma
# migrations but has no Prisma migration history. That makes a plain
# `prisma migrate deploy` fail with P3005, so on that error we baseline the
# existing migrations once and retry. Future migrations then apply normally.
set -e

cd /app

echo "[supoclip] Generating Prisma client"
pnpm exec prisma generate

if output=$(pnpm exec prisma migrate deploy 2>&1); then
    printf '%s\n' "$output"
else
    case "$output" in
        *P3005*|*"schema is not empty"*)
            echo "[supoclip] Database predates Prisma migration history; baselining existing migrations"
            for dir in prisma/migrations/*/; do
                name=$(basename "$dir")
                [ "$name" = "migration_lock.toml" ] && continue
                pnpm exec prisma migrate resolve --applied "$name" >/dev/null 2>&1 || true
            done

            # Warn loudly when init.sql drifts behind the Prisma schema instead
            # of letting authentication fail later with a missing column.
            drift=$(pnpm exec prisma migrate diff \
                --from-schema-datasource prisma/schema.prisma \
                --to-schema-datamodel prisma/schema.prisma \
                --script 2>/dev/null || true)
            if printf '%s' "$drift" | grep -Eq 'ADD COLUMN|CREATE TABLE'; then
                echo "[supoclip] WARNING: init.sql is behind prisma/schema.prisma. Update init.sql with:" >&2
                printf '%s\n' "$drift" | grep -E 'ADD COLUMN|CREATE TABLE' >&2
            fi

            pnpm exec prisma migrate deploy
            ;;
        *)
            printf '%s\n' "$output" >&2
            echo "[supoclip] prisma migrate deploy failed" >&2
            exit 1
            ;;
    esac
fi

exec "$@"
