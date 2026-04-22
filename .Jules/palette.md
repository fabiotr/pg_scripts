## 2025-05-15 - [Markdown Report Formatting]
**Learning:** For reports generated via CLI (like psql) that are intended to be viewed in Markdown-capable environments, wrapping raw SQL output or command lists in code blocks significantly improves the UX by preventing unintentional formatting and providing syntax highlighting.
**Action:** Always wrap generated SQL or CLI command outputs in Markdown code blocks (```sql or ```bash) when enhancing database audit reports.

## 2025-05-16 - [Heading Hierarchy and Code Block Semantics]
**Learning:** In long-form Markdown reports generated via CLI, maintaining a strictly sequential heading hierarchy (e.g., Level 1 -> Level 2 -> Level 3) is critical for scannability and accessibility (TOC generation). Additionally, differentiating between `text` and `bash` code blocks based on whether the content is raw output or configuration/scripting improves syntax highlighting clarity.
**Action:** Avoid skipping heading levels (e.g., don't use `####` if the parent is `##`). Use `text` for raw CLI outputs and `bash` for configuration files or scripts in report generation.

## 2025-05-17 - [psql Variable Interpolation and Metadata Alignment]
**Learning:** In `psql` scripts, variables within `\qecho` commands are only interpolated if the argument is unquoted. Wrapping the entire line in single quotes disables interpolation (e.g., `\qecho 'Report for :DBNAME'`). To preserve indentation and ensure proper variable display, metadata labels should be quoted as separate arguments (e.g., `\qecho '- Date:     ' :variable`).
**Action:** Use a mix of quoted labels and unquoted variables in `\qecho` commands to ensure correct metadata display and consistent alignment in Markdown reports.
