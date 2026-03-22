## 2026-03-22 - [Broken Includes due to Naming Inconsistency]
**Learning:** In a modular SQL environment using `\i` or `\ir`, naming inconsistencies (like `calls` vs `call` or `labels` vs `labes`) can lead to silent report failures or errors. These are critical UX issues for DBA tools where reliability is paramount.
**Action:** Always cross-reference the `sql/` directory contents when modifying inclusion logic or updating report structures to ensure all referenced files exist.
