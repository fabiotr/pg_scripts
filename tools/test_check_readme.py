#!/usr/bin/env python3
"""Tests for check_readme.py: each case is a throwaway repository.

Run from the repository root:
    python3 -m unittest discover -s tools -p 'test_*.py' -v

CHECK_README overrides the script under test (used to check that a mutated
copy makes these tests fail).
"""
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(os.environ.get("CHECK_README",
                             Path(__file__).absolute().parent / "check_readme.py"))

DISPATCHER = """\\ir variables.sql

\\if :svp_pg_16
  \\ir {name}_16up.sql
\\elif :svp_pg_95
  \\ir {name}_95up.sql
\\else
  \\qecho - Not supported on version :svp_server_version
\\endif
\\timing on
\\set QUIET off
"""


class CheckReadmeTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.repo = Path(self.tmp.name)
        (self.repo / "sql").mkdir()
        (self.repo / "reports").mkdir()
        (self.repo / "sql" / "variables.sql").write_text("-- vars\n")

    def tearDown(self):
        self.tmp.cleanup()

    def sql(self, name, text):
        (self.repo / "sql" / name).write_text(text)

    def readme(self, *rows):
        (self.repo / "README.md").write_text(
            "# Catalog\n\n| Scope | Name | Version | Description |\n|---|---|---|---|\n" + "\n".join(rows) + "\n")

    def run_check(self):
        p = subprocess.run([sys.executable, str(SCRIPT), str(self.repo)], capture_output=True, text=True)
        return p.returncode, p.stdout + p.stderr

    def test_consistent_catalog(self):
        self.sql("a.sql", DISPATCHER.format(name="a"))
        self.sql("a_16up.sql", "SELECT 1;\n")
        self.sql("b.sql", "SELECT 1;\n")  # unversioned: no version to compare
        self.readme("| Database | `a.sql` | PG >= 9.5 | A |", "| Database | `b.sql` |  | B |",
                    "| Cluster | `report_cluster.sql` | | report |")
        (self.repo / "reports" / "report_cluster.sql").write_text("-- r\n")
        rc, out = self.run_check()
        self.assertEqual(rc, 0, out)
        self.assertIn("README catalog OK", out)

    def test_missing_row(self):
        self.sql("a.sql", DISPATCHER.format(name="a"))
        self.readme()
        rc, out = self.run_check()
        self.assertEqual(rc, 1, out)
        self.assertIn("sql/a.sql:1: entry script missing from the README catalog", out)
        self.assertNotIn("variables.sql", out)

    def test_row_without_file(self):
        self.readme("| Database | `gone.sql` | | Gone |")
        rc, out = self.run_check()
        self.assertEqual(rc, 1, out)
        self.assertIn("README.md:5: `gone.sql` is in the catalog but not in sql/ or reports/", out)

    def test_version_mismatch(self):
        self.sql("a.sql", DISPATCHER.format(name="a"))
        self.readme("| Database | `a.sql` | PG >= 9.4 | A |")
        rc, out = self.run_check()
        self.assertEqual(rc, 1, out)
        self.assertIn("`a.sql` says PG >= 9.4, its dispatcher supports PG >= 9.5", out)

    def test_empty_cell_and_82_mean_every_version(self):
        self.sql("a.sql", DISPATCHER.format(name="a").replace("svp_pg_95", "svp_pg_82").replace("_95up", "_82up"))
        self.sql("c.sql", DISPATCHER.format(name="c").replace("svp_pg_95", "svp_pg_82").replace("_95up", "_82up"))
        self.readme("| Database | `a.sql` |  | A |", "| Database | `c.sql` | PG >= 8.2 | C |")
        rc, out = self.run_check()
        self.assertEqual(rc, 0, out)
        self.sql("d.sql", DISPATCHER.format(name="d"))
        self.readme("| Database | `a.sql` |  | A |", "| Database | `c.sql` | PG >= 8.2 | C |",
                    "| Database | `d.sql` |  | D |")
        rc, out = self.run_check()
        self.assertIn("`d.sql` says (empty), its dispatcher supports PG >= 9.5", out)

    def test_else_that_includes_a_file_means_every_version(self):
        self.sql("a.sql", "\\ir variables.sql\n\\if :svp_pg_10\n  \\ir a_10up.sql\n\\else\n  \\ir a_old.sql\n\\endif\n")
        self.readme("| Database | `a.sql` |  | A |")
        rc, out = self.run_check()
        self.assertEqual(rc, 0, out)

    def test_nested_ifs_are_not_versions(self):
        self.sql("a.sql", "\\ir variables.sql\n\\if :svp_pg_95\n  \\if :svp_pg_12\n    \\ir a_12up.sql\n"
                          "  \\else\n    \\ir a_95up.sql\n  \\endif\n\\else\n  \\qecho - Not supported on version x\n\\endif\n")
        self.readme("| Database | `a.sql` | PG >= 9.5 | A |")
        rc, out = self.run_check()
        self.assertEqual(rc, 0, out)

    def test_up_to_a_version_and_bad_cell(self):
        self.sql("a.sql", "\\ir variables.sql\n\\if :svp_under_pg_12\n  \\ir a_11-.sql\n\\else\n  \\qecho - Not supported\n\\endif\n")
        self.sql("b.sql", DISPATCHER.format(name="b"))
        self.readme("| Database | `a.sql` | PG < 12 | A |", "| Database | `b.sql` | 9.5+ | B |")
        rc, out = self.run_check()
        self.assertEqual(rc, 1, out)
        self.assertNotIn("`a.sql`", out)
        self.assertIn("`b.sql`: version cell '9.5+' isn't", out)

    def test_two_digit_versions(self):
        self.sql("a.sql", DISPATCHER.format(name="a").replace("svp_pg_95", "svp_pg_10").replace("_95up", "_10up"))
        self.readme("| Database | `a.sql` | PG >= 10 | A |")
        rc, out = self.run_check()
        self.assertEqual(rc, 0, out)

    def test_commented_out_branch_is_ignored(self):
        self.sql("a.sql", "/*\n\\if :svp_pg_82\n\\endif\n*/\n" + DISPATCHER.format(name="a"))
        self.readme("| Database | `a.sql` | PG >= 9.5 | A |")
        rc, out = self.run_check()
        self.assertEqual(rc, 0, out)

    def test_else_of_a_non_version_chain_does_not_count(self):
        self.sql("a.sql", DISPATCHER.format(name="a") +
                 "\\if :svp_psql_16\n  \\pset xheader_width full\n\\else\n  \\ir helper.sql\n\\endif\n")
        self.readme("| Database | `a.sql` | PG >= 9.5 | A |")
        rc, out = self.run_check()
        self.assertEqual(rc, 0, out)

    def test_fallback_include_inside_a_privilege_check(self):
        self.sql("a.sql", "\\ir variables.sql\n\\if :svp_pg_10\n  \\ir a_10up.sql\n\\else\n"
                          "  \\if :svp_rol_super\n    \\ir a_82up.sql\n  \\else\n    \\qecho - Needs superuser\n"
                          "  \\endif\n\\endif\n")
        self.readme("| Database | `a.sql` |  | A |")
        rc, out = self.run_check()
        self.assertEqual(rc, 0, out)

    def test_every_duplicate_row_is_checked(self):
        self.sql("a.sql", DISPATCHER.format(name="a"))
        self.readme("| Database | `a.sql` | PG >= 9.5 | A |", "| Cluster | `a.sql` | PG >= 8.4 | A again |")
        rc, out = self.run_check()
        self.assertEqual(rc, 1, out)
        self.assertIn("README.md:6: `a.sql` says PG >= 8.4", out)

    def test_utf8_readme_without_a_utf8_locale(self):
        self.sql("a.sql", DISPATCHER.format(name="a"))
        (self.repo / "README.md").write_text(
            "# \U0001F418 Catalog\n\n| S | N | V | D |\n|---|---|---|---|\n| Database | `a.sql` | PG >= 9.5 | A |\n",
            encoding="utf-8")
        env = dict(os.environ, LC_ALL="C", LANG="C", PYTHONUTF8="0", PYTHONCOERCECLOCALE="0")
        p = subprocess.run([sys.executable, "-X", "utf8=0", str(SCRIPT), str(self.repo)],
                           capture_output=True, text=True, env=env)
        self.assertEqual(p.returncode, 0, p.stdout + p.stderr)

    def test_not_the_repository(self):
        p = subprocess.run([sys.executable, str(SCRIPT), str(self.repo / "sql")], capture_output=True, text=True)
        self.assertEqual(p.returncode, 2)


if __name__ == "__main__":
    unittest.main()
