# API Security Testing Toolkit

Small Bash and Python utilities for authorized API security validation in a controlled lab.

## Scope

- HTTP session and CSRF handling
- API response inspection
- Input-validation checks
- Basic request-frequency observation
- Safe, explicitly authorized test execution

These scripts are educational examples, not vulnerability scanners. An HTTP `200` response alone does not prove SQL injection, XSS, or another vulnerability.

## Safety defaults

- Default target: `http://127.0.0.1:8000`
- Only loopback targets (`127.0.0.1`, `localhost`, `::1`) are accepted.
- POST requests are disabled unless `--execute-writes` is supplied.
- The scripts do not contain production domains, credentials, tokens, or assessment evidence.
- Use only against applications you own or are explicitly authorized to test.

## Requirements

- Bash script: `curl`, `grep`, `mktemp`
- Python script: Python 3.9+ and `requests`

Install Python dependency:

```bash
python3 -m pip install requests
```

## Usage

### Bash

Dry run (no POST requests):

```bash
bash scripts/api-validation.sh
```

Execute the limited write test against a local lab:

```bash
bash scripts/api-validation.sh --execute-writes
```

### Python

Dry run:

```bash
python3 scripts/api-security-checks.py
```

Execute the limited write checks against a local lab:

```bash
python3 scripts/api-security-checks.py --execute-writes
```

Both scripts expect a lab application exposing:

- `GET /` with a `<meta name="csrf-token" content="...">` tag (optional for read-only mode)
- `POST /api/ratings` accepting JSON fields `resource_id`, `rating`, `comment`, `_token`
- `GET /api/ratings/1` returning a JSON response

Adapt the paths and field names to your own deliberately vulnerable lab. Keep the loopback restriction unless you have a separately reviewed, authorized test harness.

## Repository layout

```text
scripts/  Bash and Python examples
docs/     Methodology and reporting guidance
examples/ Sanitized sample response
```

## Disclaimer

The tools are provided "as is" for learning and authorized testing. They do not establish that a target is vulnerable. Review requests and responses, application behavior, and server-side logs before reporting a finding.
