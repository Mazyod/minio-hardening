# Project rules

- Keep this project reusable for any operator. Use neutral names, example.com,
  localhost, and synthetic data in code, documentation, tests, and examples.
- Never include personal information about the repository owner or their
  employer: names, email addresses, workplace references, internal domains,
  infrastructure, customer information, local paths, or private conversations.
  Public repository coordinates and the `openimage` image namespace are allowed
  where needed to identify the project. Preserve required upstream attribution.
- Use project attribution for commits: `OpenImage contributors
  <contributors@users.noreply.github.com>`. Never copy the global Git identity.
- Keep credentials in environment variables or repository secrets. Do not commit
  credentials, scanner exports from private systems, `.env` files, or raw logs.
- Build from pinned source and reviewed patches. Pin build images and Actions.
  Keep dependency versions and checksums under version control.
- Fix vulnerable code or upgrade dependencies; do not hide scanner findings by
  changing module identities, stripping build metadata, or blanket exclusions.
- Record each security backport's origin, advisory, verification, and limits.
  Run the relevant regressions and the image smoke test before publishing.
- Retain the AGPL license, upstream notices, and matching source for releases.
- Prefer a small patch set and standard tools. Do not add deployment-specific
  integrations or unrelated features.
- Preserve the full MinIO management console from the April 2025 reference
  image. Do not replace it with the reduced object browser during upgrades.
  Keep console v1.7.6 pinned until a replacement proves equivalent features;
  verify UI assets and management APIs in the smoke test.
