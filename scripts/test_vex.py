import unittest

from vex import MINIO_VERSION, disposition, generate


class VexTest(unittest.TestCase):
    def test_scope_and_unknown_findings(self):
        vuln = {"VulnerabilityID": "CVE-2026-33322", "PkgName": "github.com/minio/minio", "InstalledVersion": MINIO_VERSION,
                "PkgIdentifier": {"PURL": "pkg:golang/github.com/minio/minio@" + MINIO_VERSION}}
        self.assertEqual(disposition(vuln)["status"], "fixed")
        for override in ({"VulnerabilityID": "CVE-2099-0001"}, {"InstalledVersion": "v0.0.0-old"}, {"PkgName": "another/module"}):
            self.assertIsNone(disposition(vuln | override))
        root = "pkg:oci/minio@sha256:" + "a" * 64
        sbom = {"metadata": {"component": {"purl": root}}, "components": [
            {"name": "github.com/minio/minio", "version": MINIO_VERSION},
            {"name": "github.com/rabbitmq/amqp091-go", "version": "v1.15.0"},
        ]}
        document = generate({"Results": [{"Vulnerabilities": [vuln]}]}, sbom)
        self.assertEqual(document["statements"][0]["products"], [{"@id": root, "subcomponents": [{"@id": vuln["PkgIdentifier"]["PURL"]}]}])
        with self.assertRaises(ValueError):
            generate({}, sbom | {"components": []})
        with self.assertRaises(ValueError):
            generate({}, {"metadata": {"component": {"purl": "pkg:oci/minio@latest"}}})


if __name__ == "__main__":
    unittest.main()
