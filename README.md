# OpenImage MinIO

An independent, open-source MinIO image maintained for `openimage/minio` on
Docker Hub. Built from pinned source with security backports and updated Go
dependencies. Licensed under [AGPL-3.0-or-later](LICENSE).

The upstream community repository is archived. This project carries an explicit
patch set; upgrading the operating-system layer alone does not fix MinIO or its
embedded Go libraries. See [security status and compatibility](SECURITY.md).

## Build and run

Docker with BuildKit and its containerd image store, Bash, Python 3, and curl
with `--aws-sigv4` are used for local verification. The scanner uses the local
Unix Docker socket; CI pins Docker 29.8.0 with the containerd store enabled so
image digests survive build, scan, and publication. The initial release target
is Linux amd64.

```sh
docker build --pull -t openimage/minio:local .
./scripts/smoke.sh openimage/minio:local
./scripts/scan.sh openimage/minio:local
```

Every image build runs the security regression tests before compiling MinIO.
Supply your own credentials; missing credentials and `minioadmin:minioadmin`
are rejected. MinIO's `MINIO_ROOT_USER_FILE` and `MINIO_ROOT_PASSWORD_FILE`
settings are also supported for mounted secrets.

```sh
export MINIO_ROOT_USER=storage-admin
export MINIO_ROOT_PASSWORD="$(openssl rand -hex 32)"
docker run --rm --name minio \
  --read-only --cap-drop ALL --security-opt no-new-privileges:true \
  --tmpfs /tmp:rw,noexec,nosuid,size=64m \
  -v minio-data:/data \
  -p 127.0.0.1:9000:9000 -p 127.0.0.1:9001:9001 \
  -e MINIO_ROOT_USER -e MINIO_ROOT_PASSWORD \
  openimage/minio:local
```

Store the generated credentials securely before stopping your shell. The image
runs as UID/GID `10001:10001`; bind-mounted data and certificate directories must
be accessible to that user. Use TLS before exposing either API or console to a
network. The example binds only to localhost. Readiness is available at
`/minio/health/ready`; the image contains no shell or curl for exec probes.

## Security verification

The initial changes upgrade `github.com/rabbitmq/amqp091-go` from `v1.10.0` to
`v1.15.0`, move MinIO to its final community security release, backport seven
subsequent server fixes, and upgrade vulnerable dependencies found by Trivy.
MinIO's module identity and original upstream revision remain visible.

`reports/` contains the raw scan, CycloneDX SBOM, image-specific OpenVEX document,
and scan after applying that document. Version-based scanners still report
backported fixes unless they consume the VEX evidence. This is **not a claim of
zero raw scanner findings**. Unknown findings of any severity block publication.
The original scanner's reported counts still need to be reconciled against its
exact CVE IDs and image digest.

## Publishing and maintenance

Pushes, pull requests, and weekly scheduled runs build, test, and scan. To publish,
configure the GitHub Actions secret `DOCKERHUB_TOKEN` with write access to
`openimage/minio`, then create and push a `v*` tag. Release builds upload matching
source and security reports before pushing the tested image to Docker Hub.
Publication uses version tags; there is no automatic mutable `latest` tag.

The source archive includes the modified MinIO source and vendored dependencies:

```sh
docker build --target source-export --output type=local,dest=build .
```

To compile that archive independently, use Go 1.27.1 and
`CGO_ENABLED=0 go build -mod=vendor -trimpath -buildvcs=false .` in the extracted
directory. The repository Dockerfile records the release linker metadata.
Keep the corresponding source available when redistributing the image, and
retain the upstream license and notices.

See [CONTRIBUTING.md](CONTRIBUTING.md) and [AGENTS.md](AGENTS.md) for project rules.
