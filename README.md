# API Security Testing Toolkit

Small Bash and Python utilities for practicing API security validation in controlled, authorized lab environments.

## Overview

This repository contains three examples:

| Script | Purpose |
|---|---|
| `scripts/api-validation.sh` | Bash-based HTTP session, CSRF, response and limited write checks |
| `scripts/api-security-checks.py` | Python-based API response and input-validation checks |
| `scripts/python/api-pentest-lab.py` | Local-only lab demonstration with response-header inspection and optional labeled test records |

These tools are educational examples, not vulnerability scanners. An HTTP `200` response does not prove SQL injection, XSS, or another vulnerability. An HTTP `500` response does not by itself prove information disclosure.

## Safety defaults

- Default target: `http://127.0.0.1:8000`
- Scripts that include target validation accept only loopback hosts: `127.0.0.1`, `localhost` and `::1`.
- Write operations are disabled by default where supported.
- Write demonstrations are bounded and use clearly labeled test data.
- No production domains, credentials, session tokens, internal IP addresses or real assessment evidence are included.
- Use only against applications you own or are explicitly authorized to test.

Do not remove the loopback restrictions to test public systems. For an authorized assessment, use an approved test harness and written scope.

## Requirements

- Bash example: `curl`, `grep`, `mktemp`
- Python examples: Python 3.9+ and `requests`

Install the Python dependency:

```bash
python3 -m pip install requests
```

## Usage

Run commands from the repository root.

### Bash validation

Default mode (read-only):

```bash
bash scripts/api-validation.sh
```

Optional bounded write demonstration against the local lab:

```bash
bash scripts/api-validation.sh --execute-writes
```

### Python API checks

Default mode (read-only):

```bash
python3 scripts/api-security-checks.py
```

Optional bounded write checks:

```bash
python3 scripts/api-security-checks.py --execute-writes
```

### Advanced Python lab demonstration

Default mode (read-only):

```bash
python3 scripts/python/api-pentest-lab.py
```

Optional write demonstration (maximum three labeled records):

```bash
python3 scripts/python/api-pentest-lab.py --write-demo
```

The scripts expect a compatible local lab application. The examples use routes such as:

- `GET /` — lab home page; may contain a CSRF meta tag
- `GET /api/ratings/1` — read a sample resource
- `POST /api/ratings` — optional lab-only write demonstration

Adapt route names and field names only within your own lab. The scripts are not guaranteed to work with arbitrary APIs without adaptation.

## Repository layout

```text
api-security-testing/
├── README.md
├── LICENSE
├── .gitignore
├── scripts/
│   ├── api-validation.sh
│   ├── api-security-checks.py
│   └── python/
│       └── api-pentest-lab.py
├── docs/
│   ├── findings-template.md
│   └── methodology.md
└── examples/
    └── sample-response.json
```

## Interpreting results

- Treat status codes as observations, not proof of exploitability.
- Validate suspected issues through controlled behavior, application logs and repeatable evidence.
- Do not submit destructive payloads or persistent test data to production.
- Document scope, prerequisites, expected behavior, actual behavior and impact.

## Disclaimer

The tools are provided "as is" for educational purposes and authorized security testing. They do not independently confirm vulnerabilities. The user is responsible for obtaining authorization, respecting the assessment scope and reviewing all requests before execution.
