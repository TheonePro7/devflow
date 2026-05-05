#!/usr/bin/env bash
# Run gitnexus commands via Docker (bypasses Windows tree-sitter SIGSEGV).
# Wraps ghcr.io/abhigyanpatwari/gitnexus:latest so analyze/context/impact
# run inside a Linux container where tree-sitter native modules work.
#
# Usage:
#   ./scripts/gitnexus-docker.sh analyze [--force]
#   ./scripts/gitnexus-docker.sh context <symbol> [--repo <name>]
#   ./scripts/gitnexus-docker.sh impact <symbol> [--depth 2]
#   ./scripts/gitnexus-docker.sh query "<search>"
#   ./scripts/gitnexus-docker.sh status

set -euo pipefail

IMAGE="ghcr.io/abhigyanpatwari/gitnexus:latest"
REPO="$(pwd)"
CLI="node /app/gitnexus/dist/cli/index.js"

CMD="${1:-help}"
shift 2>/dev/null || true

# Check Docker
if ! docker ps >/dev/null 2>&1; then
  echo "[FAIL] Docker is not running. Install/start Docker Desktop or use native gitnexus." >&2
  exit 1
fi

# Pull if needed
if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  echo "[INFO] Pulling gitnexus Docker image (first run only)..."
  docker pull "$IMAGE" >/dev/null
fi

case "$CMD" in
  analyze)
    FORCE=""
    for arg in "$@"; do
      [ "$arg" = "--force" ] && FORCE="--force"
    done
    docker run --rm -v "$REPO:/repo" --entrypoint sh "$IMAGE" -c "$CLI analyze /repo $FORCE 2>&1"
    echo "[PASS] gitnexus analyze complete"
    ;;
  context)
    SYMBOL="${1:-}"
    [ -z "$SYMBOL" ] && echo "Usage: gitnexus-docker context <symbol> [--repo <name>]" >&2 && exit 1
    EXTRA=""
    [ "$#" -ge 3 ] && [ "$2" = "--repo" ] && EXTRA="--repo $3"
    docker run --rm -v "$REPO:/repo" --entrypoint sh "$IMAGE" -c \
      "$CLI analyze /repo --force 2>&1 | tail -1 && $CLI context $EXTRA $SYMBOL --repo /repo 2>&1"
    ;;
  impact)
    SYMBOL="${1:-}"
    [ -z "$SYMBOL" ] && echo "Usage: gitnexus-docker impact <symbol> [--depth 2]" >&2 && exit 1
    shift
    DEPTH=""
    while [ "$#" -gt 0 ]; do
      [ "$1" = "--depth" ] && DEPTH="--depth $2" && shift 2
    done
    docker run --rm -v "$REPO:/repo" --entrypoint sh "$IMAGE" -c \
      "$CLI analyze /repo --force 2>&1 | tail -1 && $CLI impact $DEPTH $SYMBOL --repo /repo 2>&1"
    ;;
  query)
    QUERY="$*"
    [ -z "$QUERY" ] && echo "Usage: gitnexus-docker query <search-text>" >&2 && exit 1
    docker run --rm -v "$REPO:/repo" --entrypoint sh "$IMAGE" -c \
      "$CLI analyze /repo --force 2>&1 | tail -1 && $CLI query --repo /repo '$QUERY' 2>&1"
    ;;
  status)
    if [ -f ".gitnexus/meta.json" ]; then
      NODES=$(jq -r '.stats.nodes // "?"' .gitnexus/meta.json 2>/dev/null || echo "?")
      EDGES=$(jq -r '.stats.edges // "?"' .gitnexus/meta.json 2>/dev/null || echo "?")
      CLUSTERS=$(jq -r '.stats.communities // "?"' .gitnexus/meta.json 2>/dev/null || echo "?")
      INDEXED=$(jq -r '.indexedAt // "?"' .gitnexus/meta.json 2>/dev/null || echo "?")
      echo "gitnexus index: $NODES nodes, $EDGES edges, $CLUSTERS clusters"
      echo "  indexed: $INDEXED"
    else
      echo "no gitnexus index found — run 'gitnexus-docker analyze --force'" >&2
    fi
    ;;
  *)
    echo "Usage: $0 {analyze|context|impact|query|status} [args...]" >&2
    exit 1
    ;;
esac
