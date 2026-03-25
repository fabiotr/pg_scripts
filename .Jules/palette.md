## 2025-05-15 - [Markdown Report Formatting]
**Learning:** For reports generated via CLI (like psql) that are intended to be viewed in Markdown-capable environments, wrapping raw SQL output or command lists in code blocks significantly improves the UX by preventing unintentional formatting and providing syntax highlighting.
**Action:** Always wrap generated SQL or CLI command outputs in Markdown code blocks (```sql or ```bash) when enhancing database audit reports.

## 2025-05-16 - [Visual Delight in CLI Reports]
**Learning:** Adding emojis to major headers in CLI-generated Markdown reports significantly improves scannability and "visual delight" without impacting the technical data. It makes the reports feel more like a modern dashboard and less like a legacy log file.
**Action:** Use relevant emojis (🐘, 📊, ⏱️) for top-level headers in SQL report templates to enhance the user experience of the final output.
