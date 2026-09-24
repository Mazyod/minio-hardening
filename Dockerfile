FROM --platform=$BUILDPLATFORM golang:1.27.1-bookworm@sha256:69a7b9788769bec032d238959b61854e9ae87f57be9029ec04e9885fabf99195 AS source
WORKDIR /src
RUN git init . \
    && git remote add origin https://github.com/minio/minio.git \
    && git fetch --depth 1 origin 9e49d5e7a648f00e26f2246f4dc28e6b07f8c84a \
    && git checkout --detach FETCH_HEAD \
    && test "$(git rev-parse HEAD)" = 9e49d5e7a648f00e26f2246f4dc28e6b07f8c84a
COPY patches/ /patches/
RUN for patch in /patches/*.patch; do git apply "$patch"; done
COPY dependencies/go.mod dependencies/go.sum ./
COPY scripts/openimage_security_test.go cmd/openimage_security_test.go
COPY scripts/csv_security_test.go internal/s3select/csv/openimage_security_test.go
COPY scripts/test-source.sh /test-source.sh
ENV GOTOOLCHAIN=local GOMAXPROCS=3 CGO_ENABLED=0
RUN --mount=type=cache,target=/go/pkg/mod go mod download && go mod verify

FROM source AS test
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build sh /test-source.sh

FROM test AS build
ARG TARGETOS
ARG TARGETARCH
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    GOOS=$TARGETOS GOARCH=$TARGETARCH go build -p 2 -mod=readonly -trimpath \
      -ldflags="-s -w -X github.com/minio/minio/cmd.Version=2025-10-15T17:29:55Z -X github.com/minio/minio/cmd.ReleaseTag=RELEASE.2025-10-15T17-29-55Z.openimage.2 -X github.com/minio/minio/cmd.CommitID=9e49d5e7a648f00e26f2246f4dc28e6b07f8c84a -X github.com/minio/minio/cmd.ShortCommitID=9e49d5e7a648 -X github.com/minio/minio/cmd.CopyrightYear=2025" \
      -o /out/minio .
RUN mkdir -p /rootfs/data /rootfs/tmp /rootfs/etc /rootfs/usr/share/minio \
    && chmod 1777 /rootfs/tmp \
    && chown 10001:10001 /rootfs/data \
    && printf 'minio:x:10001:10001:MinIO:/tmp:/sbin/nologin\n' > /rootfs/etc/passwd \
    && printf 'minio:x:10001:\n' > /rootfs/etc/group
COPY LICENSE NOTICE /rootfs/usr/share/minio/

FROM source AS archive
RUN --mount=type=cache,target=/go/pkg/mod go mod vendor \
    && mkdir -p /src/_openimage \
    && cp -a /go/pkg/mod/github.com/minio/console@v1.7.6 /src/_openimage/console-source
COPY Dockerfile LICENSE NOTICE README.md SECURITY.md /src/_openimage/
COPY scripts/ /src/_openimage/scripts/
COPY patches/ /src/_openimage/patches/
COPY dependencies/ /src/_openimage/dependencies/
RUN mkdir -p /out \
    && tar --exclude=.git -czf /out/minio-source.tar.gz -C /src .
FROM scratch AS source-export
COPY --from=archive /out/ /

FROM scratch AS runtime
COPY --from=build /rootfs/ /
COPY --from=build /out/minio /usr/bin/minio
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=build /usr/share/zoneinfo /usr/share/zoneinfo
ARG REVISION=local
LABEL org.opencontainers.image.title="OpenImage MinIO" \
      org.opencontainers.image.description="MinIO security backports with the full management console" \
      org.opencontainers.image.source="https://github.com/Mazyod/minio-hardening" \
      org.opencontainers.image.licenses="AGPL-3.0-or-later" \
      org.opencontainers.image.revision=$REVISION
ENV HOME=/tmp MINIO_UPDATE=off
USER 10001:10001
WORKDIR /data
EXPOSE 9000 9001
ENTRYPOINT ["/usr/bin/minio"]
CMD ["server", "/data", "--console-address", ":9001"]
