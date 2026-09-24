#!/usr/bin/env bash
set -euo pipefail
image=${1:-openimage/minio:local}
scanner=aquasec/trivy:0.74.0@sha256:62b1e65e8869bc4b4c6aa4fa2b21595256c7c2f6018a9d9ad61caf87187c1969
docker_endpoint=${DOCKER_HOST:-$(docker context inspect --format '{{.Endpoints.docker.Host}}')}
[[ "$docker_endpoint" == unix://* ]] || { echo 'Scanning requires a local Unix Docker socket' >&2; exit 1; }
mkdir -p build reports
docker image save "$image" -o build/image.tar
scan() {
    docker run --rm -v "$PWD:/work" -v minio-hardening-trivy:/root/.cache/trivy \
        -v "${docker_endpoint#unix://}:/var/run/docker.sock:ro" \
        -w /work "$scanner" image --image-src docker --ignorefile /dev/null --timeout 10m "$@" "$image"
}
python3 -m unittest discover -s scripts -p test_vex.py
scan --scanners vuln --format json --output reports/raw.json
scan --format cyclonedx --output reports/sbom.cdx.json
python3 scripts/vex.py reports/raw.json reports/sbom.cdx.json > reports/vex.json
scan --scanners vuln --vex reports/vex.json --format json --output reports/assessed.json --exit-code 1
echo 'PASS: no untriaged vulnerabilities; retain raw.json and vex.json together'
