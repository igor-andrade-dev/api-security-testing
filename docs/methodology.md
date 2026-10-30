# Test methodology

## Objective

Practice repeatable validation of API behavior in an isolated, authorized lab.

## Checks

1. Establish an HTTP session.
2. Inspect whether the home page exposes a CSRF meta token.
3. Read a known lab resource.
4. Optionally submit a small, bounded number of clearly labeled test records.
5. Inspect the response and resulting lab state.

## Interpretation

- HTTP status codes are signals, not proof of a vulnerability.
- A `200` response does not prove SQL injection or XSS.
- A `500` response does not by itself prove information disclosure.
- Confirm findings using application behavior, server-side logs, and controlled test data.

## Safety

The included scripts reject non-loopback hostnames and default to read-only dry-run mode. Do not remove those safeguards casually.
