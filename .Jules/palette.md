## 2025-05-15 - [Markdown Report Formatting]
**Learning:** For reports generated via CLI (like psql) that are intended to be viewed in Markdown-capable environments, wrapping raw SQL output or command lists in code blocks significantly improves the UX by preventing unintentional formatting and providing syntax highlighting.
**Action:** Always wrap generated SQL or CLI command outputs in Markdown code blocks (```sql or ```bash) when enhancing database audit reports.

## 2025-05-22 - [Report Visual Hierarchy & Cues]
**Learning:** Using emojis in top-level Markdown headers for database reports provides immediate visual cues for different information categories (e.g., 🐘 for cluster/database, 📊 for statistics, 🛡️ for security). Additionally, maintaining a shallow heading hierarchy (avoiding Level 4) ensures better scannability in long audit reports.
**Action:** Use sanctioned emojis (🐘, 📊, 🛡️, etc.) in report headers and prefer Level 3 (###) over Level 4 (####) for secondary sections.
