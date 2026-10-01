#!/usr/bin/env python3
"""Tests for tools/check_sql_style.py.

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
    "check_sql_style", Path(__file__).with_name("check_sql_style.py"))
ck = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(ck)


def of_kind(sql, kind):
    return [text for _, _, text, k, _ in ck.scan(sql)[0] if k == kind]


def found(sql):
    """Lowercase reserved keywords reported for sql."""
    return of_kind(sql, ck.KEYWORD)


def idents(sql):
    """Non-lowercase identifiers reported for sql."""
    return of_kind(sql, ck.IDENTIFIER)


def non_ascii(sql):
    """Non-ASCII identifiers and dollar-quote tags reported for sql."""
    return of_kind(sql, ck.NON_ASCII)


def specials(sql):
    """Non-uppercase PL/pgSQL special variables reported for sql."""
    return of_kind(sql, ck.SPECIAL)


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

    def test_non_ascii_identifiers_are_whole_words(self):
        self.assertEqual(found("SELECT selecté, éselect, ñandu_order, fromção FROM t"), [])
        self.assertEqual(found("SELECT açúcar from t"), ["from"])

    def test_non_reserved_keywords_are_ignored(self):
        self.assertEqual(found("SELECT 1 AS schema, 2 AS name, 3 AS begin"), [])


class Literals(unittest.TestCase):
    def test_strings_and_quoted_identifiers(self):
        self.assertEqual(found("""SELECT 'select from' AS a, E'where\\'s' AS b, "select" AS c"""), [])

    def test_doubled_quote_inside_string(self):
        self.assertEqual(found("SELECT 'can''t select' AS a"), [])

    def test_dollar_quotes_with_and_without_tags(self):
        self.assertEqual(found("SELECT $$order by$$, $body1$select from$body1$, $a_2$ where $a_2$"), [])

    def test_non_ascii_dollar_quote_tags(self):
        sql = "SELECT $café$select from$café$ AS x, $ñ$ where $ñ$ AS y"
        self.assertEqual(found(sql), [])
        self.assertEqual(ck.apply_fixes(sql, ck.scan(sql)[0]), sql)

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

    def test_even_backslashes_and_e_strings_are_not_ambiguous(self):
        # "ambiguous" is only about where the string ends; plain strings with
        # backslashes are still reported by the backslash rule
        for sql in ("SELECT '\\\\' AS a", "SELECT '\\s+' AS r", "SELECT E'can\\'t' AS e"):
            with self.subTest(sql=sql):
                findings, ambiguous_at = ck.scan(sql)
                self.assertIsNone(ambiguous_at)
                kinds = [k for _, _, _, k, _ in findings]
                self.assertEqual(kinds, [] if sql.startswith("SELECT E") else [ck.BACKSLASH])

    def test_scanning_stops_at_ambiguous_string(self):
        findings, at = ck.scan("select 1;\nSELECT 'can\\'t select from' AS a;\nselect 2")
        self.assertEqual([t for _, _, t, _, _ in findings], ["select"])
        self.assertEqual(ck.line_of("select 1;\nSELECT 'can", at), 2)


class Identifiers(unittest.TestCase):
    def test_non_lowercase_identifiers(self):
        self.assertEqual(idents("SELECT SUM(x), Round(y), t.Col, NOW() FROM Tbl"),
                         ["SUM", "Round", "Col", "NOW", "Tbl"])

    def test_lowercase_identifiers_pass(self):
        self.assertEqual(idents("SELECT sum(x), t.col, now() FROM pg_catalog.pg_class t"), [])

    def test_unreserved_and_column_name_keywords_are_free(self):
        sql = "SELECT COALESCE(a, b), nullif(a, b), x::TEXT, x::text, x::INTEGER, EXTRACT(YEAR FROM d)"
        self.assertEqual(idents(sql), [])
        self.assertEqual(found(sql), [])

    def test_role_options_and_privileges_are_free(self):
        sql = "CREATE ROLE r LOGIN; CREATE ROLE o NOLOGIN NOSUPERUSER; GRANT USAGE, CONNECT ON SCHEMA s TO r"
        self.assertEqual(idents(sql), [])
        self.assertEqual(idents("create role r login; grant usage on schema s to r"), [])

    def test_record_type_is_an_identifier(self):
        self.assertEqual(idents("DO $$ DECLARE v RECORD; BEGIN NULL; END $$;"), ["RECORD"])

    def test_extract_field_epoch_is_an_identifier(self):
        self.assertEqual(idents("SELECT EXTRACT(EPOCH FROM d), extract(epoch FROM d)"), ["EPOCH"])

    def test_casts_to_non_keyword_types(self):
        self.assertEqual(idents("SELECT x::REGCLASS, y::regclass, z :: OID"), ["REGCLASS", "OID"])

    def test_psql_variables_are_not_identifiers(self):
        self.assertEqual(idents("SELECT :DBNAME, :svp_pg_14, :'Foo', :\"Bar\""), [])

    def test_after_dot_is_always_an_identifier(self):
        self.assertEqual(idents("SELECT t.USER, s.Select, pg_catalog.COUNT(*) FROM t"),
                         ["USER", "Select", "COUNT"])

    def test_keyword_after_as_is_not_checked(self):
        sql = "CREATE VIEW v AS SELECT 1; SELECT CAST(x AS INTEGER), 1 AS ORDER, 2 AS Total"
        self.assertEqual(idents(sql), ["Total"])
        self.assertEqual(found(sql), [])

    def test_type_keyword_function_call_is_an_identifier(self):
        self.assertEqual(idents("SELECT LEFT(v, 1), Right (v, 2), CURRENT_SCHEMA()"),
                         ["LEFT", "Right", "CURRENT_SCHEMA"])
        self.assertEqual(idents("SELECT 1 FROM t LEFT JOIN u ON TRUE"), [])

    def test_identifiers_inside_literals_are_ignored(self):
        self.assertEqual(idents("SELECT to_char(d, 'Month MON mon') AS m, \"MixedCase\" -- COUNT\n"), [])


class NonAscii(unittest.TestCase):
    def test_non_ascii_identifier(self):
        self.assertEqual(non_ascii("SELECT café, selecté FROM tabelação"), ["café", "selecté", "tabelação"])
        self.assertEqual(found("SELECT selecté FROM t"), [])

    def test_non_ascii_dollar_quote_tag(self):
        self.assertEqual(non_ascii("SELECT $café$select$café$ AS x, $$ñ$$ AS y"), ["$café$"])

    def test_non_ascii_allowed_in_strings_quoted_identifiers_and_comments(self):
        self.assertEqual(non_ascii("SELECT ' ✅ OK' AS \"σ\", 1 -- tabelação\n/* é */"), [])

    def test_non_ascii_is_not_fixed(self):
        sql = "select café"
        self.assertEqual(ck.apply_fixes(sql, ck.scan(sql)[0]), "SELECT café")


class Bodies(unittest.TestCase):
    def test_do_block_is_plpgsql_code(self):
        sql = "DO $$ declare v int; begin if not found then raise notice 'x'; end if; end $$;"
        self.assertEqual(found(sql), ["declare", "begin", "if", "not", "then", "end", "if", "end"])
        self.assertEqual(specials(sql), ["found"])

    def test_do_block_with_language(self):
        self.assertEqual(found("DO LANGUAGE plpgsql $$ begin null; end $$;"), ["begin", "null", "end"])
        self.assertEqual(found("DO $x$ begin null; end $x$ LANGUAGE plpgsql;"), ["begin", "null", "end"])

    def test_function_body_language_before_or_after(self):
        before = "CREATE OR REPLACE FUNCTION f() RETURNS int LANGUAGE plpgsql AS $function$ begin return 1; end $function$;"
        after = "CREATE FUNCTION f() RETURNS int AS $$ begin return 1; end $$ LANGUAGE 'plpgsql';"
        for sql in (before, after):
            with self.subTest(sql=sql):
                self.assertEqual(found(sql), ["begin", "end"])

    def test_sql_function_and_procedure_bodies(self):
        self.assertEqual(found("CREATE FUNCTION f() RETURNS int LANGUAGE sql AS $$ select 1 $$;"), ["select"])
        self.assertEqual(idents("CREATE PROCEDURE p() LANGUAGE sql AS $$ SELECT COUNT(*) FROM t $$;"), ["COUNT"])

    def test_other_languages_stay_literals(self):
        self.assertEqual(found("CREATE FUNCTION f() RETURNS int LANGUAGE plpython3u AS $$ select from $$;"), [])

    def test_text_dollar_literals_stay_literals(self):
        self.assertEqual(found("SELECT $$select from$$ AS sql; SELECT $q$ begin $q$ AS b;"), [])

    def test_nested_dollar_literal_in_body_is_text(self):
        self.assertEqual(found("DO $$ BEGIN EXECUTE $q$ select from $q$; END $$;"), [])

    def test_plpgsql_unreserved_keywords_are_free(self):
        sql = "DO $$ BEGIN raise notice 'x'; PERFORM 1; GET DIAGNOSTICS n = row_count; EXCEPTION WHEN others THEN RETURN; END $$;"
        self.assertEqual(found(sql), [])
        self.assertEqual(idents(sql), [])

    def test_special_variables_uppercase(self):
        ok = "DO $$ BEGIN IF NOT FOUND THEN RAISE NOTICE '% %', SQLSTATE, SQLERRM; END IF; RETURN NEW; END $$;"
        self.assertEqual(specials(ok), [])
        self.assertEqual(specials("DO $$ BEGIN IF tg_op = 'x' THEN RETURN new; END IF; END $$;"), ["tg_op", "new"])

    def test_special_variable_record_fields_are_identifiers(self):
        sql = "DO $$ BEGIN NEW.Col := OLD.col; END $$;"
        self.assertEqual(specials(sql), [])
        self.assertEqual(idents(sql), ["Col"])

    def test_special_variables_only_in_plpgsql(self):
        self.assertEqual(specials("SELECT found FROM t"), [])

    def test_type_attributes(self):
        self.assertEqual(idents("DO $$ DECLARE r t%rowtype; c t.col%TYPE; BEGIN NULL; END $$;"), [])

    def test_no_psql_variables_inside_bodies(self):
        self.assertEqual(idents("DO $$ BEGIN x := a[1:N]; END $$;"), ["N"])
        self.assertEqual(idents("SELECT :DBNAME"), [])

    def test_no_psql_meta_lines_inside_bodies(self):
        self.assertEqual(found("DO $$\n\\qecho select\nBEGIN NULL; END $$;"), ["select"])

    def test_ambiguous_string_inside_body(self):
        self.assertIsNotNone(ck.scan("DO $$ BEGIN RAISE NOTICE 'can\\'t'; END $$;")[1])

    def test_fix_inside_body_keeps_positions(self):
        sql = "select 1;\nDO $$ declare v record; begin if not found then v := SUM(1); end if; end $$;\nselect 2"
        self.assertEqual(ck.apply_fixes(sql, ck.scan(sql)[0]),
                         "SELECT 1;\nDO $$ DECLARE v record; BEGIN IF NOT FOUND THEN v := sum(1); END IF; END $$;\nSELECT 2")

    def test_line_numbers_inside_body(self):
        sql = "DO $$\nBEGIN\n  select 1;\nEND $$;"
        (start, _, _, _, _), = ck.scan(sql)[0]
        self.assertEqual(ck.line_of(sql, start), 3)


class Review(unittest.TestCase):
    """Cases from the Copilot review of #60/#14/#1."""

    def test_psql_existence_test_variable(self):
        self.assertEqual(idents("SELECT :{?DBNAME}, :{?Foo}"), [])
        self.assertEqual(idents("SELECT a{?Foo}"), ["Foo"])  # no ':', so not a psql test

    def test_prefixed_literals(self):
        sql = "SELECT B'1010', b'01', X'CAFE', x'ff', U&'d\\0061t', U&\"Col\", N'abc'"
        self.assertEqual(idents(sql), [])
        self.assertEqual(found(sql), [])
        self.assertEqual(ck.apply_fixes(sql, ck.scan(sql)[0]), sql)

    def test_numeric_constants(self):
        sql = "SELECT 1E10, 2.5E-3, 1e+2, .5E1, 0X1F, 0o17, 0B101, 1_000_000"
        self.assertEqual(idents(sql), [])
        self.assertEqual(ck.apply_fixes(sql, ck.scan(sql)[0]), sql)

    def test_language_clause_outside_parentheses(self):
        sql = "CREATE FUNCTION f(language text, x text DEFAULT 'language') RETURNS int LANGUAGE plpgsql AS $$ begin return 1; end $$;"
        self.assertEqual(found(sql), ["begin", "end"])

    def test_last_language_clause_wins(self):
        sql = "CREATE FUNCTION f() RETURNS int LANGUAGE sql LANGUAGE plpython3u AS $$ select 1 $$;"
        self.assertEqual(found(sql), [])

    def test_pg18_keywords(self):
        sql = ("CREATE TABLE t (a int, b int GENERATED ALWAYS AS (a * 2) VIRTUAL, "
               "CONSTRAINT c CHECK (a > 0) NOT ENFORCED, "
               "FOREIGN KEY (a, PERIOD b) REFERENCES u (a, PERIOD b))")
        self.assertEqual(idents(sql), [])

    def test_qualified_language_is_not_the_language_clause(self):
        sql = ("CREATE FUNCTION f() RETURNS int LANGUAGE plpgsql SET app.language TO 'sql' "
               "AS $$ begin return 1; end $$;")
        self.assertEqual(found(sql), ["begin", "end"])

    def test_language_as_set_value_is_not_the_language_clause(self):
        for opt in ("SET search_path TO language", "SET search_path = language", "SET search_path TO a, language"):
            sql = f"CREATE FUNCTION f() RETURNS int LANGUAGE plpgsql {opt} AS $$ begin return 1; end $$;"
            with self.subTest(opt=opt):
                self.assertEqual(found(sql), ["begin", "end"])

    def test_reserved_word_after_as_is_syntax_unless_an_alias(self):
        self.assertEqual(found("CREATE VIEW v AS select a FROM t"), ["select"])
        self.assertEqual(found("CREATE TABLE t2 AS table t"), ["table"])
        self.assertEqual(found("SELECT 1 AS order, 2 AS desc FROM t"), [])
        self.assertEqual(found("SELECT (x AS order) , 1 AS end"), [])

    def test_language_followed_by_an_option_is_not_the_clause(self):
        for opt in ("SUPPORT language", "SET search_path TO language SECURITY DEFINER",
                    "SUPPORT language LANGUAGE plpgsql"):
            sql = f"CREATE FUNCTION f() RETURNS int LANGUAGE plpgsql {opt} AS $$ begin return 1; end $$;"
            with self.subTest(opt=opt):
                self.assertEqual(found(sql), ["begin", "end"])

    def test_unterminated_dollar_quotes_are_linear(self):
        # distinct unterminated tags used to rescan to the end each time
        code = ("import importlib.util, sys; "
                "spec = importlib.util.spec_from_file_location('ck', sys.argv[1]); "
                "ck = importlib.util.module_from_spec(spec); spec.loader.exec_module(ck); "
                "ck.scan('SELECT ' + ' '.join('$t%d$ x' % i for i in range(60000)))")
        try:
            subprocess.run([sys.executable, "-c", code, _spec.origin], check=True, timeout=5)
        except subprocess.TimeoutExpired:
            self.fail("scanning unterminated dollar quotes took more than 5s")

    def test_unterminated_dollar_quote_is_literal_to_the_end(self):
        self.assertEqual(found("select 1; SELECT $x$ select from"), ["select"])

    def test_symlinked_checker_checks_the_invoking_repository(self):
        root = Path(tempfile.mkdtemp())
        self.addCleanup(lambda: __import__("shutil").rmtree(root))
        (root / ".git").mkdir()
        (root / "tools").mkdir()
        (root / "tools" / "check_sql_style.py").symlink_to(Path(_spec.origin).resolve())
        (root / "x.sql").write_text("select 1;\n")
        r = subprocess.run([sys.executable, str(root / "tools" / "check_sql_style.py")],
                           capture_output=True, text=True, timeout=30)
        self.assertEqual(r.returncode, 1)
        self.assertIn("x.sql:1: keyword 'select'", r.stdout)

    def test_reserved_alias_before_any_clause(self):
        for tail in ("WHERE TRUE", "GROUP BY 1", "ORDER BY 1", "HAVING TRUE", "LIMIT 1", "OFFSET 1",
                     "UNION SELECT 1", "EXCEPT SELECT 1", "INTERSECT SELECT 1", "FETCH FIRST 1 ROW ONLY",
                     "FOR UPDATE", "INTO t2", "WINDOW w AS ()"):
            with self.subTest(tail=tail):
                self.assertEqual(found(f"SELECT 1 AS order {tail}"), [])
        self.assertEqual(found("INSERT INTO t VALUES (1) RETURNING id AS order"), [])

    def test_psql_variable_needs_an_adjacent_colon(self):
        self.assertEqual(idents("SELECT a[1: Upper], a[1:Upper] FROM t"), ["Upper"])
        self.assertEqual(idents("SELECT a[1: /* x */ Upper] FROM t"), ["Upper"])
        self.assertEqual(idents("SELECT :{? Foo}"), ["Foo"])
        self.assertEqual(idents("SELECT :DBNAME, :{?DBNAME}, x::REGCLASS"), ["REGCLASS"])

    def test_scan_is_linear_in_tokens(self):
        code = ("import importlib.util, sys; "
                "spec = importlib.util.spec_from_file_location('ck', sys.argv[1]); "
                "ck = importlib.util.module_from_spec(spec); spec.loader.exec_module(ck); "
                "ck.scan('SELECT ' + ', '.join('c%d' % i for i in range(100000)) + ' FROM t')")
        try:
            subprocess.run([sys.executable, "-c", code, _spec.origin], check=True, timeout=5)
        except subprocess.TimeoutExpired:
            self.fail("scanning 100k words took more than 5s")

    def test_psql_meta_line_ends_the_query(self):
        self.assertEqual(found("SELECT 1 AS order\n\\gset\nSELECT 2 AS desc\n\\g"), [])
        self.assertEqual(found("SELECT 1 AS order\n\\gset\nSELECT 2 FROM t\n"), [])

    def test_many_text_dollar_literals_are_linear(self):
        code = ("import importlib.util, sys; "
                "spec = importlib.util.spec_from_file_location('ck', sys.argv[1]); "
                "ck = importlib.util.module_from_spec(spec); spec.loader.exec_module(ck); "
                "ck.scan('SELECT ' + ', '.join('$$x$$' for i in range(20000)))")
        try:
            subprocess.run([sys.executable, "-c", code, _spec.origin], check=True, timeout=5)
        except subprocess.TimeoutExpired:
            self.fail("scanning 20000 dollar literals in one statement took more than 5s")

    def test_prefixed_language_names(self):
        for lang in ("E'plpgsql'", "U&'plpgsql'", "'plpgsql'", "plpgsql"):
            sql = f"CREATE FUNCTION f() RETURNS int LANGUAGE {lang} AS $$ begin return 1; end $$;"
            with self.subTest(lang=lang):
                self.assertEqual(found(sql), ["begin", "end"])

    def test_fix_messages_count_items(self):
        root = Path(tempfile.mkdtemp())
        self.addCleanup(lambda: __import__("shutil").rmtree(root))
        (root / "a.sql").write_text("select regexp_split_to_array(q, '\\s+');\n")
        out = io.StringIO()
        with contextlib.redirect_stdout(out):
            ck.main(["--fix", str(root)])
        self.assertIn("a.sql: fixed 2 item(s)", out.getvalue())
        self.assertIn("Fixed 2 item(s)", out.getvalue())

    def test_backslash_in_plain_string(self):
        sql = "SELECT regexp_split_to_array(q, '\\s+'), 'a\\\\b', E'\\\\s+', $$\\s+$$, U&'\\0061'"
        self.assertEqual(of_kind(sql, ck.BACKSLASH), ["'\\s+'", "'a\\\\b'"])
        self.assertEqual(ck.apply_fixes(sql, ck.scan(sql)[0]),
                         "SELECT regexp_split_to_array(q, E'\\\\s+'), E'a\\\\\\\\b', E'\\\\s+', $$\\s+$$, U&'\\0061'")

    def test_backslash_in_national_string_is_reported_without_fix(self):
        sql = "SELECT N'\\x'"
        self.assertEqual(of_kind(sql, ck.BACKSLASH), ["N'\\x'"])
        self.assertEqual(ck.apply_fixes(sql, ck.scan(sql)[0]), sql)

    def test_backslash_inside_function_body(self):
        sql = "DO $$ BEGIN PERFORM regexp_replace(x, '\\s', ''); END $$;"
        self.assertEqual(of_kind(sql, ck.BACKSLASH), ["'\\s'"])

    def test_phrase_keywords(self):
        sql = "CREATE TABLE t (id int PRIMARY key, x int, FOREIGN key (x) REFERENCES u); SELECT 1 ORDER by 1; SELECT 1 GROUP by 1"
        self.assertEqual(found(sql), ["key", "key", "by", "by"])
        self.assertEqual(found("SELECT x AS key, y AS by FROM t; SELECT key FROM t"), [])
        self.assertEqual(found("SELECT 1 OVER (PARTITION by x)"), [])


class Fix(unittest.TestCase):
    def test_fix_uppercases_keywords_and_lowercases_identifiers(self):
        sql = "select SUM(x), t.Col FROM Tbl WHERE EXTRACT(EPOCH FROM d) > 0"
        self.assertEqual(ck.apply_fixes(sql, ck.scan(sql)[0]),
                         "SELECT sum(x), t.col FROM tbl WHERE EXTRACT(epoch FROM d) > 0")

    def test_uppercase_only_touches_reported_words(self):
        sql = "select 'select' AS a, $$from$$ AS b -- where\nfrom t left join u ON true"
        new = ck.apply_fixes(sql, ck.scan(sql)[0])
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
        self.assertEqual(self.run_main(str(root)), (0, "All SQL style checks OK\n"))

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
        self.assertIn("backslash before one of its quotes is ambiguous", out)

    def test_reports_identifiers_and_non_ascii(self):
        root = self.repo({"sql/a.sql": "SELECT SUM(x) FROM t;\nSELECT café;\n"})
        code, out = self.run_main(str(root))
        self.assertEqual(code, 1)
        self.assertIn("sql/a.sql:1: identifier 'SUM' should be lowercase (sum)", out)
        self.assertIn("sql/a.sql:2: non-ASCII character in the unquoted identifier", out)

    def test_fix_leaves_non_ascii_and_exits_1(self):
        root = self.repo({"sql/a.sql": "select SUM(x), café;\n"})
        code, out = self.run_main("--fix", str(root))
        self.assertEqual(code, 1)
        self.assertEqual((root / "sql" / "a.sql").read_text(), "SELECT sum(x), café;\n")
        self.assertIn("non-ASCII", out)

    def test_no_sql_files(self):
        with tempfile.TemporaryDirectory() as tmp:
            with contextlib.redirect_stderr(io.StringIO()):
                self.assertEqual(ck.main([tmp]), 2)

    def generic_repo(self, files):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        for name, text in files.items():
            (root / name).parent.mkdir(parents=True, exist_ok=True)
            (root / name).write_text(text)
        return root

    def test_generic_repo_scans_every_sql_file(self):
        root = self.generic_repo({"a/x.sql": "select 1;\n", "b/c/y.sql": "SELECT SUM(1);\n",
                                  ".git/z.sql": "select 1;\n", "notes.txt": "select"})
        code, out = self.run_main(str(root))
        self.assertEqual(code, 1)
        self.assertIn("a/x.sql:1: keyword 'select'", out)
        self.assertIn("b/c/y.sql:1: identifier 'SUM'", out)
        self.assertNotIn(".git", out)

    def test_explicit_root_and_patterns(self):
        root = self.generic_repo({"a/x.sql": "select 1;\n", "b/y.sql": "SELECT 1;\n"})
        self.assertEqual(self.run_main("--root", str(root), "b/*.sql"), (0, "All SQL style checks OK\n"))
        self.assertEqual(self.run_main("--root", str(root), "a/x.sql")[0], 1)

    def test_pg_scripts_layout_only_checks_sql_and_reports(self):
        root = self.repo({"sql/a.sql": "SELECT 1;\n"})
        (root / "tools").mkdir()
        (root / "tools" / "t.sql").write_text("select 1;\n")
        self.assertEqual(self.run_main(str(root))[0], 0)


if __name__ == "__main__":
    unittest.main()
