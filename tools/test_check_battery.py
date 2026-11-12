#!/usr/bin/env python3
"""Tests for check_battery.py: each case builds fake run_battery.sh output.

Run from the repository root:
    python3 -m unittest discover -s tools -p 'test_*.py' -v

CHECK_BATTERY overrides the script under test (used to check that a mutated
copy makes these tests fail).
"""
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(os.environ.get("CHECK_BATTERY",
                             Path(__file__).absolute().parent / "check_battery.py"))
REPO_KNOWN = Path(__file__).absolute().parent / "known_failures.csv"
HEADER = "version,script,rc,lines,errors,fatal,timeout,not_supported,needs,md5\n"
KNOWN = '''# comment
script,versions,pattern,reason
needs_input,all,"syntax error at or near "":""",asks for input
old_syntax,82-84,"syntax error at or near ""WITH""",no CTE before 8.4
'''


class CheckBatteryTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.known = self.root / "known.csv"
        self.known.write_text(KNOWN)

    def tearDown(self):
        self.tmp.cleanup()

    def run_version(self, v, runs, ended=True):
        """runs: {script: (rc, output text, timeout)}; ended: write the END row"""
        d = self.root / "out" / v
        d.mkdir(parents=True)
        rows = []
        for s, (rc, text, to) in runs.items():
            (d / f"{s}.out").write_text(text)
            rows.append(f"{v},{s},{rc},{text.count(chr(10))},{text.count('ERROR:')},"
                        f"{text.count('FATAL:')},{int(to)},0,0,x\n")
        (d / "results.csv").write_text(HEADER + "".join(rows) + (f"{v},END,0,0,0,0,0,0,0,\n" if ended else ""))

    def check(self, *extra, known=None):
        p = subprocess.run([sys.executable, str(SCRIPT), "--known", str(known or self.known),
                            *extra, str(self.root / "out")], capture_output=True, text=True)
        return p.returncode, p.stdout + p.stderr

    def test_clean_run(self):
        self.run_version("16", {"a": (0, "ok\n", False)})
        rc, out = self.check()
        self.assertEqual(rc, 0, out)
        self.assertIn("0 new problem(s), 0 known", out)

    def test_known_failure_all_versions(self):
        self.run_version("16", {"needs_input": (0, 'psql:needs_input.sql:4: ERROR:  syntax error at or near ":"\n', False)})
        rc, out = self.check()
        self.assertEqual(rc, 0, out)
        self.assertIn("1 known", out)

    def test_new_error(self):
        self.run_version("16", {"a": (0, "psql:a_10up.sql:3: ERROR:  boom\n", False)})
        rc, out = self.check()
        self.assertEqual(rc, 1, out)
        self.assertIn("NEW a", out)
        self.assertIn("[16] ERROR:  boom", out)

    def test_known_script_with_a_second_error_is_new(self):
        self.run_version("16", {"needs_input": (0, 'ERROR:  syntax error at or near ":"\nERROR:  other\n', False)})
        rc, out = self.check()
        self.assertEqual(rc, 1, out)
        self.assertIn("ERROR:  other", out)

    def test_known_error_does_not_hide_a_failed_psql(self):
        self.run_version("16", {"needs_input": (2, 'ERROR:  syntax error at or near ":"\nserver closed the connection\n', False)})
        rc, out = self.check()
        self.assertEqual(rc, 1, out)
        self.assertIn("exit code 2", out)

    def test_psql_client_error(self):
        out = "psql:a.sql:3: error: a_10up.sql: No such file or directory\n"
        d = self.root / "out" / "16"
        d.mkdir(parents=True)
        (d / "a.out").write_text(out)
        # run_battery.sh counts it as an error; psql itself exits with 0
        (d / "results.csv").write_text(HEADER + "16,a,0,1,1,0,0,0,0,x\n16,END,0,0,0,0,0,0,0,\n")
        rc, out = self.check()
        self.assertEqual(rc, 1, out)
        self.assertIn("error: a_10up.sql: No such file", out)

    def test_known_only_on_listed_versions(self):
        self.run_version("84", {"old_syntax": (0, 'ERROR:  syntax error at or near "WITH"\n', False)})
        self.run_version("90", {"old_syntax": (0, 'ERROR:  syntax error at or near "WITH"\n', False)})
        rc, out = self.check()
        self.assertEqual(rc, 1, out)
        self.assertIn("[90]", out)
        self.assertNotIn("[84", out)

    def test_versions_grouped_in_version_order(self):
        for v in ("10", "96", "18"):
            self.run_version(v, {"a": (0, "ERROR:  boom\n", False)})
        rc, out = self.check()
        self.assertIn("[96,10,18] ERROR:  boom", out)

    def test_timeout_and_exit_code_without_error_line(self):
        self.run_version("16", {"slow": (124, "", True), "crash": (2, "server closed the connection\n", False)})
        rc, out = self.check()
        self.assertEqual(rc, 1, out)
        self.assertIn("TIMEOUT", out)
        self.assertIn("exit code 2: server closed the connection", out)

    def test_reports_failure(self):
        d = self.root / "out" / "16"
        (d / "reports" / "pg16").mkdir(parents=True)
        (d / "reports" / "pg16" / "db.md").write_text("ERROR:  in a report\n")
        (d / "reports.log").write_text("ok\n")
        (d / "results.csv").write_text(HEADER + "16,REPORTS,0,1,1,0,0,0,0,1\n16,END,0,0,0,0,0,0,0,\n")
        rc, out = self.check()
        self.assertEqual(rc, 1, out)
        self.assertIn("NEW REPORTS", out)
        self.assertIn("in a report", out)

    def test_stale_entry_is_a_note_unless_strict(self):
        self.run_version("16", {"needs_input": (0, "fine now\n", False)})
        rc, out = self.check()
        self.assertEqual(rc, 0, out)
        self.assertIn("note: known failure not seen any more: needs_input", out)
        rc, out = self.check("--strict")
        self.assertEqual(rc, 1, out)
        # an entry for versions that weren't run is not stale
        self.assertNotIn("old_syntax", out)

    def test_entry_for_a_script_not_run_is_not_stale(self):
        self.run_version("16", {"a": (0, "ok\n", False)})
        rc, out = self.check("--strict")
        self.assertEqual(rc, 0, out)
        self.assertNotIn("not seen any more", out)

    def test_bad_known_file(self):
        self.run_version("16", {"a": (0, "ok\n", False)})
        bad = self.root / "bad.csv"
        bad.write_text("script,versions,pattern,reason\nx,82-99,y,z\n")
        rc, out = self.check(known=bad)
        self.assertEqual(rc, 2, out)
        self.assertIn("82-99", out)

    def test_results_without_runs_fail(self):
        d = self.root / "out" / "16"
        d.mkdir(parents=True)
        (d / "results.csv").write_text(HEADER)
        rc, out = self.check()
        self.assertEqual(rc, 1, out)
        self.assertIn("no runs recorded", out)

    def test_interrupted_run_fails(self):
        self.run_version("16", {"a": (0, "ok\n", False)}, ended=False)
        rc, out = self.check()
        self.assertEqual(rc, 1, out)
        self.assertIn("run interrupted: no END row", out)
        self.assertIn("[16] run interrupted", out)

    def test_end_row_is_not_a_run(self):
        self.run_version("16", {"a": (0, "ok\n", False)})
        rc, out = self.check()
        self.assertEqual(rc, 0, out)
        self.assertIn("1 runs on 1 version(s)", out)

    def test_fixture_load_failure(self):
        d = self.root / "out" / "16"
        d.mkdir(parents=True)
        (d / "fixture.log").write_text("fixture pg16: load had errors\nERROR:  relation \"bloat_upd\" does not exist\n")
        (d / "results.csv").write_text(HEADER + "16,a,0,1,0,0,0,0,0,x\n16,FIXTURE_LOAD,1,0,1,0,0,0,0,\n16,END,0,0,0,0,0,0,0,\n")
        (d / "a.out").write_text("ok\n")
        rc, out = self.check()
        self.assertEqual(rc, 1, out)
        self.assertIn("NEW FIXTURE_LOAD", out)
        self.assertIn("load had errors", out)

    def test_expected_version_missing(self):
        self.run_version("82", {"a": (0, "ok\n", False)})
        self.run_version("18", {"a": (0, "ok\n", False)})
        rc, out = self.check("--versions", "82 83 18")
        self.assertEqual(rc, 1, out)
        self.assertIn("NEW (missing)", out)
        self.assertIn("[83] no results for this version", out)
        rc, out = self.check("--versions", "82 18")
        self.assertEqual(rc, 0, out)

    def test_expected_versions_range_and_all(self):
        self.run_version("10", {"a": (0, "ok\n", False)})
        rc, out = self.check("--versions", "96-10")
        self.assertEqual(rc, 1, out)
        self.assertIn("[96] no results", out)
        rc, out = self.check("--versions", "all")
        self.assertIn("[82,83,84,90,91,92,93,94,95,96,11,12,13,14,15,16,17,18] no results", out)
        rc, out = self.check("--versions", "10-99")
        self.assertEqual(rc, 2, out)

    def test_path_that_does_not_exist(self):
        self.run_version("16", {"a": (0, "ok\n", False)})
        p = subprocess.run([sys.executable, str(SCRIPT), "--known", str(self.known),
                            str(self.root / "out" / "16"), str(self.root / "out" / "83")],
                           capture_output=True, text=True)
        self.assertEqual(p.returncode, 2, p.stdout + p.stderr)
        self.assertIn("does not exist", p.stderr)

    ALIGNED = (" name | size | note \n"
               "------+------+------\n"
               " a    | 1 kB |      \n"
               " b    | 2 kB |      \n"
               "(2 rows)\n")

    def test_empty_column_aligned(self):
        self.run_version("16", {"t": (0, self.ALIGNED, False)})
        rc, out = self.check()
        self.assertEqual(rc, 1, out)
        self.assertIn('[16] empty column "note" (all 2 rows)', out)
        self.assertNotIn('"size"', out)

    def test_empty_column_expanded(self):
        text = ("-[ RECORD 1 ]-----\nname | a\nnote | \n"
                "-[ RECORD 2 ]-----\nname | b\nnote | -\n")
        self.run_version("16", {"t": (0, text, False)})
        rc, out = self.check()
        self.assertEqual(rc, 1, out)
        self.assertIn('empty column "note" (all 2 rows)', out)

    def test_wide_characters_are_cut_by_display_width(self):
        text = (" name | note | n \n"
                "------+------+---\n"
                " \u6f22   |      | 1\n"
                " \u5b57   |      | 2\n"
                "(2 rows)\n")
        self.run_version("16", {"t": (0, text, False)})
        rc, out = self.check()
        self.assertEqual(rc, 1, out)
        self.assertIn('empty column "note" (all 2 rows)', out)
        self.assertNotIn('"n"', out)

    def test_multiline_value_is_one_row(self):
        # psql marks a value that goes on with "+" in the cell's last column
        text = (" name | note | n \n"
                "------+------+---\n"
                " ab  +|      | 1\n"
                " cd   |      | \n"
                "(1 row)\n")
        self.run_version("16", {"t": (0, text, False)})
        rc, out = self.check()
        self.assertEqual(rc, 0, out)  # one row: below the 2-row threshold
        text2 = (" n | last \n---+------\n 1 | ab  +\n   | cd\n 2 | \n(2 rows)\n")
        self.run_version("17", {"t": (0, text2, False)})
        rc, out = self.check()
        self.assertNotIn('"last"', out)  # filled in the first row's second line

    def test_one_column_null_rows_before_a_footer(self):
        text = " only \n------\n \n \n(2 rows)\n"
        self.run_version("16", {"t": (0, text, False)})
        rc, out = self.check()
        self.assertEqual(rc, 1, out)
        self.assertIn('empty column "only" (all 2 rows)', out)

    def test_consecutive_tables_without_a_blank_line(self):
        # footers off: the second table follows the first one right away
        text = (" a | b \n---+---\n 1 | x\n 2 | y\n"
                " name | note \n------+------\n a    |      \n b    |      \n")
        self.run_version("16", {"t": (0, text, False)})
        rc, out = self.check()
        self.assertEqual(rc, 1, out)
        self.assertIn('empty column "note" (all 2 rows)', out)

    def test_aligned_table_right_after_expanded_records(self):
        text = ("-[ RECORD 1 ]---\nname | a\nsize | 1\n"
                "-[ RECORD 2 ]---\nname | b\nsize | 2\n"
                " key | note \n-----+------\n x   |      \n y   |      \n")
        self.run_version("16", {"t": (0, text, False)})
        rc, out = self.check()
        self.assertEqual(rc, 1, out)
        self.assertIn('empty column "note" (all 2 rows)', out)

    def test_needs_as_superuser(self):
        text = "- Needs superuser (or EXECUTE on pg_ls_dir())\n"
        d = self.root / "out" / "16"
        d.mkdir(parents=True)
        (d / "t.out").write_text(text)
        (d / "t@low.out").write_text(text)
        (d / "results.csv").write_text(HEADER + "16,t,0,1,0,0,0,0,1,x\n16,t@low,0,1,0,0,0,0,1,x\n16,END,0,0,0,0,0,0,0,\n")
        rc, out = self.check()
        self.assertEqual(rc, 1, out)
        self.assertIn("NEW t\n", out)
        self.assertIn("as superuser: - Needs superuser", out)
        self.assertNotIn("t@low", out)  # expected without privileges

    def test_lowpriv_role_with_translated_messages(self):
        d = self.root / "out" / "16"
        d.mkdir(parents=True)
        (d / "LOWPRIV.out").write_text("ERROR:  role r has lc_messages=fr_FR: set ALTER ROLE r SET lc_messages TO 'C'\n")
        (d / "results.csv").write_text(HEADER + "16,LOWPRIV,1,1,1,0,0,0,0,\n16,END,0,0,0,0,0,0,0,\n")
        rc, out = self.check()
        self.assertEqual(rc, 1, out)
        self.assertIn("NEW LOWPRIV", out)
        self.assertIn("lc_messages=fr_FR", out)

    def test_one_row_table_and_filled_columns_pass(self):
        self.run_version("16", {"t": (0, " name | note \n------+------\n a    |      \n(1 row)\n", False),
                                "u": (0, " name | n \n------+---\n a    | 1 \n b    | 2 \n", False)})
        rc, out = self.check()
        self.assertEqual(rc, 0, out)

    def test_known_error_and_known_empty_column_from_two_entries(self):
        known = self.root / "k2.csv"
        known.write_text('script,versions,pattern,reason\n'
                         't,all,"empty column ""note""",no notes in the fixture\n'
                         't,all,boom,environment\n')
        self.run_version("16", {"t": (0, "ERROR:  boom\n" + self.ALIGNED, False)})
        rc, out = self.check(known=known)
        self.assertEqual(rc, 0, out)
        self.assertIn("1 known", out)

    def test_entry_covers_the_unprivileged_pass(self):
        known = self.root / "k3.csv"
        known.write_text('script,versions,pattern,reason\n'
                         't,all,boom,environment\n'
                         'u@low,all,hidden,no privilege\n')
        self.run_version("16", {"t": (0, "ERROR:  boom\n", False), "t@low": (0, "ERROR:  boom\n", False),
                                "u": (0, "ERROR:  hidden\n", False), "u@low": (0, "ERROR:  hidden\n", False)})
        rc, out = self.check(known=known)
        self.assertEqual(rc, 1, out)
        self.assertIn("NEW u\n", out)       # u@low's entry doesn't cover u
        self.assertNotIn("NEW t", out)       # t's entry covers t and t@low
        self.assertNotIn("NEW u@low", out)

    def test_no_results(self):
        (self.root / "out").mkdir()
        rc, out = self.check()
        self.assertEqual(rc, 2, out)

    def test_repository_known_failures_file_is_valid(self):
        self.run_version("16", {"a": (0, "ok\n", False)})
        rc, out = self.check(known=REPO_KNOWN)
        self.assertEqual(rc, 0, out)


if __name__ == "__main__":
    unittest.main()
