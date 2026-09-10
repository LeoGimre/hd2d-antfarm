#!/usr/bin/env python3
"""publish.py — upload a tick's media to object storage and print public URLs.

    farm/publish.py <devlog-slug> [files...]

Talks plain S3 SigV4 with nothing but the standard library. Two reasons:
this machine has no boto3 or aws-cli, and speaking the raw protocol means the
storage provider is a config change (endpoint + keys) rather than a rewrite —
which matters because Neon Object Storage is still beta.

Reads credentials from farm/.env or the environment:
    AWS_ENDPOINT_URL_S3   branch S3 endpoint
    AWS_ACCESS_KEY_ID     Neon credential token_id
    AWS_SECRET_ACCESS_KEY Neon s3_secret_access_key
    AWS_REGION            us-east-2
    ANTFARM_BUCKET        bucket name (default: antfarm-media)
"""
import hashlib
import hmac
import os
import sys
import urllib.request
import urllib.error
from datetime import datetime, timezone

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEFAULT_BUCKET = "antfarm-media"

CONTENT_TYPES = {
    ".mp4": "video/mp4",
    ".webm": "video/webm",
    ".jpg": "image/jpeg",
    ".jpeg": "image/jpeg",
    ".png": "image/png",
    ".gif": "image/gif",
}


def load_env():
    """farm/.env wins over nothing; real environment wins over farm/.env."""
    path = os.path.join(ROOT, "farm", ".env")
    if os.path.exists(path):
        with open(path) as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith("#") or "=" not in line:
                    continue
                k, v = line.split("=", 1)
                os.environ.setdefault(k.strip(), v.strip().strip('"').strip("'"))


def _sign(key, msg):
    return hmac.new(key, msg.encode("utf-8"), hashlib.sha256).digest()


def signing_key(secret, datestamp, region, service):
    k = _sign(("AWS4" + secret).encode("utf-8"), datestamp)
    k = _sign(k, region)
    k = _sign(k, service)
    return _sign(k, "aws4_request")


def put_object(endpoint, bucket, key, body, content_type, access_key, secret_key, region):
    """Path-style PUT with SigV4. Neon requires force_path_style."""
    host = endpoint.split("://", 1)[1].rstrip("/")
    canonical_uri = f"/{bucket}/{key}"
    payload_hash = hashlib.sha256(body).hexdigest()

    now = datetime.now(timezone.utc)
    amzdate = now.strftime("%Y%m%dT%H%M%SZ")
    datestamp = now.strftime("%Y%m%d")

    signed_headers = "content-type;host;x-amz-content-sha256;x-amz-date"
    canonical_headers = (
        f"content-type:{content_type}\n"
        f"host:{host}\n"
        f"x-amz-content-sha256:{payload_hash}\n"
        f"x-amz-date:{amzdate}\n"
    )
    canonical_request = "\n".join(
        ["PUT", canonical_uri, "", canonical_headers, signed_headers, payload_hash]
    )

    scope = f"{datestamp}/{region}/s3/aws4_request"
    string_to_sign = "\n".join(
        [
            "AWS4-HMAC-SHA256",
            amzdate,
            scope,
            hashlib.sha256(canonical_request.encode("utf-8")).hexdigest(),
        ]
    )
    signature = hmac.new(
        signing_key(secret_key, datestamp, region, "s3"),
        string_to_sign.encode("utf-8"),
        hashlib.sha256,
    ).hexdigest()

    authorization = (
        f"AWS4-HMAC-SHA256 Credential={access_key}/{scope}, "
        f"SignedHeaders={signed_headers}, Signature={signature}"
    )

    url = f"{endpoint.rstrip('/')}{canonical_uri}"
    req = urllib.request.Request(url, data=body, method="PUT")
    req.add_header("Content-Type", content_type)
    req.add_header("X-Amz-Content-Sha256", payload_hash)
    req.add_header("X-Amz-Date", amzdate)
    req.add_header("Authorization", authorization)

    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            if resp.status not in (200, 201):
                raise SystemExit(f"publish: unexpected status {resp.status} for {key}")
    except urllib.error.HTTPError as e:
        raise SystemExit(f"publish: {e.code} {e.reason} for {key}\n{e.read().decode()[:400]}")

    return url


def main():
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    slug = sys.argv[1]
    files = sys.argv[2:]

    load_env()
    endpoint = os.environ.get("AWS_ENDPOINT_URL_S3")
    access_key = os.environ.get("AWS_ACCESS_KEY_ID")
    secret_key = os.environ.get("AWS_SECRET_ACCESS_KEY")
    region = os.environ.get("AWS_REGION", "us-east-2")
    bucket = os.environ.get("ANTFARM_BUCKET", DEFAULT_BUCKET)

    missing = [
        n
        for n, v in (
            ("AWS_ENDPOINT_URL_S3", endpoint),
            ("AWS_ACCESS_KEY_ID", access_key),
            ("AWS_SECRET_ACCESS_KEY", secret_key),
        )
        if not v
    ]
    if missing:
        raise SystemExit(
            "publish: missing credentials: "
            + ", ".join(missing)
            + "\n  Create them with:  neon env pull --file farm/.env"
        )

    if not files:
        # Default to whatever the capture step left behind for this demo.
        out = os.path.join(ROOT, "farm", "out", slug)
        for name in ("clip.mp4", "clip.webm", "poster.jpg"):
            p = os.path.join(out, name)
            if os.path.exists(p):
                files.append(p)
    if not files:
        raise SystemExit(f"publish: nothing to upload for {slug}")

    for path in files:
        if not os.path.exists(path):
            raise SystemExit(f"publish: no such file: {path}")
        ext = os.path.splitext(path)[1].lower()
        ctype = CONTENT_TYPES.get(ext, "application/octet-stream")
        key = f"clips/{slug}/{os.path.basename(path)}"
        with open(path, "rb") as f:
            body = f.read()
        url = put_object(endpoint, bucket, key, body, ctype, access_key, secret_key, region)
        print(f"{os.path.basename(path)}\t{url}")


if __name__ == "__main__":
    main()
