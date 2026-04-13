## 2025-05-15 - [Markdown Report Formatting]
**Learning:** For reports generated via CLI (like psql) that are intended to be viewed in Markdown-capable environments, wrapping raw SQL output or command lists in code blocks significantly improves the UX by preventing unintentional formatting and providing syntax highlighting.
**Action:** Always wrap generated SQL or CLI command outputs in Markdown code blocks (```sql or ```bash) when enhancing database audit reports.

## 2025-05-16 - [Heading Hierarchy and Code Block Semantics]
**Learning:** In long-form Markdown reports generated via CLI, maintaining a strictly sequential heading hierarchy (e.g., Level 1 -> Level 2 -> Level 3) is critical for scannability and accessibility (TOC generation). Additionally, differentiating between `text` and `bash` code blocks based on whether the content is raw output or configuration/scripting improves syntax highlighting clarity.
**Action:** Avoid skipping heading levels (e.g., don't use `####` if the parent is `##`). Use `text` for raw CLI outputs and `bash` for configuration files or scripts in report generation.

## 2025-05-17 - [Psql Report Variable Interpolation and Alignment]
**Learning:** In `psql` scripts using `\qecho` for report generation, variables (e.g., `:DBNAME`) are only interpolated if they are unquoted or passed as separate arguments. Wrapping the entire line in single quotes prevents interpolation. Additionally, quoting labels (e.g., `\qecho '- Date:     ' :svp_date`) preserves whitespace for better alignment in the generated output.
**Action:** For `psql` report templates, move variables outside of literal strings in `\qecho` commands and use quoted labels to ensure both correct value display and consistent visual alignment of metadata.
