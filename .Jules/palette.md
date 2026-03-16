## 2025-05-15 - [Markdown Report Formatting]
**Learning:** For reports generated via CLI (like psql) that are intended to be viewed in Markdown-capable environments, wrapping raw SQL output or command lists in code blocks significantly improves the UX by preventing unintentional formatting and providing syntax highlighting.
**Action:** Always wrap generated SQL or CLI command outputs in Markdown code blocks (```sql or ```bash) when enhancing database audit reports.
