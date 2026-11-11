# Security Policy

## Supported Versions

This repository has no releases. Only the `main` branch is maintained, and fixes land there.

## Reporting a Vulnerability

Please **do not open a public issue** for security problems.

Report them privately through GitHub: go to the **Security** tab of this repository and click **Report a vulnerability**
(or use [this link](https://github.com/fabiotr/pg_scripts/security/advisories/new)).

Please include:

- the affected file(s) and the PostgreSQL version(s) you used;
- how to reproduce the problem;
- what an attacker could gain from it.

## Scope

In scope:

- scripts that leak credentials, connection strings or other secrets (in output, logs or temporary files);
- SQL injection or shell injection through script parameters or object names;
- scripts that grant, or silently require, more privileges than they document;
- the CI workflows in `.github/workflows`.

Out of scope:

- bugs or vulnerabilities in PostgreSQL itself, which should be reported to the
  [PostgreSQL Security Team](https://www.postgresql.org/support/security/);
- scripts that need superuser by design, when this is stated in their header (see [CONTRIBUTING.md](CONTRIBUTING.md)).

## Response

This is a personal project maintained on a best-effort basis. You can expect a first answer within 7 days.
Once a fix is merged, the report is disclosed through a GitHub security advisory, crediting you unless you prefer otherwise.
