#!/usr/bin/env python3
"""Verify the original full console against the smoke test's disposable server."""
import hashlib
import http.cookiejar
import json
import os
import secrets
import sys
import time
import urllib.error
import urllib.request

endpoint = sys.argv[1].rstrip("/")
client = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()))


def request(path, method="GET", data=None, status=200):
    body = None if data is None else json.dumps(data).encode()
    req = urllib.request.Request(endpoint + path, data=body, method=method,
                                 headers={"Content-Type": "application/json", "Accept-Encoding": "identity"})
    try:
        response = client.open(req, timeout=20)
    except urllib.error.HTTPError as error:
        response = error
    with response:
        assert response.status == status, f"{method} {path}: expected {status}, got {response.status}"
        return response.read()


def api(path, method="GET", data=None, status=200):
    body = request("/api/v1" + path, method, data, status)
    return json.loads(body) if body else None


# These hashes come from console v1.7.6 in the April 2025 reference image.
manifest = request("/asset-manifest.json")
assert hashlib.sha256(manifest).hexdigest() == "1506906c46fbede5d4e436b7023fbdcc87fca1332ebf3a65b71cc2cc6bd0d013", "Full-console asset manifest changed"
assets = sorted(p.removeprefix("./") for p in json.loads(manifest)["files"].values() if p.endswith((".js", ".css")))
digest = hashlib.sha256()
for asset in assets:
    checksum = hashlib.sha256(request("/" + asset)).hexdigest()
    digest.update((asset + "\0" + checksum + "\n").encode())
assert digest.hexdigest() == "804aaf23247b4dce3899d0f639039608422bafc1e37eb2edab906eb3fcece3b8", "Full-console JavaScript or CSS changed"

api("/users", status=403)
api("/login", "POST", {"accessKey": os.environ["MINIO_ROOT_USER"], "secretKey": os.environ["MINIO_ROOT_PASSWORD"]}, 204)
assert api("/session")["status"] == "ok"

name = "openimage-" + secrets.token_hex(6)
policy = {"Version": "2012-10-17", "Statement": [
    {"Effect": "Allow", "Action": ["s3:*"], "Resource": [f"arn:aws:s3:::{name}", f"arn:aws:s3:::{name}/*"]},
]}
api("/buckets", "POST", {"name": name})
# AccountInfo uses the server's one-second bucket-list cache.
for _ in range(30):
    if name in [b["name"] for b in api("/buckets")["buckets"]]:
        break
    time.sleep(0.1)
else:
    raise AssertionError("Created bucket did not appear in the console")
api(f"/buckets/{name}/versioning", "PUT", {"enabled": True}, 201)
assert api(f"/buckets/{name}/versioning")["status"] == "Enabled"

api("/policies", "POST", {"name": name, "policy": json.dumps(policy)}, 201)
api("/users", "POST", {"accessKey": name, "secretKey": secrets.token_hex(24), "groups": [], "policies": [name]}, 201)
assert name in [u["accessKey"] for u in api("/users")["users"]]
assert name in api(f"/user/{name}")["policy"]
api("/groups", "POST", {"group": name, "members": [name]}, 201)
assert name in api(f"/group/{name}")["members"]
account = api("/service-accounts", "POST", {"name": name}, 201)
access_key = account["accessKey"]
api(f"/service-accounts/{access_key}")

api(f"/service-accounts/{access_key}", "DELETE", status=204)
api(f"/user/{name}", "DELETE", status=204)
api(f"/group/{name}", "DELETE", status=204)
api(f"/policy/{name}", "DELETE", status=204)
api(f"/buckets/{name}", "DELETE", status=204)
print(f"PASS: {len(assets)} original UI assets; console login, users, groups, policies, access keys, buckets, versioning")
