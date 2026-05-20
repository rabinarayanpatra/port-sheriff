# Security Policy

## Reporting a Vulnerability

If you find a security issue in Port Sheriff, please **do not** open a public GitHub issue.

Email the maintainer at **rabinarayanpatra1999@gmail.com** with:

- A description of the issue.
- Steps to reproduce.
- The version (commit SHA) you observed it on.
- Any proof-of-concept code or sample output.

You will receive an acknowledgement within 5 business days. Fixes for confirmed vulnerabilities are prioritized over feature work.

## Scope

In scope:

- Privilege escalation via Port Sheriff (e.g. killing processes the current user should not be able to kill).
- Arbitrary code execution triggered by crafted `lsof` output, rule data, or `UserDefaults` content.
- Bypasses of the system-process protection.
- Data leakage from the alert log or settings store.

Out of scope:

- Issues that require root or physical access already.
- Bugs in Apple-supplied components (`lsof`, `launchd`, kernel) — report those to Apple.
- Denial of service achievable only by killing your own processes.

## Supported Versions

Port Sheriff is pre-1.0. Only the `main` branch is supported. Pinning to a tagged release is recommended once 1.0 ships.
