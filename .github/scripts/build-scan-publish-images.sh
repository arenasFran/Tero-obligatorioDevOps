#!/usr/bin/env bash
set -euo pipefail

: "${GITHUB_REPOSITORY:?GITHUB_REPOSITORY must be set by GitHub Actions}"
: "${GITHUB_SHA:?GITHUB_SHA must be set by GitHub Actions}"

owner_lower="${GITHUB_REPOSITORY_OWNER,,}"
repository_lower="${GITHUB_REPOSITORY#*/}"
repository_lower="${repository_lower,,}"
image_tag="${GITHUB_SHA}"
image_prefix="ghcr.io/${owner_lower}/${repository_lower}"
trivy_cache="${RUNNER_TEMP:-/tmp}/trivy-cache"

services=(catalog carts orders checkout ui admin)
declare -A contexts=(
  [catalog]="src/catalog"
  [carts]="src/cart"
  [orders]="src/orders"
  [checkout]="src/checkout"
  [ui]="src/ui"
  [admin]="src/admin"
)

mkdir -p "$trivy_cache"

for service in "${services[@]}"; do
  image="${image_prefix}-${service}:${image_tag}"
  echo "Building ${image}"
  docker build --pull \
    --label "org.opencontainers.image.source=https://github.com/${GITHUB_REPOSITORY}" \
    --label "org.opencontainers.image.revision=${GITHUB_SHA}" \
    --tag "$image" \
    "${contexts[$service]}"
done

scan_status=0
for service in "${services[@]}"; do
  image="${image_prefix}-${service}:${image_tag}"
  echo "Scanning ${image}"
  if ! docker run --rm \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "${trivy_cache}:/root/.cache/" \
    ghcr.io/aquasecurity/trivy:0.76.2 \
    image --scanners vuln --severity HIGH,CRITICAL --exit-code 1 "$image"; then
    scan_status=1
  fi
done

if [[ "$scan_status" -ne 0 ]]; then
  echo "One or more images have HIGH or CRITICAL vulnerabilities; no images will be published." >&2
  exit "$scan_status"
fi

if [[ "${PUBLISH_IMAGES:-false}" == "true" ]]; then
  : "${GH_TOKEN:?GH_TOKEN is required to publish images}"
  echo "$GH_TOKEN" | docker login ghcr.io --username "$GITHUB_ACTOR" --password-stdin

  for service in "${services[@]}"; do
    image="${image_prefix}-${service}:${image_tag}"
    echo "Publishing ${image}"
    docker push "$image"
  done
fi
