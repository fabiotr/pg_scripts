# Contributing to PostgreSQL DBA Essentials

First of all, thank you for considering contributing to this project! It is people like you who make this a great resource for the PostgreSQL community.

## 📜 Code of Conduct
By participating in this project, you agree to maintain a professional and respectful environment for everyone.

## 🛠️ How Can I Contribute?

### Adding New Scripts
We are always looking for new scripts! To ensure consistency, please follow these guidelines:

1. **Version Compatibility**: Ideally, scripts should be compatible from PostgreSQL 8.2 to the current version. If a script requires a specific version (e.g., `PG >= 16`), please state it clearly in the comments.
2. **Metadata Header**: Every script should start with a brief comment explaining:
   - What it does.
   - The required permissions (e.g., superuser).
   - Any external extensions needed (e.g., `pg_stat_statements`).
3. **Coding Style**:
   - Use meaningful alias names for joins.
   - Use uppercase for SQL keywords (`SELECT`, `FROM`, `WHERE`) for consistency with the existing library.
   - Avoid hardcoded schema names unless necessary.

4. **Run the checks** before opening a PR (CI runs them too):
   - `./tools/check_dispatchers.sh` must print `All dispatchers OK`.
   - `./tools/check_keywords.py` must print `All keywords OK`. `./tools/check_keywords.py --fix` uppercases the keywords it reports, but leaves alone any file with an ambiguous string (a plain `'...'` with a backslash right before one of its quotes): rewrite that string by hand with `''` or `E'...'`.
   - If you change `tools/check_keywords.py`, run its tests: `python3 -m unittest discover -s tools -p 'test_*.py'`.

### Improving Existing Scripts
If you find a bug or a way to make a query more efficient (e.g., reducing I/O overhead), please submit a Pull Request!

## 📤 Submission Process

1. **Fork** the repository.
2. **Create a Branch** for your feature (`git checkout -b feature/NewAwesomeScript`).
3. **Commit** your changes (`git commit -m 'Add: New script for analyzing X'`).
4. **Push** to your branch (`git push origin feature/NewAwesomeScript`).
5. **Open a Pull Request** and describe:
   - What the script does.
   - Which category it belongs to (Assessment, Troubleshooting, etc.).
   - The scope (Cluster or Database).

## 📂 Category Standard
When adding a script, please suggest which category it fits into:
- **Assessment**: General inventory and stats.
- **Maintenance**: Cleanup and fixes.
- **Migration**: Tools for version upgrades.
- **Object/Parameter Tuning**: Optimization.
- **Query Tuning**: SQL performance.
- **Replication**: High Availability and Logical/Physical replication.
- **Security**: Auditing and permissions.
- **Troubleshooting**: Emergency and active incident response.

---
*Thank you for helping us build the best PostgreSQL script toolbox!*
