## 2025-05-15 - [Markdown Report Formatting]
**Learning:** For reports generated via CLI (like psql) that are intended to be viewed in Markdown-capable environments, wrapping raw SQL output or command lists in code blocks significantly improves the UX by preventing unintentional formatting and providing syntax highlighting.
**Action:** Always wrap generated SQL or CLI command outputs in Markdown code blocks (```sql or ```bash) when enhancing database audit reports.

## 2025-05-22 - [Psql Report Variable Interpolation]
**Learning:** In `psql` scripts, variables (e.g., `:DBNAME`, `:HOST`) used within `\qecho` commands are only interpolated if the argument is unquoted. Wrapping the entire line in single quotes to "clean up" the syntax or handle special characters (like emojis) disables interpolation, breaking the report's dynamic headers.
**Action:** Keep `\qecho` arguments unquoted when variable interpolation is required, even when adding emojis or other decorative elements.
