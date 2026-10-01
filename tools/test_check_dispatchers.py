#!/usr/bin/env python3
"""Tests for check_dispatchers.py: each rule is run against a throwaway repo.

Run from the repository root:
    python3 -m unittest discover -s tools -p 'test_*.py' -v

CHECK_DISPATCHERS overrides the script under test (used to check that a
mutated copy makes these tests fail).
"""
import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(os.environ.get("CHECK_DISPATCHERS",
                             Path(__file__).absolute().parent / "check_dispatchers.py"))

# A minimal dispatcher that follows every convention
DISPATCHER = """\\if :svp_pg_16
    \\ir t_16up.sql
\\elif :svp_pg_10
    \\ir t_10up.sql
\\else
    \\qecho - Not supported on version :svp_server_version
\\endif
"""
CLEAN = {
    "sql/variables.sql": "\\set svp_pg_16 true\n",
    "sql/t.sql": DISPATCHER,
    "sql/t_16up.sql": "SELECT 1;\n",
    "sql/t_10up.sql": "SELECT 1;\n",
}


def run(files):
    """Runs the check on a repo made of files ({path: content}).
    Returns (exit code, output)."""
    root = Path(tempfile.mkdtemp())
    try:
        for path, content in files.items():
            (root / path).parent.mkdir(parents=True, exist_ok=True)
            (root / path).write_text(content)
        p = subprocess.run([str(SCRIPT), str(root)], capture_output=True, text=True,
                           stdin=subprocess.DEVNULL, timeout=30)
        return p.returncode, p.stdout + p.stderr
    finally:
        shutil.rmtree(root)


def with_files(changes):
    """CLEAN with some files added or replaced ({path: content}) or removed (None)."""
    files = dict(CLEAN, **changes)
    return {path: content for path, content in files.items() if content is not None}


class CheckDispatchers(unittest.TestCase):
    def assertProblem(self, files, text, where=None):
        code, out = run(files)
        self.assertEqual(code, 1, out)
        self.assertIn(text, out)
        if where:
            self.assertIn(where, out)
        self.assertIn("problem(s) found", out)

    def test_clean_repo_passes(self):
        code, out = run(CLEAN)
        self.assertEqual(code, 0, out)
        self.assertIn("All dispatchers OK", out)

    def test_not_the_repo(self):
        code, out = run({"README.md": "x\n"})
        self.assertEqual(code, 2, out)
        self.assertIn("sql/variables.sql not found", out)

    def test_backslash_i_in_sql(self):
        self.assertProblem(with_files({"sql/t.sql": DISPATCHER.replace("\\ir t_10up", "\\i t_10up")}),
                           "uses \\i t_10up.sql", "sql/t.sql:4:")

    def test_backslash_i_in_reports_is_allowed(self):
        files = with_files({"reports/r.sql": "\\i sql/t.sql\n"})
        code, out = run(files)
        self.assertEqual(code, 0, out)

    def test_file_included_only_from_reports_is_reachable(self):
        files = with_files({"sql/t_14up.sql": "SELECT 1;\n", "reports/r.sql": "\\ir ../sql/t_14up.sql\n"})
        code, out = run(files)
        self.assertEqual(code, 0, out)

    def test_missing_include_in_reports(self):
        self.assertProblem(with_files({"reports/r.sql": "\\ir ../sql/nope.sql\n"}),
                           "includes ../sql/nope.sql, which does not exist", "reports/r.sql:1:")

    def test_missing_include(self):
        self.assertProblem(with_files({"sql/t_10up.sql": None}),
                           "includes t_10up.sql, which does not exist", "sql/t.sql:4:")

    def test_include_built_from_a_variable_is_not_checked(self):
        files = with_files({"sql/v.sql": "\\ir :sql_dir/whatever.sql\n"})
        code, out = run(files)
        self.assertEqual(code, 0, out)

    def test_comment_lines_are_ignored(self):
        # the message check isn't anchored, so only the comment skip keeps it quiet here
        files = with_files({"sql/v.sql": "-- \\qecho - not supported on version 9.4\n"})
        code, out = run(files)
        self.assertEqual(code, 0, out)

    def test_commands_inside_block_comments_are_ignored(self):
        files = with_files({"sql/v.sql": "/*\n\\i missing.sql\n\\qecho - not supported on version\n*/\n"})
        code, out = run(files)
        self.assertEqual(code, 0, out)

    def test_commands_inside_dollar_quoted_bodies_are_ignored(self):
        files = with_files({"sql/v.sql": "DO $$\nBEGIN\n\\i missing.sql\nEND $$;\n"})
        code, out = run(files)
        self.assertEqual(code, 0, out)

    def test_symlinked_hook_checks_the_git_top_level(self):
        # run as .git/hooks/pre-commit -> ../../tools/check_dispatchers.py, no argument
        root = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, root)
        for path, content in with_files({"sql/t_14up.sql": "SELECT 1;\n"}).items():
            (root / path).parent.mkdir(parents=True, exist_ok=True)
            (root / path).write_text(content)
        subprocess.run(["git", "init", "-q", str(root)], check=True)
        (root / "tools").mkdir()
        for name in ("check_dispatchers.py", "check_sql_style.py"):
            shutil.copy(SCRIPT.parent / name, root / "tools" / name)
        hook = root / ".git" / "hooks" / "pre-commit"
        hook.parent.mkdir(parents=True, exist_ok=True)
        hook.symlink_to("../../tools/check_dispatchers.py")
        p = subprocess.run([str(hook)], cwd=root, capture_output=True, text=True,
                           stdin=subprocess.DEVNULL, timeout=30)
        self.assertEqual(p.returncode, 1, p.stdout + p.stderr)
        self.assertIn("sql/t_14up.sql: is not included by any script (unreachable)", p.stdout)

    def test_version_mismatch(self):
        self.assertProblem(
            with_files({"sql/t.sql": DISPATCHER.replace("\\elif :svp_pg_10", "\\elif :svp_pg_11")}),
            "branch svp_pg_11 includes t_10up.sql (version mismatch)", "sql/t.sql:4:")

    def test_branches_out_of_order(self):
        swapped = ("\\if :svp_pg_10\n    \\ir t_10up.sql\n\\elif :svp_pg_16\n    \\ir t_16up.sql\n"
                   "\\else\n    \\qecho - Not supported on version :svp_server_version\n\\endif\n")
        self.assertProblem(with_files({"sql/t.sql": swapped}),
                           "branch svp_pg_16 comes after svp_pg_10", "sql/t.sql:3:")

    def test_old_versions_compare_as_numbers(self):
        # 96 is 9.6, older than 10: 10 -> 96 -> 82 is the right order
        chain = ("\\if :svp_pg_10\n    \\ir t_10up.sql\n\\elif :svp_pg_96\n    \\ir t_96up.sql\n"
                 "\\elif :svp_pg_82\n    \\ir t_82up.sql\n\\endif\n")
        files = with_files({"sql/t.sql": chain, "sql/t_16up.sql": None,
                            "sql/t_96up.sql": "SELECT 1;\n", "sql/t_82up.sql": "SELECT 1;\n"})
        code, out = run(files)
        self.assertEqual(code, 0, out)

    def test_unreachable_versioned_file(self):
        files = with_files({"sql/t_14up.sql": "SELECT 1;\n"})
        self.assertProblem(files, "sql/t_14up.sql: is not included by any script (unreachable)")

    def test_unreachable_minus_file(self):
        files = with_files({"sql/t_95-.sql": "SELECT 1;\n"})
        self.assertProblem(files, "sql/t_95-.sql: is not included by any script (unreachable)")

    def test_lowercase_not_supported(self):
        self.assertProblem(with_files({"sql/t.sql": DISPATCHER.replace("Not supported", "not supported")}),
                           "(capital N)", "sql/t.sql:6:")

    def test_nested_if_restores_the_outer_branch(self):
        # after the inner \endif, t_10up.sql is back in the svp_pg_16 branch
        nested = ("\\if :svp_pg_16\n    \\if :other\n    \\endif\n    \\ir t_10up.sql\n"
                  "\\elif :svp_pg_10\n    \\ir t_16up.sql\n\\endif\n")
        self.assertProblem(with_files({"sql/t.sql": nested}),
                           "branch svp_pg_16 includes t_10up.sql (version mismatch)", "sql/t.sql:4:")

    def test_include_in_a_non_version_branch_is_not_matched(self):
        # the inner branch's condition isn't a version, so the file name isn't compared
        nested = ("\\if :svp_pg_16\n    \\if :other\n        \\ir t_10up.sql\n    \\endif\n"
                  "    \\ir t_16up.sql\n\\endif\n")
        code, out = run(with_files({"sql/t.sql": nested}))
        self.assertEqual(code, 0, out)

    def test_else_branch_is_not_matched(self):
        chain = "\\if :svp_pg_16\n    \\ir t_16up.sql\n\\else\n    \\ir t_10up.sql\n\\endif\n"
        code, out = run(with_files({"sql/t.sql": chain}))
        self.assertEqual(code, 0, out)


if __name__ == "__main__":
    unittest.main()
