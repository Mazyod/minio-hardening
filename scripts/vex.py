#!/usr/bin/env python3
"""Attach reviewed dispositions to one image, retaining the raw scan separately."""
import datetime
import json
import pathlib
import sys

MINIO_VERSION = "v0.0.0-20251015172955-9e49d5e7a648+dirty"
BACKPORTS = {
    "CVE-2026-33322": "00",
    "CVE-2026-33419": "01, 06-09",
    "CVE-2026-34204": "02",
    "CVE-2026-39414": "03, 10",
    "CVE-2026-41145": "04",
    "CVE-2026-40344": "05",
    "CVE-2026-42600": "11",
}


def disposition(vulnerability):
    name = vulnerability["VulnerabilityID"]
    package = vulnerability["PkgName"]
    version = vulnerability["InstalledVersion"]
    if (package, version) == ("github.com/minio/minio", MINIO_VERSION) and name in BACKPORTS:
        return {
            "status": "fixed",
            "status_notes": f"Security backport(s) {BACKPORTS[name]}; see SECURITY.md and source regression results for this image.",
        }
    if (name, package, version) == ("GO-2026-5932", "golang.org/x/crypto", "v0.56.0"):
        return {
            "status": "not_affected",
            "justification": "vulnerable_code_not_present",
            "impact_statement": "No golang.org/x/crypto/openpgp package occurs in go list -deps for this server; enforced during the image build.",
        }
    return None


def generate(report, sbom):
    product = sbom["metadata"]["component"]["purl"]
    if not product.startswith("pkg:oci/") or "@sha256:" not in product:
        raise ValueError("VEX requires an image PURL pinned to its digest")
    packages = {(c.get("name"), c.get("version")) for c in sbom.get("components", [])}
    expected = {("github.com/minio/minio", MINIO_VERSION), ("github.com/rabbitmq/amqp091-go", "v1.15.0"), ("github.com/minio/console", "v1.7.6")}
    if not expected <= packages:
        raise ValueError("SBOM does not identify the pinned MinIO, AMQP, and full-console modules")
    statements = []
    for result in report.get("Results", []):
        for vuln in result.get("Vulnerabilities", []):
            status = disposition(vuln)
            if status:
                statements.append({
                    "vulnerability": {"name": vuln["VulnerabilityID"]},
                    "products": [{"@id": product, "subcomponents": [{"@id": vuln["PkgIdentifier"]["PURL"]}]}],
                    **status,
                })
    return {
        "@context": "https://openvex.dev/ns/v0.2.0",
        "@id": "https://github.com/Mazyod/minio-hardening/vex/" + product.split("@", 1)[1].split("?", 1)[0],
        "author": "OpenImage contributors",
        "timestamp": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "version": 1,
        "statements": statements,
    }


if __name__ == "__main__":
    report, sbom = (json.loads(pathlib.Path(p).read_text()) for p in sys.argv[1:])
    print(json.dumps(generate(report, sbom), indent=2))
