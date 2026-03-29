## 2025-05-15 - [Markdown Report Formatting]
**Learning:** For reports generated via CLI (like psql) that are intended to be viewed in Markdown-capable environments, wrapping raw SQL output or command lists in code blocks significantly improves the UX by preventing unintentional formatting and providing syntax highlighting.
**Action:** Always wrap generated SQL or CLI command outputs in Markdown code blocks (```sql or ```bash) when enhancing database audit reports.

## 2025-05-22 - [Heading Hierarchy and Scannability]
**Learning:** In long-form technical Markdown reports (like database audits), a strictly sequential heading hierarchy (L1 -> L2 -> L3) is essential for screen reader accessibility and document outline generation. Additionally, using consistent emojis as prefix icons for major sections significantly improves scannability and visual delight without compromising professional tone.
**Action:** Always ensure a logical heading progression and use the sanctioned emoji set (🐘, 📌, 📊, etc.) for section headers in all report-generating scripts.
