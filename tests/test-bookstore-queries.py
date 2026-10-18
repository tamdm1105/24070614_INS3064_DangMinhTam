import os
import re
import subprocess
import unittest

CONTAINER = "ins3064-homework04-mysql-261005"  # same disposable container as test-bookstore-db.py
ROOT = os.path.join(os.path.dirname(__file__), "..")
SCHEMA_FILE = os.path.join(ROOT, "bookstore_db.sql")
QUERIES_FILE = os.path.join(ROOT, "bookstore_queries.sql")
EXPECTED_BLOCK = re.compile(r"/\* Expected output[^\n]*\n(.*?)\n\*/", re.S)


def mysql(sql, *flags):
    result = subprocess.run(["docker", "exec", "-i", CONTAINER, "mysql", "-uroot", "--default-character-set=utf8mb4", *flags],
                            input=sql, text=True, capture_output=True)
    if result.returncode:
        raise AssertionError(result.stderr.strip())
    return result.stdout


class BookstoreQueriesTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        with open(SCHEMA_FILE, encoding="utf-8") as f:
            mysql(f.read())
        with open(QUERIES_FILE, encoding="utf-8") as f:
            cls.text = f.read()

    def test_whole_file_runs_twice(self):
        mysql(self.text)
        mysql(self.text)  # CREATE OR REPLACE VIEW keeps it re-runnable

    def test_ten_numbered_queries_with_description_and_expected_output(self):
        self.assertEqual(re.findall(r"^-- Query (\d+):", self.text, re.M), [str(n) for n in range(1, 11)])
        self.assertEqual(self.text.count("-- Description:"), 10)
        self.assertEqual(len(EXPECTED_BLOCK.findall(self.text)), 10)
        for field in ("Name:", "Student ID:", "Assignment:", "Date:"):
            self.assertIn(field, self.text.split("USE bookstore_db;")[0])

    def test_style_rules(self):
        code = re.sub(r"/\*.*?\*/|--[^\n]*", "", self.text, flags=re.S)
        self.assertNotRegex(code, r"(?i)select\s+\*")
        self.assertNotRegex(code, r"(?i)\bfrom\s+\w+(\s+as\s+\w+)?\s*,\s*\w+")  # no comma joins
        self.assertIn("CREATE OR REPLACE VIEW v_book_sales_summary", code)

    def test_each_query_returns_its_documented_output(self):
        if mysql("SELECT YEAR(CURDATE());", "-N").strip() != "2026":
            self.skipTest("expected output of Query 10 was recorded in 2026")
        segments = EXPECTED_BLOCK.split(self.text)
        for number in range(10):
            sql, expected = segments[number * 2].split("USE bookstore_db;")[-1], segments[number * 2 + 1]
            with self.subTest(query=number + 1):
                self.assertEqual(mysql("USE bookstore_db;\n" + sql, "-t").strip(), expected.strip())


if __name__ == "__main__":
    unittest.main()
