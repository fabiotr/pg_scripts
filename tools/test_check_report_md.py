#!/usr/bin/env python3
"""Tests for check_report_md.py: each case is a small Markdown report.

Run from the repository root:
    python3 -m unittest discover -s tools -p 'test_*.py' -v

CHECK_REPORT_MD overrides the script under test (used to check that a
mutated copy makes these tests fail).
"""
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(os.environ.get("CHECK_REPORT_MD",
                             Path(__file__).absolute().parent / "check_report_md.py"))

GOOD = """# Report

## Section

| Name | Size |
|---|---|
| a \\| b | 10 kB |
| c | |

- Not supported on version 8.2.23

| Info | Value
|---|---|
 BINDIR | /usr/bin
 EMPTY  |

```sql
SELECT 1;
(1 row)
Time: 0.1 ms
```
"""


class CheckReportMdTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.dir = Path(self.tmp.name)

    def tearDown(self):
        self.tmp.cleanup()

    def check(self, text, name="r.md"):
        f = self.dir / name
        f.write_text(text)
        p = subprocess.run([sys.executable, str(SCRIPT), str(f)], capture_output=True, text=True)
        return p.returncode, p.stdout + p.stderr

    def test_good_report(self):
        rc, out = self.check(GOOD)
        self.assertEqual(rc, 0, out)
        self.assertEqual(out, "")

    def test_footer(self):
        rc, out = self.check("| a |\n|---|\n| 1 |\n\n(1 row)\n\n| b |\n|---|\n\n(12 rows)\n")
        self.assertEqual(rc, 1, out)
        self.assertIn("r.md:5: psql row-count footer '(1 row)'", out)
        self.assertIn("r.md:10: psql row-count footer '(12 rows)'", out)

    def test_psql_feedback(self):
        rc, out = self.check("Timing is on.\n| a |\n|---|\n| 1 |\n\nTime: 0.339 ms\nExpanded display is used automatically.\n")
        self.assertEqual(rc, 1, out)
        self.assertEqual(out.count("psql feedback"), 3, out)
        self.assertTrue(out.startswith("ERROR: "), out)

    def test_row_with_more_cells_than_header(self):
        rc, out = self.check("| a | b |\n|---|---|\n| 1 | 2 | 3 |\n")
        self.assertEqual(rc, 1, out)
        self.assertIn("r.md:3: table row has 3 columns, its header (line 1) 2", out)

    def test_short_row_with_leading_pipe(self):
        rc, out = self.check("| a | b |\n|---|---|\n| 1 |\n")
        self.assertEqual(rc, 1, out)
        self.assertIn("table row has 1 columns", out)

    def test_escaped_pipes_and_backslashes(self):
        rc, out = self.check("| a | b |\n|---|---|\n| x \\| y | C:\\\\ |\n")
        self.assertEqual(rc, 0, out)

    def test_header_without_separator(self):
        rc, out = self.check("| a | b |\n| 1 | 2 |\n")
        self.assertEqual(rc, 1, out)
        self.assertIn("not followed by a |---| separator", out)

    def test_header_followed_by_blank_heading_or_eof(self):
        for text in ("| a | b |\n\nmore\n", "| a | b |\n## Next\n", "text\n\n| a | b |\n", "| a | b |"):
            rc, out = self.check(text)
            self.assertEqual(rc, 1, (text, out))
            self.assertIn("not followed by a |---| separator", out)

    def test_unicode_line_separator_inside_a_cell(self):
        rc, out = self.check("| a | b |\n|---|---|\n| alpha\u2028beta | 1 kB |\n| x\u2029y | 2 kB |\n")
        self.assertEqual(rc, 0, out)

    def test_separator_width(self):
        rc, out = self.check("| a | b |\n|---|\n| 1 | 2 |\n")
        self.assertEqual(rc, 1, out)
        self.assertIn("separator has 1 columns", out)

    def test_unclosed_code_block(self):
        rc, out = self.check("text\n```sql\nSELECT 1;\n")
        self.assertEqual(rc, 1, out)
        self.assertIn("r.md:2: code block (```) never closed", out)

    def test_fence_closes_only_on_a_bare_run_as_long(self):
        # two opening fences with an info string, never closed
        rc, out = self.check("```sql\nSELECT 1;\n```sql\nSELECT 2;\n")
        self.assertEqual(rc, 1, out)
        self.assertIn("r.md:1: code block (```) never closed", out)
        # a four-backtick block holding a three-backtick line is closed
        rc, out = self.check("````\n```sql\nSELECT 1;\n```\n````\n\n| a |\n|---|\n")
        self.assertEqual(rc, 0, out)
        # a longer closing run closes it too
        rc, out = self.check("```\nx\n`````\n")
        self.assertEqual(rc, 0, out)

    def test_several_files_and_missing_file(self):
        (self.dir / "ok.md").write_text(GOOD)
        p = subprocess.run([sys.executable, str(SCRIPT), str(self.dir / "ok.md"), str(self.dir / "nope.md")],
                           capture_output=True, text=True)
        self.assertEqual(p.returncode, 2, p.stdout + p.stderr)


if __name__ == "__main__":
    unittest.main()
