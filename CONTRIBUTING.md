# Contributing

Keep changes generic and focused on reproducible builds, vulnerability fixes,
and maintenance. Follow [AGENTS.md](AGENTS.md), including its privacy rules.
Examples and reports must use synthetic data and public project information.
Do not include personal or employer details, private infrastructure, or secrets.

Security changes need an advisory link, a pinned patch origin or explanation,
and a regression that fails on the vulnerable code. Preserve upstream notices.
Update dependency locks and image/Action digests deliberately. Dependabot checks
Docker and GitHub Actions weekly; Go updates use `dependencies/go.mod` in the
prepared source tree, because this repository is a build recipe, not a Go module.

Run the README build, smoke, and scan commands. Review both raw and VEX-adjusted
findings. Do not mark findings fixed based solely on a successful scan. Changes
to backports or vulnerability dispositions require matching test evidence.

Contributions are accepted under AGPL-3.0-or-later. Be respectful, constructive,
and technical in issues and reviews. Report exploitable vulnerabilities through
the private reporting channel described in [SECURITY.md](SECURITY.md).
