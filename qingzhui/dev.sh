#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/env.sh"
command="${1:-help}"
if [ "$#" -gt 0 ]; then shift; fi

case "$command" in
  doctor)
    java -version
    mvn -version
    node --version
    npm --version
    buf --version
    docker --version
    docker compose version
    colima version
    docker info --format 'Docker server: {{.ServerVersion}}'
    ;;
  containers-start)
    dns_addresses=(223.5.5.5 1.1.1.1)
    dns_flags=()
    for address in "${dns_addresses[@]}"; do dns_flags+=(--dns "$address"); done
    colima start --vm-type vz --runtime docker --cpus 4 --memory 4 --disk 30 \
      --ssh-config=false "${dns_flags[@]}" \
      --mount "$QINGZHUI_WORKSPACE:w" "$@"
    # Some colima-core images retain a dangling systemd-resolved symlink.
    # Repair only that missing resolver inside this development VM.
    if ! colima ssh -- test -r /etc/resolv.conf 2>/dev/null; then
      colima ssh -- sudo rm -f /etc/resolv.conf
      printf 'nameserver %s\n' "${dns_addresses[@]}" | colima ssh -- sudo tee /etc/resolv.conf >/dev/null
    fi
    ;;
  containers-stop)
    exec colima stop "$@"
    ;;
  backend-build)
    cd "$QINGZHUI_BACKEND"
    exec make build AGENT=1 "$@"
    ;;
  backend-dev)
    cd "$QINGZHUI_BACKEND"
    exec make apiserver-dev AGENT=1 "$@"
    ;;
  frontend-install)
    cd "$QINGZHUI_WORKSPACE/frontend"
    exec npm ci --no-audit --no-fund "$@"
    ;;
  frontend-build)
    cd "$QINGZHUI_WORKSPACE/frontend"
    exec npm run build -- "$@"
    ;;
  frontend-dev)
    cd "$QINGZHUI_WORKSPACE/frontend"
    exec npm run serve -- --host 127.0.0.1 --port 8082 "$@"
    ;;
  upstream-fetch)
    git -C "$QINGZHUI_BACKEND" fetch upstream --tags
    git -C "$QINGZHUI_WORKSPACE/frontend" fetch upstream --tags
    ;;
  help|--help|-h)
    cat <<'EOF'
Usage: bash backend/qingzhui/dev.sh <command>

  doctor              Check local tools and Docker daemon
  containers-start    Start this workspace's Colima Docker VM
  containers-stop     Stop the VM while retaining development data
  backend-build       Build backend from source with the upstream Makefile
  backend-dev         Run backend with PostgreSQL and the 5.2.1 frontend image
  frontend-install    Install locked frontend dependencies
  frontend-build      Build frontend from source
  frontend-dev        Run frontend source with hot reload on localhost:8082
  upstream-fetch      Fetch official branches and tags into both repositories
EOF
    ;;
  *)
    printf 'Unknown command: %s\n' "$command" >&2
    exit 2
    ;;
esac
