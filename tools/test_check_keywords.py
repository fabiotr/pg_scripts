#!/usr/bin/env python3
"""Tests for tools/check_keywords.py.

Run: python3 -m unittest discover -s tools -p 'test_*.py'
"""

import contextlib
import importlib.util
import io
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "check_keywords", Path(__file__).with_name("check_keywords.py"))
ck = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(ck)


def found(sql):
    """Lowercase keywords reported for sql, as a list of words."""
    return [word for _, _, word in ck.scan(sql)[0]]


class Keywords(unittest.TestCase):
    def test_reports_lowercase_reserved_words(self):
        self.assertEqual(found("select a from t where x is not null and y = true"),
                         ["select", "from", "where", "is", "not", "null", "and", "true"])

    def test_uppercase_and_mixed_case(self):
        self.assertEqual(found("SELECT 1"), [])
        self.assertEqual(found("Select 1"), ["Select"])

    def test_function_like_reserved_words(self):
        self.assertEqual(found("SELECT current_timestamp, current_date, system_user"),
                         ["current_timestamp", "current_date", "system_user"])

    def test_real_functions_stay_lowercase(self):
        self.assertEqual(found("SELECT now(), count(*), current_schema()"), [])

    def test_non_reserved_keywords_are_ignored(self):
        self.assertEqual(found("SELECT 1 AS schema, 2 AS name, 3 AS begin"), [])


class Literals(unittest.TestCase):
    def test_strings_and_quoted_identifiers(self):
        self.assertEqual(found("""SELECT 'select from' AS a, E'where\\'s' AS b, "select" AS c"""), [])

    def test_doubled_quote_inside_string(self):
        self.assertEqual(found("SELECT 'can''t select' AS a"), [])

    def test_dollar_quotes_with_and_without_tags(self):
        self.assertEqual(found("SELECT $$order by$$, $body1$select from$body1$, $a_2$ where $a_2$"), [])

    def test_positional_parameters_are_not_dollar_quotes(self):
        self.assertEqual(found("SELECT x FROM t WHERE id = $1 and y = $2"), ["and"])

    def test_psql_meta_command_lines(self):
        self.assertEqual(found("\\if :svp_pg_14\n\\qecho select from where\nSELECT 1\n\\endif"), [])

    def test_backslash_in_middle_of_line_is_not_meta(self):
        self.assertEqual(found("SELECT 1 \\gset\nselect 2"), ["select"])


    def test_unterminated_e_string_is_linear(self):
        # py/redos: overlapping alternatives made this exponential. A regex
        # can't be interrupted, so run it in a subprocess with a timeout.
        code = ("import importlib.util, sys; "
                "spec = importlib.util.spec_from_file_location('ck', sys.argv[1]); "
                "ck = importlib.util.module_from_spec(spec); spec.loader.exec_module(ck); "
                "ck.tokens(\"SELECT E'\" + '\\\\&' * 5000)")
        try:
            subprocess.run([sys.executable, "-c", code, _spec.origin], check=True, timeout=5)
        except subprocess.TimeoutExpired:
            self.fail("tokenizing an unterminated E'...' string took more than 5s (ReDoS)")


class Comments(unittest.TestCase):
    def test_line_and_block_comments(self):
        self.assertEqual(found("-- select\nSELECT 1 /* from where */"), [])

    def test_nested_block_comment(self):
        self.assertEqual(found("/* outer /* inner */ select still a comment */ SELECT 1"), [])

    def test_unterminated_block_comment_runs_to_end(self):
        self.assertEqual(found("SELECT 1 /* select"), [])


class Context(unittest.TestCase):
    def test_after_dot_as_and_colon(self):
        self.assertEqual(found("SELECT t.user, 1 AS order, :select FROM t"), [])

    def test_comment_between_as_or_dot_and_word(self):
        self.assertEqual(found("SELECT 1 AS /* note */ user, s./* note */select FROM t"), [])

    def test_type_keyword_as_function_call(self):
        self.assertEqual(found("SELECT left(v, 1), right (v, 2) FROM t"), [])

    def test_type_keyword_function_call_with_comment(self):
        self.assertEqual(found("SELECT left /* note */ (v, 1), right -- note\n(v, 2) FROM t"), [])

    def test_type_keyword_not_a_call(self):
        self.assertEqual(found("SELECT 1 FROM t left join u ON true"), ["left", "join", "true"])

    def test_reserved_word_before_paren_is_still_reported(self):
        self.assertEqual(found("SELECT 1 WHERE x in (1, 2)"), ["in"])

    def test_type_keyword_syntax_before_paren_is_reported(self):
        self.assertEqual(found("SELECT * FROM t join (SELECT 1) s ON TRUE"), ["join"])
        self.assertEqual(found("SELECT 1 WHERE v like ('x') OR v ilike ('y')"), ["like", "ilike"])
        self.assertEqual(found("SELECT (a, b) overlaps (c, d)"), ["overlaps"])

    def test_function_names_among_type_keywords(self):
        self.assertEqual(found("SELECT current_schema(), left(v, 1), right(v, 1)"), [])
        self.assertEqual(found("SELECT current_schema"), ["current_schema"])


class Ambiguous(unittest.TestCase):
    def test_backslash_quote_is_ambiguous(self):
        self.assertIsNotNone(ck.scan("SELECT 'can\\'t select' AS a")[1])
        self.assertIsNotNone(ck.scan("SELECT 'C:\\' AS path")[1])

    def test_escaped_quote_at_doubled_quote_is_ambiguous(self):
        # standard_conforming_strings on: 'a\' + '' + closing quote;
        # off: \' is an escaped quote, so the string ends elsewhere
        self.assertIsNotNone(ck.scan("SELECT 'a\\''' AS x")[1])
        self.assertIsNotNone(ck.scan("SELECT 'x\\''y' AS x")[1])

    def test_doubled_quotes_without_backslash_are_not_ambiguous(self):
        self.assertIsNone(ck.scan("SELECT 'can''t' AS a, '''' AS q, 'a\\\\''b' AS e")[1])

    def test_even_backslashes_and_e_strings_are_not(self):
        for sql in ("SELECT '\\\\' AS a", "SELECT '\\s+' AS r", "SELECT E'can\\'t' AS e"):
            with self.subTest(sql=sql):
                self.assertIsNone(ck.scan(sql)[1])

    def test_scanning_stops_at_ambiguous_string(self):
        keywords, at = ck.scan("select 1;\nSELECT 'can\\'t select from' AS a;\nselect 2")
        self.assertEqual([w for _, _, w in keywords], ["select"])
        self.assertEqual(ck.line_of("select 1;\nSELECT 'can", at), 2)


class Fix(unittest.TestCase):
    def test_uppercase_only_touches_reported_words(self):
        sql = "select 'select' AS a, $$from$$ AS b -- where\nfrom t left join u ON true"
        new = ck.uppercase(sql, ck.scan(sql)[0])
        self.assertEqual(new, "SELECT 'select' AS a, $$from$$ AS b -- where\nFROM t LEFT JOIN u ON TRUE")
        self.assertEqual(found(new), [])


class Main(unittest.TestCase):
    def repo(self, files):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        (root / "sql").mkdir()
        (root / "reports").mkdir()
        (root / "sql" / "variables.sql").write_text("SELECT 1;\n")
        for name, text in files.items():
            (root / name).write_text(text)
        return root

    def run_main(self, *args):
        out = io.StringIO()
        with contextlib.redirect_stdout(out):
            code = ck.main(list(args))
        return code, out.getvalue()

    def test_clean_repo(self):
        root = self.repo({"sql/a.sql": "SELECT 1;\n"})
        self.assertEqual(self.run_main(str(root)), (0, "All keywords OK\n"))

    def test_reports_file_and_line(self):
        root = self.repo({"sql/a.sql": "SELECT 1;\nselect 2;\n"})
        code, out = self.run_main(str(root))
        self.assertEqual(code, 1)
        self.assertIn("sql/a.sql:2: keyword 'select' should be uppercase (SELECT)", out)

    def test_fix_rewrites_and_then_passes(self):
        root = self.repo({"reports/r.sql": "select 1 from t;\n"})
        self.assertEqual(self.run_main("--fix", str(root))[0], 0)
        self.assertEqual((root / "reports" / "r.sql").read_text(), "SELECT 1 FROM t;\n")
        self.assertEqual(self.run_main(str(root))[0], 0)

    def test_fix_leaves_ambiguous_file_untouched(self):
        text = "select 'can\\'t' AS a;\n"
        root = self.repo({"sql/a.sql": text, "sql/b.sql": "select 1;\n"})
        code, out = self.run_main("--fix", str(root))
        self.assertEqual(code, 1)
        self.assertEqual((root / "sql" / "a.sql").read_text(), text)
        self.assertEqual((root / "sql" / "b.sql").read_text(), "SELECT 1;\n")
        self.assertIn("ambiguous", out)

    def test_not_a_pg_scripts_repo(self):
        with tempfile.TemporaryDirectory() as tmp:
            with contextlib.redirect_stderr(io.StringIO()):
                self.assertEqual(ck.main([tmp]), 2)


if __name__ == "__main__":
    unittest.main()
