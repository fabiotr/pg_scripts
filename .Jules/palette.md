## 2025-05-15 - [Markdown Report Formatting]
**Learning:** For reports generated via CLI (like psql) that are intended to be viewed in Markdown-capable environments, wrapping raw SQL output or command lists in code blocks significantly improves the UX by preventing unintentional formatting and providing syntax highlighting.
**Action:** Always wrap generated SQL or CLI command outputs in Markdown code blocks (```sql or ```bash) when enhancing database audit reports.

## 2025-05-16 - [Heading Hierarchy and Code Block Semantics]
**Learning:** In long-form Markdown reports generated via CLI, maintaining a strictly sequential heading hierarchy (e.g., Level 1 -> Level 2 -> Level 3) is critical for scannability and accessibility (TOC generation). Additionally, differentiating between `text` and `bash` code blocks based on whether the content is raw output or configuration/scripting improves syntax highlighting clarity.
**Action:** Avoid skipping heading levels (e.g., don't use `####` if the parent is `##`). Use `text` for raw CLI outputs and `bash` for configuration files or scripts in report generation.

## 2025-05-17 - [SQL Terminology and Metadata Alignment]
**Learning:** Terminology such as "resume" (from the Portuguese "resumo") should be localized to "summary" in professional English reports. Additionally, in `psql` scripts, unquoting variables in `\qecho` (e.g., `\qecho 'Title ' :variable`) and quoting metadata labels (e.g., `\qecho '- Date:     ' :date`) is necessary to ensure correct interpolation and preserve visual alignment by preventing space collapsing.
**Action:** Standardize "resume" to "summary" in report headers and documentation. Always unquote psql variables and quote static labels in `\qecho` commands for consistent report formatting.
