# Security policy and current status

Report exploitable issues using this repository's **Security → Report a
vulnerability** feature. Do not post credentials, private scanner exports, or
exploit details in public issues. Support targets the latest project release.

## Baseline and fixes

Base: MinIO `RELEASE.2025-10-15T17-29-55Z`, commit
`9e49d5e7a648f00e26f2246f4dc28e6b07f8c84a`.

| Finding | Treatment | Verification |
| --- | --- | --- |
| RabbitMQ Go client v1.10.0 | Pin `amqp091-go` v1.15.0, including the fixes in v1.13 and v1.14 | Embedded-module scan; compiled MinIO integration tests |
| [CVE-2025-62506](https://github.com/minio/minio/security/advisories/GHSA-jjjj-jwhf-8rgr) | Fixed in the chosen upstream release | Pinned upstream security release |
| [CVE-2026-33322](https://github.com/minio/minio/security/advisories/GHSA-5cx5-wh4m-82fh) | Patch 00: reject HMAC OIDC tokens, including key-refresh retries | OpenID JWT acceptance and rejection tests |
| [CVE-2026-33419](https://github.com/minio/minio/security/advisories/GHSA-jv87-32hw-hh99) | Patches 01, 06–09: uniform LDAP authentication failures and source rate limiting | LDAP classification, rate limiter, and proxy address tests |
| [CVE-2026-34204](https://github.com/minio/minio/security/advisories/GHSA-3rh2-v3gr-35p9) | Patch 02: replication-only metadata requires replication authorization | PUT/COPY metadata poisoning regressions |
| [CVE-2026-39414](https://github.com/minio/minio/security/advisories/GHSA-h749-fxx7-pwpg) | Patches 03 and 10: bounded CSV/JSON line reads | S3 Select tests and explicit CSV size-boundary test |
| [CVE-2026-41145](https://github.com/minio/minio/security/advisories/GHSA-hv4r-mvr4-25vw) | Patch 04: verify header signatures and reject presigned unsigned-trailer requests | Signed, forged, mixed-auth, multipart, and anonymous-policy regressions |
| [CVE-2026-40344](https://github.com/minio/minio/security/advisories/GHSA-9c4q-hq6p-c237) | Patch 05: verify unsigned-trailer Snowball uploads | Forged, anonymous-denied, and valid Snowball regressions |
| [CVE-2026-42600](https://github.com/minio/minio/security/advisories/GHSA-xh8f-g2qw-gcm7) | Patch 11: remove unused ReadMultiple storage API | Compilation and route-removal check |
| [GO-2026-5932](https://pkg.go.dev/vuln/GO-2026-5932) | The unmaintained OpenPGP packages are absent from the server dependency graph | Build fails if an OpenPGP package enters the dependency graph |

Patch filenames retain the exact originating commit IDs from
[pgsty/silo](https://github.com/pgsty/silo). Patches 04 and 05 contain provisional
CVE labels in their original commit messages; the advisory links and final CVE
IDs in this table are authoritative. Patch 09 omits an incompatible documentation
hunk only. Patch 12 is this project's explicit-credentials startup requirement.

## Compatibility and limits

- OIDC requires asymmetric signatures backed by JWKS; shared-secret HMAC ID
  tokens are rejected.
- LDAP rate limits are in memory, per node and per source. Distributed guessing
  and timing side channels require deployment-level controls. A trusted proxy
  must overwrite client-supplied `X-Real-IP`; only allowlist actual proxy addresses
  using `MINIO_IDENTITY_LDAP_STS_TRUSTED_PROXIES`. Never use catch-all CIDRs.
- S3 Select rejects CSV/JSON lines exceeding the 1 MiB record limit.
- Presigned unsigned-trailer uploads are rejected. Signed uploads and explicitly
  permitted anonymous bucket writes retain regression coverage.
- The removed ReadMultiple API had no production callers in the pinned base.
  Older nodes that still call it must not be mixed into a deployment.
- The UI comes from the final community source release. This image does not
  restore earlier administrative console features.
- The bundled `mc` client from the reference image is not included. Workflows
  that invoke `mc` inside the server container need a separate client image.
- Tests cover the listed regressions and a single-node S3 smoke flow. They do not
  certify distributed upgrades, every external identity provider, or all
  replication topologies. Back up data and test an upgrade before deployment.

## Scanner evidence

Trivy runs with all severities, including unfixed findings. Raw results are
retained. VEX statements are scoped to the scanned image's exact PURL and exact
component versions. Only the explicitly listed backports and proven absent
OpenPGP code are classified; every other finding fails the release gate.
The VEX dispositions are project assertions backed by these patches and tests,
not independent certification. A clean adjusted report is not a zero-CVE claim.

## Reference image comparison

Reference: `quay.io/minio/minio:RELEASE.2025-04-08T15-41-24Z`, pinned to
`quay.io/minio/minio@sha256:8834ae47a2de3509b83e0e70da9369c24bbbc22de42f2a2eddc530eee88acd1b`.
The scanned platform is Linux amd64. Its embedded server module is
`github.com/minio/minio v0.0.0-20250408154124-d0cada583fce+dirty`.
This is the comparison baseline; the hardened build uses the newer source
release and security backports listed above.

Scanned on 2026-09-24 with Trivy 0.74.0 and vulnerability database updated
2026-09-23T20:20:57Z. Both images used that database, all severities, and no
ignore file. The hardened recipe was commit
`b5c8d7308de72ed59ef50ee91fff26174db90729`.

| Scope | Reference raw findings | Hardened raw findings | Hardened after VEX |
| --- | ---: | ---: | ---: |
| RabbitMQ Go client in server | 10 | 0 | 0 |
| MinIO server module | 7 | 6 | 0 |
| Other server dependencies and Go runtime | 104 | 1 | 0 |
| Bundled `mc` client | 93 | Not included | Not included |
| Operating-system packages | 91 | 0 | 0 |
| **Total finding occurrences** | **305** | **7** | **0** |

The reference has 161 distinct vulnerability IDs; a vulnerability can occur in
multiple packages or binaries. Removed components are not counted as patched.
The hardened runtime uses `scratch` and does not ship the reference image's OS
packages or `mc` binary. The seven remaining raw findings are the six MinIO
backports detected by Trivy and the absent OpenPGP code discussed above.

The ten RabbitMQ findings are CVE-2026-77403, CVE-2026-77404,
CVE-2026-77405, CVE-2026-77406, CVE-2026-77407, CVE-2026-77408,
CVE-2026-77410, CVE-2026-77411, CVE-2026-77412, and CVE-2026-79921.
All ten have a fixed-version floor of v1.13.0 in this scan; the hardened binary
contains v1.15.0 and reports none of them.

The seven detected MinIO findings are CVE-2025-62506 and CVE-2026-33322,
CVE-2026-33419, CVE-2026-34204, CVE-2026-39414, CVE-2026-40344, and
CVE-2026-41145. The newer upstream release fixes CVE-2025-62506; source
backports address the other six. CVE-2026-42600 is additionally backported,
although this scanner does not report it for the reference image.

This reproduces the reported RabbitMQ count of ten. It detects seven MinIO
findings rather than the reported nine. The original scanner's CVE IDs are
still needed to reconcile that difference; identical counts alone would not
prove identical coverage.
