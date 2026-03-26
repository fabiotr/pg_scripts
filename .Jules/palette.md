## 2025-05-15 - [Markdown Report Formatting]
**Learning:** For reports generated via CLI (like psql) that are intended to be viewed in Markdown-capable environments, wrapping raw SQL output or command lists in code blocks significantly improves the UX by preventing unintentional formatting and providing syntax highlighting.
**Action:** Always wrap generated SQL or CLI command outputs in Markdown code blocks (```sql or ```bash) when enhancing database audit reports.

## 2025-05-20 - [Report Accessibility & Visual Delight]
**Learning:** Standardizing header emojis and fixing Markdown heading hierarchy in psql-generated reports significantly improves both visual delight and accessibility (proper TOC generation and screen reader navigation).
**Action:** Use emojis in major headers for visual consistency with branding and ensure a logical H1-H2-H3 hierarchy even when generating reports via multiple nested SQL scripts.
