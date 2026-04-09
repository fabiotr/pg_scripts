## 2025-05-15 - [Markdown Report Formatting]
**Learning:** For reports generated via CLI (like psql) that are intended to be viewed in Markdown-capable environments, wrapping raw SQL output or command lists in code blocks significantly improves the UX by preventing unintentional formatting and providing syntax highlighting.
**Action:** Always wrap generated SQL or CLI command outputs in Markdown code blocks (```sql or ```bash) when enhancing database audit reports.

## 2025-05-16 - [Heading Hierarchy and Code Block Semantics]
**Learning:** In long-form Markdown reports generated via CLI, maintaining a strictly sequential heading hierarchy (e.g., Level 1 -> Level 2 -> Level 3) is critical for scannability and accessibility (TOC generation). Additionally, differentiating between `text` and `bash` code blocks based on whether the content is raw output or configuration/scripting improves syntax highlighting clarity.
**Action:** Avoid skipping heading levels (e.g., don't use `####` if the parent is `##`). Use `text` for raw CLI outputs and `bash` for configuration files or scripts in report generation.

## 2025-05-17 - [Dynamic Metadata Interpolation in psql Reports]
**Learning:** To provide consistent and detailed report metadata (like full server version) across multiple psql scripts, aliasing system function outputs in a configuration `SELECT` followed by `\gset` ensures that custom variables (e.g., `:svp_server_version`) are reliably available for `\qecho` commands.
**Action:** Always alias `current_setting('server_version')` as `server_version` in the initial configuration query of report scripts to enable the use of `:svp_server_version` for detailed version reporting.
