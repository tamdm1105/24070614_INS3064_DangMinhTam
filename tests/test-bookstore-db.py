import os
import subprocess
import unittest

CONTAINER = "ins3064-homework04-mysql-261005"  # fixed name: tests only ever touch this disposable container
DATABASE = "bookstore_db"
SQL_FILE = os.path.join(os.path.dirname(__file__), "..", "bookstore_db.sql")
TABLES = ("authors", "publishers", "categories", "books", "book_authors", "book_categories",
          "customers", "orders", "order_items", "reviews")


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


def import_sql():
    with open(SQL_FILE, encoding="utf-8") as sql_file:
        result = subprocess.run(["docker", "exec", "-i", CONTAINER, "mysql", "-uroot"],
                                stdin=sql_file, text=True, capture_output=True)
    if result.returncode:
        raise AssertionError(result.stderr.strip())


class BookstoreDatabaseTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        # This test suite is intentionally restricted to the disposable named container.
        actual = subprocess.run(
            ["docker", "inspect", "--format", "{{.Name}} {{.HostConfig.NetworkMode}} {{json .NetworkSettings.Ports}}", CONTAINER],
            text=True, capture_output=True, check=True,
        ).stdout.strip()
        if actual != f"/{CONTAINER} none {{}}":
            raise RuntimeError(f"Refusing non-isolated MySQL container: {actual}")
        import_sql()

    def test_tables_engine_and_charset(self):
        rows = query("SELECT table_name, engine, table_collation FROM information_schema.tables "
                     f"WHERE table_schema = '{DATABASE}' AND table_type = 'BASE TABLE'")
        self.assertEqual({r.split("\t")[0] for r in rows}, set(TABLES))
        for row in rows:
            _, engine, collation = row.split("\t")
            self.assertEqual(engine, "InnoDB")
            self.assertTrue(collation.startswith("utf8mb4"))

    def test_sample_data_minimums_and_utf8(self):
        minimum = {"books": 8, "authors": 6, "publishers": 4, "categories": 5, "customers": 5,
                   "orders": 6, "order_items": 12, "reviews": 10}
        for table, count in minimum.items():
            with self.subTest(table=table):
                self.assertGreaterEqual(int(query(f"SELECT COUNT(*) FROM {table}")[0]), count)
        self.assertEqual(query("SELECT title FROM books WHERE isbn = '9786041200012'"), ["Cho Tôi Xin Một Vé Đi Tuổi Thơ"])

    def test_many_to_many_and_self_reference(self):
        self.assertTrue(query("SELECT book_id FROM book_authors GROUP BY book_id HAVING COUNT(*) > 1"))
        self.assertTrue(query("SELECT book_id FROM book_categories GROUP BY book_id HAVING COUNT(*) > 1"))
        self.assertTrue(query("SELECT category_id FROM categories WHERE parent_category_id IS NOT NULL"))

    def test_order_totals_match_items(self):
        mismatched = query("SELECT o.order_id FROM orders o JOIN order_items oi ON oi.order_id = o.order_id "
                           "GROUP BY o.order_id, o.total_amount HAVING o.total_amount <> SUM(oi.subtotal)")
        self.assertEqual(mismatched, [])

    def test_foreign_key_actions(self):
        rows = query(
            "SELECT k.table_name, k.column_name, r.delete_rule, r.update_rule "
            "FROM information_schema.key_column_usage k JOIN information_schema.referential_constraints r "
            "ON r.constraint_schema = k.constraint_schema AND r.constraint_name = k.constraint_name AND r.table_name = k.table_name "
            f"WHERE k.constraint_schema = '{DATABASE}' AND k.referenced_table_name IS NOT NULL"
        )
        actions = {tuple(r.split("\t")[:2]): tuple(r.split("\t")[2:]) for r in rows}
        self.assertEqual(actions, {
            ("categories", "parent_category_id"): ("SET NULL", "CASCADE"),
            ("books", "publisher_id"): ("RESTRICT", "CASCADE"),
            ("book_authors", "book_id"): ("CASCADE", "CASCADE"),
            ("book_authors", "author_id"): ("RESTRICT", "CASCADE"),
            ("book_categories", "book_id"): ("CASCADE", "CASCADE"),
            ("book_categories", "category_id"): ("CASCADE", "CASCADE"),
            ("orders", "customer_id"): ("RESTRICT", "CASCADE"),
            ("order_items", "order_id"): ("CASCADE", "CASCADE"),
            ("order_items", "book_id"): ("RESTRICT", "CASCADE"),
            ("reviews", "book_id"): ("CASCADE", "CASCADE"),
            ("reviews", "customer_id"): ("CASCADE", "CASCADE"),
        })

    def test_rejects_invalid_rows(self):
        statements = [
            "INSERT INTO books (isbn, title, publisher_id, price) VALUES ('9780000000001', 'Zero price', 1, 0)",
            "INSERT INTO books (isbn, title, publisher_id, price, stock_quantity) VALUES ('9780000000002', 'Neg stock', 1, 1, -1)",
            "INSERT INTO books (isbn, title, publisher_id, price) VALUES ('97800000ABC', 'Bad ISBN', 1, 1)",
            "INSERT INTO books (isbn, title, publisher_id, price) VALUES ('9786041190016', 'Dup ISBN', 1, 1)",
            "INSERT INTO books (isbn, title, publisher_id, price) VALUES ('9780000000003', 'No publisher', 999, 1)",
            "INSERT INTO customers (full_name, email, password_hash) VALUES ('Dup', 'an.nguyen@example.com', 'x')",
            "INSERT INTO reviews (book_id, customer_id, rating) VALUES (6, 6, 6)",
            "INSERT INTO reviews (book_id, customer_id, rating) VALUES (1, 1, 3)",
            "INSERT INTO order_items (order_id, book_id, quantity, unit_price) VALUES (1, 2, 0, 1)",
            "INSERT INTO orders (customer_id, status, shipping_address) VALUES (1, 'lost', 'x')",
            "INSERT INTO book_authors (book_id, author_id) VALUES (1, 1)",
        ]
        for statement in statements:
            with self.subTest(statement=statement):
                result = mysql("START TRANSACTION;\n" + statement + ";\nROLLBACK;", check=False)
                self.assertNotEqual(result.returncode, 0, statement)

    def test_defaults_and_generated_subtotal(self):
        sql = (
            "START TRANSACTION;\n"
            "INSERT INTO orders (customer_id, shipping_address) VALUES (6, '3 Lê Lợi, TP. Huế');\n"
            "INSERT INTO order_items (order_id, book_id, quantity, unit_price) VALUES (LAST_INSERT_ID(), 6, 3, 279000);\n"
            "SELECT o.status, o.order_date IS NOT NULL, oi.subtotal FROM orders o JOIN order_items oi ON oi.order_id = o.order_id WHERE o.customer_id = 6;\n"
            "ROLLBACK;"
        )
        self.assertEqual(mysql(sql).stdout.strip().splitlines()[-1], "pending\t1\t837000.00")

    def test_delete_behaviors_rollback(self):
        cases = [
            ("DELETE FROM publishers WHERE publisher_id = 1", False),   # has books
            ("DELETE FROM customers WHERE customer_id = 1", False),     # has orders
            ("DELETE FROM books WHERE book_id = 1", False),             # has been sold
            ("DELETE FROM authors WHERE author_id = 1", False),         # still has books
            ("DELETE FROM orders WHERE order_id = 1", True),            # items cascade
            ("DELETE FROM books WHERE book_id = 6", True),              # never sold
            ("DELETE FROM categories WHERE category_id = 1", True),     # child genre -> NULL parent
        ]
        for statement, should_succeed in cases:
            with self.subTest(statement=statement):
                result = mysql("START TRANSACTION;\n" + statement + ";\nROLLBACK;", check=False)
                self.assertEqual(result.returncode == 0, should_succeed, result.stderr)

    def test_sql_import_is_idempotent(self):
        before = {table: query(f"SELECT COUNT(*) FROM {table}")[0] for table in TABLES}
        import_sql()
        self.assertEqual({table: query(f"SELECT COUNT(*) FROM {table}")[0] for table in TABLES}, before)


if __name__ == "__main__":
    unittest.main()
