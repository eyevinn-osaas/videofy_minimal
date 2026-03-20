#!/bin/bash
set -e

# OSC platform defaults
PORT="${PORT:-8080}"
export PORT

# Map OSC_HOSTNAME to public-facing URLs
if [ -n "$OSC_HOSTNAME" ]; then
    export NEXT_PUBLIC_CMS_BASE_URL="https://${OSC_HOSTNAME}"
    export MINIMAL_FILE_BASE_URL="https://${OSC_HOSTNAME}/api/files"
fi

# The API runs internally; CMS proxies to it via MINIMAL_DATA_API_URL
export MINIMAL_DATA_API_URL="${MINIMAL_DATA_API_URL:-http://127.0.0.1:8001}"

# API settings: allow CMS origin for CORS
CMS_ORIGIN="http://127.0.0.1:${PORT}"
if [ -n "$OSC_HOSTNAME" ]; then
    CMS_ORIGIN="https://${OSC_HOSTNAME}"
fi
export CORS_ALLOW_ORIGINS="${CORS_ALLOW_ORIGINS:-${CMS_ORIGIN}}"
export APP_BASE_URL="${APP_BASE_URL:-https://${OSC_HOSTNAME:-127.0.0.1:8001}}"

# Persistent storage: map projects and brands to /data volume
# Both services read from /app/projects and /app/brands (resolved via cwd).
# We symlink /app/projects -> /data/projects and /app/brands -> /data/brands
# so data persists across restarts.
mkdir -p /data/projects /data/brands /data/brand_assets /data/intro_outro_wipes /data/fetchers

# Replace /app/projects with a symlink to /data/projects if not already linked
if [ ! -L /app/projects ]; then
    # Copy any seed project files bundled in the image into the volume on first run
    if [ -d /app/projects ] && [ "$(ls -A /app/projects 2>/dev/null)" ]; then
        cp -rn /app/projects/. /data/projects/ 2>/dev/null || true
    fi
    rm -rf /app/projects
    ln -s /data/projects /app/projects
fi

# Replace /app/brands with a symlink to /data/brands if not already linked
if [ ! -L /app/brands ]; then
    if [ -d /app/brands ] && [ "$(ls -A /app/brands 2>/dev/null)" ]; then
        cp -rn /app/brands/. /data/brands/ 2>/dev/null || true
    fi
    rm -rf /app/brands
    ln -s /data/brands /app/brands
fi

# Replace /app/brand_assets with a symlink to /data/brand_assets if not already linked
if [ ! -L /app/brand_assets ]; then
    if [ -d /app/brand_assets ] && [ "$(ls -A /app/brand_assets 2>/dev/null)" ]; then
        cp -rn /app/brand_assets/. /data/brand_assets/ 2>/dev/null || true
    fi
    rm -rf /app/brand_assets
    ln -s /data/brand_assets /app/brand_assets
fi

# Replace /app/intro_outro_wipes with a symlink to /data/intro_outro_wipes if not already linked
if [ ! -L /app/intro_outro_wipes ]; then
    if [ -d /app/intro_outro_wipes ] && [ "$(ls -A /app/intro_outro_wipes 2>/dev/null)" ]; then
        cp -rn /app/intro_outro_wipes/. /data/intro_outro_wipes/ 2>/dev/null || true
    fi
    rm -rf /app/intro_outro_wipes
    ln -s /data/intro_outro_wipes /app/intro_outro_wipes
fi

# Replace /app/fetchers with a symlink to /data/fetchers if not already linked
if [ ! -L /app/fetchers ]; then
    if [ -d /app/fetchers ] && [ "$(ls -A /app/fetchers 2>/dev/null)" ]; then
        cp -rn /app/fetchers/. /data/fetchers/ 2>/dev/null || true
    fi
    rm -rf /app/fetchers
    ln -s /data/fetchers /app/fetchers
fi

# API uses PROJECTS_ROOT and CONFIG_ROOT env vars
export PROJECTS_ROOT="${PROJECTS_ROOT:-/data/projects}"
export CONFIG_ROOT="${CONFIG_ROOT:-/data/brands}"

exec "$@"
