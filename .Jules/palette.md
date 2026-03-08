## 2025-05-14 - [Documentation UX & Navigation Polish]
**Learning:** Even in non-UI repositories, the README is the primary user interface. Broken links and inconsistent capitalization in tables degrade trust and usability. GitHub's slugification for headers with emojis (e.g., `## ✨ Header`) results in anchors like `#-header`, which must be carefully verified.
**Action:** Always verify TOC anchors against actual GitHub-rendered IDs and use `grep` to ensure consistency in table columns and link syntax across the entire document.
