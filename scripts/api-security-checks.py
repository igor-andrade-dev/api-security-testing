#!/usr/bin/env python3
"""Safe API assessment example restricted to localhost lab targets."""

import argparse
import re
import sys
from urllib.parse import urlparse

import requests

DEFAULT_TARGET = "http://127.0.0.1:8000"
USER_AGENT = "api-security-testing-lab/1.0"
MAX_WRITES = 5


def validate_loopback_target(target: str) -> str:
    target = target.rstrip("/")
    parsed = urlparse(target)

    if parsed.scheme not in {"http", "https"}:
        raise ValueError("Target must use http:// or https://")

    host = (parsed.hostname or "").lower()
    if host not in {"localhost", "127.0.0.1", "::1"}:
        raise ValueError(
            f"Blocked target {host!r}: this portfolio script only permits localhost."
        )
    return target


def extract_csrf(html: str) -> str:
    match = re.search(
        r'<meta\s+name=["\']csrf-token["\']\s+content=["\']([^"\']+)',
        html,
        re.IGNORECASE,
    )
    return match.group(1) if match else ""


def main() -> int:
    parser = argparse.ArgumentParser(description="Local API security validation example")
    parser.add_argument("--target", default=DEFAULT_TARGET, help="Loopback lab URL")
    parser.add_argument(
        "--execute-writes",
        action="store_true",
        help="Allow up to five POST requests to the local lab",
    )
    args = parser.parse_args()

    try:
        base_url = validate_loopback_target(args.target)
    except ValueError as exc:
        print(f"[BLOCKED] {exc}", file=sys.stderr)
        return 2

    session = requests.Session()
    session.headers.update(
        {"User-Agent": USER_AGENT, "Accept": "application/json"}
    )

    print(f"[*] Local lab target: {base_url}")
    try:
        initial = session.get(
            f"{base_url}/", headers={"Accept": "text/html"}, timeout=10
        )
        print(f"[*] Home page: HTTP {initial.status_code}")
    except requests.RequestException as exc:
        print(f"[ERROR] Could not reach local lab: {exc}", file=sys.stderr)
        return 1

    csrf = extract_csrf(initial.text)
    if csrf:
        session.headers["X-CSRF-TOKEN"] = csrf
        print("[+] CSRF meta token detected.")
    else:
        print("[i] No CSRF meta token detected; lab may use another mechanism.")

    read_url = f"{base_url}/api/ratings/1"
    try:
        response = session.get(read_url, timeout=10)
        print(f"[*] Read check: HTTP {response.status_code}")
        print(response.text[:500])
    except requests.RequestException as exc:
        print(f"[ERROR] Read request failed: {exc}", file=sys.stderr)

    if not args.execute_writes:
        print("[DRY RUN] No POST requests were sent.")
        print(
            f"Use --execute-writes to perform at most {MAX_WRITES} "
            "submissions against this local lab."
        )
        return 0

    print(f"[!] Write checks enabled; maximum {MAX_WRITES} local submissions.")
    write_url = f"{base_url}/api/ratings"

    for index in range(1, MAX_WRITES + 1):
        payload = {
            "resource_id": 1,
            "rating": 3,
            "comment": f"authorized-lab-check-{index}",
            "_token": csrf,
        }
        try:
            response = session.post(write_url, json=payload, timeout=10)
            print(f"POST {index}: HTTP {response.status_code}")
            print(response.text[:250])
        except requests.RequestException as exc:
            print(f"[ERROR] POST {index} failed: {exc}")

    try:
        response = session.get(read_url, timeout=10)
        print(f"[*] Read after writes: HTTP {response.status_code}")
        print(response.text[:500])
    except requests.RequestException as exc:
        print(f"[ERROR] Final read failed: {exc}", file=sys.stderr)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
