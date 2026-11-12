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

    def run_version(self, v, runs):
        """runs: {script: (rc, output text, timeout)}"""
        d = self.root / "out" / v
        d.mkdir(parents=True)
        rows = []
        for s, (rc, text, to) in runs.items():
            (d / f"{s}.out").write_text(text)
            rows.append(f"{v},{s},{rc},{text.count(chr(10))},{text.count('ERROR:')},"
                        f"{text.count('FATAL:')},{int(to)},0,0,x\n")
        (d / "results.csv").write_text(HEADER + "".join(rows))

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
        (d / "results.csv").write_text(HEADER + "16,REPORTS,0,1,1,0,0,0,0,1\n")
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
