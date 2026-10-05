import os
import subprocess
import unittest

CONTAINER = "ins3064-homework04-mysql-261005"  # fixed name: tests only ever touch this disposable container
DATABASE = "university_db"
SQL_FILE = os.path.join(os.path.dirname(__file__), "..", "university_db.sql")


def mysql(sql, *, database=DATABASE, check=True):
    command = ["docker", "exec", "-i", CONTAINER, "mysql", "-uroot", "--batch", "--raw", "--skip-column-names", "--default-character-set=utf8mb4"]
    if database:
        command += [database]
    result = subprocess.run(command, input=sql, text=True, capture_output=True)
    if check and result.returncode:
        raise AssertionError(result.stderr.strip())
    return result


def query(sql):
    return mysql(sql).stdout.rstrip("\n").splitlines()


class UniversityDatabaseTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if not os.path.isfile(SQL_FILE):
            raise RuntimeError(f"SQL file not found: {SQL_FILE}")
        # This test suite is intentionally restricted to the disposable named container.
        actual = subprocess.run(
            ["docker", "inspect", "--format", "{{.Name}} {{.HostConfig.NetworkMode}} {{json .NetworkSettings.Ports}}", CONTAINER],
            text=True, capture_output=True, check=True,
        ).stdout.strip()
        if actual != f"/{CONTAINER} none {{}}":
            raise RuntimeError(f"Refusing non-isolated MySQL container: {actual}")
        subprocess.run(
            ["docker", "exec", "-i", CONTAINER, "mysql", "-uroot"],
            input=f"CREATE DATABASE IF NOT EXISTS {DATABASE};\n", text=True, check=True,
        )
        cls.import_sql()

    @classmethod
    def import_sql(cls):
        with open(SQL_FILE, encoding="utf-8") as sql_file:
            result = subprocess.run(
                ["docker", "exec", "-i", CONTAINER, "mysql", "-uroot", DATABASE],
                stdin=sql_file, text=True, capture_output=True,
            )
        if result.returncode:
            raise AssertionError(result.stderr.strip())

    def test_expected_tables_exist(self):
        tables = set(query(
            "SELECT table_name FROM information_schema.tables "
            f"WHERE table_schema = '{DATABASE}' AND table_type = 'BASE TABLE'"
        ))
        self.assertEqual(tables, {"departments", "instructors", "students", "courses", "semesters", "enrollments"})

    def test_seed_counts_and_utf8_names(self):
        minimum = {"departments": 5, "instructors": 5, "students": 5, "courses": 5, "semesters": 5, "enrollments": 10}
        for table, count in minimum.items():
            with self.subTest(table=table):
                self.assertGreaterEqual(int(query(f"SELECT COUNT(*) FROM {table}")[0]), count)
        # Imported without any client charset flag: names must still round-trip exactly.
        self.assertEqual(query("SELECT student_name FROM students WHERE student_code = '25000001'"), ["Nguyễn Thị Hương"])

    def test_columns_constraints_and_auto_increment(self):
        expected_keys = {"department_id", "instructor_id", "student_id", "course_id", "semester_id", "enrollment_id"}
        columns = query(
            "SELECT table_name, column_name, is_nullable, extra "
            f"FROM information_schema.columns WHERE table_schema = '{DATABASE}'"
        )
        actual_ids = set()
        for line in columns:
            table, column, nullable, extra = line.split("\t")
            if column == table[:-1] + "_id" and column in expected_keys:  # each table's own primary key
                actual_ids.add(column)
                self.assertIn("auto_increment", extra.lower(), f"{table}.{column} must auto-increment")
        self.assertEqual(actual_ids, expected_keys)
        required = query(
            "SELECT table_name, column_name FROM information_schema.columns "
            f"WHERE table_schema = '{DATABASE}' AND is_nullable = 'NO'"
        )
        self.assertGreaterEqual(len(required), 20)
        indexes = query(
            "SELECT table_name, index_name FROM information_schema.statistics "
            f"WHERE table_schema = '{DATABASE}' AND non_unique = 0"
        )
        unique_pairs = {(row.split("\t")[0], row.split("\t")[1]) for row in indexes}
        for table, field in [("students", "email"), ("courses", "course_code"), ("departments", "department_code")]:
            with self.subTest(unique=field):
                matching = [name for tbl, name in unique_pairs if tbl == table and name != "PRIMARY"]
                self.assertTrue(matching, f"{table}.{field} needs a unique constraint")

    def test_foreign_key_actions(self):
        rows = query(
            "SELECT k.table_name, k.column_name, k.referenced_table_name, r.delete_rule, r.update_rule "
            "FROM information_schema.key_column_usage k JOIN information_schema.referential_constraints r "
            "ON r.constraint_schema = k.constraint_schema AND r.constraint_name = k.constraint_name AND r.table_name = k.table_name "
            f"WHERE k.constraint_schema = '{DATABASE}' AND k.referenced_table_name IS NOT NULL"
        )
        actions = {(r.split("\t")[0], r.split("\t")[1]): (r.split("\t")[3].upper(), r.split("\t")[4].upper()) for r in rows}
        required = {
            ("instructors", "department_id"): ("RESTRICT", "CASCADE"),
            ("courses", "department_id"): ("RESTRICT", "CASCADE"),
            ("courses", "instructor_id"): ("SET NULL", "CASCADE"),
            ("enrollments", "student_id"): ("CASCADE", "CASCADE"),
            ("enrollments", "course_id"): ("RESTRICT", "CASCADE"),
            ("enrollments", "semester_id"): ("RESTRICT", "CASCADE"),
        }
        for key, value in required.items():
            with self.subTest(foreign_key=key):
                self.assertEqual(actions.get(key), value)
        self.assertTrue(rows, "foreign keys are required")

    def test_checks_and_date_order(self):
        self.assertEqual(query("SELECT COUNT(*) FROM students WHERE gpa < 0 OR gpa > 4")[0], "0")
        self.assertEqual(query("SELECT COUNT(*) FROM enrollments WHERE grade IS NOT NULL AND (grade < 0 OR grade > 4)")[0], "0")
        self.assertEqual(query("SELECT COUNT(*) FROM courses WHERE credits <= 0")[0], "0")
        self.assertEqual(query("SELECT COUNT(*) FROM semesters WHERE end_date <= start_date")[0], "0")
        checks = query(
            "SELECT t.table_name, c.check_clause FROM information_schema.check_constraints c "
            "JOIN information_schema.table_constraints t ON t.constraint_schema = c.constraint_schema AND t.constraint_name = c.constraint_name "
            f"WHERE t.constraint_schema = '{DATABASE}' AND t.constraint_type = 'CHECK'"
        )
        self.assertGreaterEqual(len(checks), 4, "domain and date constraints should be enforced")

    def test_rejects_invalid_values_and_duplicate_registration(self):
        statements = [
            "INSERT INTO students (student_code, student_name, email, gender, birth_date, gpa, department_id) VALUES ('X1', 'Bad GPA', 'bad-gpa@example.test', 'Male', '2006-01-01', 4.1, 1)",
            "INSERT INTO students (student_code, student_name, email, gender, birth_date, department_id) VALUES ('X2', 'Bad Gender', 'bad-gender@example.test', 'Robot', '2006-01-01', 1)",
            "INSERT INTO students (student_code, student_name, email, gender, birth_date, department_id) VALUES ('X3', 'Dup Email', 'huong.nt@student.example.vn', 'Male', '2006-01-01', 1)",
            "INSERT INTO students (student_code, student_name, email, gender, birth_date, department_id) VALUES ('X4', 'No Dept', 'x4@example.test', 'Male', '2006-01-01', 999)",
            "INSERT INTO courses (course_code, course_name, credits, department_id) VALUES ('BAD0', 'No credits', 0, 1)",
            "INSERT INTO semesters (semester_name, start_date, end_date) VALUES ('Invalid', '2026-10-02', '2026-10-01')",
            "INSERT INTO enrollments (student_id, course_id, semester_id, enrollment_date, grade) VALUES (1, 1, 1, '2026-01-01', 4.1)",
            "INSERT INTO enrollments (student_id, course_id, semester_id, enrollment_date) VALUES (1, 2, 1, '2026-01-01')",
        ]
        for statement in statements:
            with self.subTest(statement=statement):
                result = mysql("START TRANSACTION;\n" + statement + ";\nROLLBACK;", check=False)
                self.assertNotEqual(result.returncode, 0, statement)

    def test_accepts_boundary_values_and_defaults(self):
        sql = (
            "START TRANSACTION;\n"
            "INSERT INTO enrollments (student_id, course_id, semester_id, enrollment_date, grade) VALUES (1, 1, 1, '2026-01-01', 4.00);\n"
            "INSERT INTO enrollments (student_id, course_id, semester_id, enrollment_date, grade) VALUES (1, 3, 1, '2026-01-01', 0.00);\n"
            "INSERT INTO enrollments (student_id, course_id, semester_id, enrollment_date) VALUES (1, 4, 1, '2026-01-01');\n"
            "SELECT status, grade IS NULL FROM enrollments WHERE student_id = 1 AND course_id = 4 AND semester_id = 1;\n"
            "ROLLBACK;"
        )
        self.assertEqual(mysql(sql).stdout.strip().splitlines()[-1], "Enrolled\t1")

    def test_foreign_key_delete_behaviors_rollback(self):
        cases = [
            ("DELETE FROM departments WHERE department_id = 1", False),
            ("DELETE FROM courses WHERE course_id = 1", False),
            ("DELETE FROM semesters WHERE semester_id = 1", False),
            ("DELETE FROM students WHERE student_id = 1", True),
            ("DELETE FROM instructors WHERE instructor_id = 1", True),
        ]
        for statement, should_succeed in cases:
            with self.subTest(statement=statement):
                result = mysql("START TRANSACTION;\n" + statement + ";\nROLLBACK;", check=False)
                self.assertEqual(result.returncode == 0, should_succeed, result.stderr)

    def test_sql_import_is_idempotent(self):
        before = {table: int(query(f"SELECT COUNT(*) FROM {table}")[0]) for table in
                  ("departments", "instructors", "students", "courses", "semesters", "enrollments")}
        self.import_sql()
        after = {table: int(query(f"SELECT COUNT(*) FROM {table}")[0]) for table in before}
        self.assertEqual(after, before)


if __name__ == "__main__":
    unittest.main()
