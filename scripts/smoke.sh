#!/usr/bin/env bash
set -euo pipefail

image=${1:-openimage/minio:local}
container=
trap 'if [[ -n "$container" ]]; then docker rm -fv "$container" >/dev/null; fi' EXIT

# No credentials and the upstream default must both fail closed.
for credentials in missing default; do
    env_args=()
    if [[ "$credentials" == default ]]; then
        env_args=(-e MINIO_ROOT_USER=minioadmin -e MINIO_ROOT_PASSWORD=minioadmin)
    fi
    container=$(docker run -d --network none "${env_args[@]}" "$image" server /data)
    status=$(timeout 30 docker wait "$container")
    [[ "$status" == 1 ]] || { echo "Unexpected startup exit with $credentials credentials: $status" >&2; exit 1; }
    docker rm -fv "$container" >/dev/null
    container=
done

export MINIO_ROOT_USER=smoke-test
MINIO_ROOT_PASSWORD=$(python3 -c 'import secrets; print(secrets.token_hex(24))')
export MINIO_ROOT_PASSWORD
container=$(docker run -d --read-only --cap-drop ALL \
    --security-opt no-new-privileges:true --tmpfs /tmp:rw,noexec,nosuid,size=64m \
    --volume /data -p 127.0.0.1::9000 -p 127.0.0.1::9001 \
    -e MINIO_ROOT_USER -e MINIO_ROOT_PASSWORD "$image")
[[ "$(docker inspect --format '{{.Config.User}}' "$container")" == '10001:10001' ]]
endpoint="http://$(docker port "$container" 9000/tcp)"
console_endpoint="http://$(docker port "$container" 9001/tcp)"
ready() {
    for _ in {1..60}; do
        if curl -fsS "$endpoint/minio/health/ready" >/dev/null 2>&1 \
            && curl -fsS "$console_endpoint/api/v1/login" >/dev/null 2>&1; then return; fi
        sleep 1
    done
    echo 'MinIO did not become ready' >&2
    return 1
}
s3() {
    curl --fail --silent --show-error --aws-sigv4 'aws:amz:us-east-1:s3' \
        --user "$MINIO_ROOT_USER:$MINIO_ROOT_PASSWORD" "$@"
}
ready
python3 "$(dirname "$0")/console_test.py" "$console_endpoint"
s3 -X PUT "$endpoint/smoke-bucket"
s3 -X PUT --data-binary 'openimage-smoke-test' "$endpoint/smoke-bucket/object"
[[ "$(s3 "$endpoint/smoke-bucket/object")" == 'openimage-smoke-test' ]]
[[ "$(curl -s -o /dev/null -w '%{http_code}' "$endpoint/smoke-bucket/object")" == 403 ]]
docker restart "$container" >/dev/null
endpoint="http://$(docker port "$container" 9000/tcp)"
console_endpoint="http://$(docker port "$container" 9001/tcp)"
ready
[[ "$(s3 "$endpoint/smoke-bucket/object")" == 'openimage-smoke-test' ]]
s3 -X DELETE "$endpoint/smoke-bucket/object"
s3 -X DELETE "$endpoint/smoke-bucket"
echo 'PASS: non-root, read-only root, credentials, signed S3, anonymous denial, persistence'
