#!/bin/sh
set -eu

# GO-2026-5932 affects these packages, not every user of x/crypto.
go list -deps . > /tmp/minio-packages.txt
if grep -q '^golang.org/x/crypto/openpgp\($\|/\)' /tmp/minio-packages.txt; then
    echo 'Unmaintained OpenPGP code entered the server dependency graph' >&2
    exit 1
fi

# Run in the prepared MinIO source tree. Keep regression tests from backports.
go test -p 2 -timeout 10m ./internal/config/identity/openid ./internal/config/identity/ldap ./internal/s3select/...
go test -p 2 -timeout 10m ./cmd -run 'Test(OpenImageSecurity|.*STSLDAP.*|.*LDAPBindError.*|.*STSThrottled.*|.*STSTrustedProx.*|.*ReplicationHeaderPoisoning|Extract.*MetadataHeaders|GetCopyObjectMetadataFromHeaderReplication|CloneRequestWithoutCopyReplicationHeaders)$'
if grep -q 'storageRESTMethodReadMultiple' cmd/storage-rest-server.go; then
    echo 'Vulnerable ReadMultiple route is still registered' >&2
    exit 1
fi
