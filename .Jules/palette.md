## 2025-05-15 - [Markdown Report Formatting]
**Learning:** For reports generated via CLI (like psql) that are intended to be viewed in Markdown-capable environments, wrapping raw SQL output or command lists in code blocks significantly improves the UX by preventing unintentional formatting and providing syntax highlighting.
**Action:** Always wrap generated SQL or CLI command outputs in Markdown code blocks (```sql or ```bash) when enhancing database audit reports.

## 2025-05-16 - [Heading Hierarchy and Code Block Semantics]
**Learning:** In long-form Markdown reports generated via CLI, maintaining a strictly sequential heading hierarchy (e.g., Level 1 -> Level 2 -> Level 3) is critical for scannability and accessibility (TOC generation). Additionally, differentiating between `text` and `bash` code blocks based on whether the content is raw output or configuration/scripting improves syntax highlighting clarity.
**Action:** Avoid skipping heading levels (e.g., don't use `####` if the parent is `##`). Use `text` for raw CLI outputs and `bash` for configuration files or scripts in report generation.

## 2026-04-04 - [UX Consistency Across Report Types]
**Learning:** Maintaining a consistent visual language (emojis, metadata fields, TOC placement) between different report formats (SQL-generated vs Shell-generated) improves the user's mental model and makes the suite of tools feel like a cohesive product.
**Action:** When enhancing one report type, audit other report-generating scripts in the repository to ensure they share the same headers, emojis, and metadata patterns.
