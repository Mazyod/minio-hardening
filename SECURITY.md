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

The original image digest and scanner CVE IDs are still needed to reconcile the
reported nine MinIO and ten RabbitMQ findings one by one. Counts alone cannot
establish which issues were present or prove they are all resolved.
