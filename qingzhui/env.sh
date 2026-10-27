#!/usr/bin/env bash
# Source this file to select this workspace's local tools and data directories.

QINGZHUI_BACKEND="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
QINGZHUI_WORKSPACE="$(cd "$QINGZHUI_BACKEND/.." && pwd)"
QINGZHUI_RUNTIME="$QINGZHUI_WORKSPACE/.runtime"
export QINGZHUI_BACKEND QINGZHUI_WORKSPACE QINGZHUI_RUNTIME
export JAVA_HOME="$QINGZHUI_RUNTIME/toolchains/java"
export PATH="$JAVA_HOME/bin:$QINGZHUI_RUNTIME/toolchains/maven/bin:$QINGZHUI_RUNTIME/bin:$QINGZHUI_RUNTIME/toolchains/lima/bin:$PATH"
export DOCKER_CONFIG="$QINGZHUI_RUNTIME/docker"
export COLIMA_HOME="$QINGZHUI_RUNTIME/colima"
export COLIMA_CACHE_HOME="$QINGZHUI_RUNTIME/colima-cache"
export LIMA_HOME="$QINGZHUI_RUNTIME/lima"
mkdir -p "$DOCKER_CONFIG" "$COLIMA_HOME" "$COLIMA_CACHE_HOME" "$LIMA_HOME" "$QINGZHUI_RUNTIME/logs"
export DOCKER_HOST="unix://$COLIMA_HOME/default/docker.sock"
export TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE=/var/run/docker.sock
export TESTCONTAINERS_REUSE_ENABLE=true
export DT_DATA_DIRECTORY="$QINGZHUI_RUNTIME/data/apiserver"
export DT_DATASOURCE_URL=jdbc:postgresql://localhost:15432/qingzhui
export DT_DATASOURCE_USERNAME=dtrack
export DT_DATASOURCE_PASSWORD=dtrack
export DT_DEV_SERVICES_FRONTEND_IMAGE=ghcr.io/dependencytrack/frontend:5.2.1
export DT_DEV_SERVICES_POSTGRES_IMAGE=postgres:18-alpine
export DT_DEV_SERVICES_FRONTEND_PORT=8081
export MAVEN_ARGS="-s $QINGZHUI_BACKEND/qingzhui/maven-settings.xml -T2"
export MAVEN_OPTS="${MAVEN_OPTS:-} -Xmx3g -Dfile.encoding=UTF-8"
export npm_config_cache="$QINGZHUI_RUNTIME/npm-cache"
