# INS3064 — Homework (MySQL)

Student: Dang Minh Tam · ID: 24070614

A MySQL database for a university course registration system: 6 tables, constraints and realistic sample data (Vietnamese names).

## Homework 7: Advanced SQL (Online Bookstore)

`bookstore_queries.sql` holds 10 queries against `bookstore_db` (Homework 6), each with a description and an expected-output block:

| # | Technique | Returns |
|---|---|---|
| 1–3 | JOIN | books ↔ authors; order lines; books + publisher + categories (5 tables, parent genre) |
| 4–5 | GROUP BY | sales by book; customer summary incl. customers without orders (LEFT JOIN) |
| 6–7 | Subquery | books above average price; best-selling author(s), ties kept (no `LIMIT`) |
| 8 | HAVING | customers with more than 2 reviews rated ≥ 3 |
| 9 | View | `v_book_sales_summary` (0 / NULL when no sales or reviews) |
| 10 | Combined | monthly revenue for the current year, all 12 months, running total |

Revenue excludes `cancelled` orders. `homework07.zip` is the LMS upload. Test: `python3 tests/test-bookstore-queries.py` (checks every query returns its documented output).

**phpMyAdmin:** import `bookstore_db.sql` first, then open the **SQL** tab and paste `bookstore_queries.sql`.

## Homework 6: Online Bookstore database design

| File | Purpose |
|---|---|
| `bookstore_erd.md` | Text ERD: entities, PK/FK, cardinality, 3NF notes. |
| `bookstore_db.sql` | Creates `bookstore_db`: 10 InnoDB/utf8mb4 tables, PK/FK (explicit `ON DELETE`/`ON UPDATE`), `NOT NULL`, `UNIQUE`, `CHECK`, `DEFAULT`, sample data and a 3NF comment block. Safe to re-run. |
| `homework06.zip` | `bookstore_erd.md` + `bookstore_db.sql`, for the LMS upload. |
| `tests/test-bookstore-db.py` | 9 acceptance tests against a real MySQL server. |

Sample data: 9 books, 8 authors, 6 publishers, 7 categories (2 sub-genres), 6 customers (one without orders), 9 orders (one cancelled), 16 order items, 10 reviews.

**phpMyAdmin:** SQL tab (no database selected) → import `bookstore_db.sql` → **Go**. **CLI:** `mysql -u root -p < bookstore_db.sql`. Test: `python3 tests/test-bookstore-db.py` (same container as below).

## Homework 5: SQL queries

`university_queries.sql` holds 10 queries (SELECT, WHERE, AND/OR, ORDER BY, LIMIT, LIKE, aggregates, GROUP BY + HAVING, 2-table JOIN, 4-table JOIN) against `university_db`, each with a description and expected output. `homework05.zip` is the LMS upload.

**phpMyAdmin:** first import `university_db.sql` (below), select `university_db`, open the **SQL** tab and paste `university_queries.sql`.

## Files (Homework 4)

| File | Purpose |
|---|---|
| `university_db.sql` | The submission: creates `university_db`, 6 tables and sample data. Safe to re-run. |
| `homework04.zip` | ZIP containing only `university_db.sql`, for the LMS upload. |
| `tests/test-university-db.py` | Acceptance tests that run against a real MySQL server. |
| `plans/` | Implementation plan. |

## Schema

```
departments 1──* instructors
departments 1──* students   (major)
departments 1──* courses
instructors 1──* courses    (instructor_id may be NULL)
students    1──* enrollments *──1 courses
                             *──1 semesters
```

| Table | Rows | Notes |
|---|---:|---|
| `departments` | 5 | unique `department_code` and `department_name` |
| `instructors` | 5 | unique `email` |
| `students` | 6 | unique `student_code`, `email`; `gender` is an `ENUM`; `gpa` is `DECIMAL(3,2)` checked 0.00–4.00 |
| `courses` | 6 | unique `course_code`; `credits > 0` |
| `semesters` | 5 | unique name; `end_date > start_date` |
| `enrollments` | 12 | unique `(student_id, course_id, semester_id)`; `status` is an `ENUM`; nullable `grade` checked 0.00–4.00 |

Foreign key actions (all `ON UPDATE CASCADE`):

| Foreign key | `ON DELETE` | Reason |
|---|---|---|
| instructors/students/courses → departments | `RESTRICT` | a department in use must not vanish |
| courses → instructors | `SET NULL` | a course survives when its instructor leaves |
| enrollments → students | `CASCADE` | removing a student removes their registrations |
| enrollments → courses / semesters | `RESTRICT` | registered courses and semesters must be kept |

## Run it

**phpMyAdmin:** open the **SQL** tab (no database selected) → paste or import `university_db.sql` → **Go**.

**Command line:**

```bash
mysql -u root -p < university_db.sql
```

> The script drops and recreates `university_db`. Run it only on a practice server. Requires MySQL 8.0.16+ (for `CHECK`); tested on MySQL 8.4.

## Test

The tests import the script (twice) into a disposable MySQL container and check tables, row counts, keys, referential actions, `CHECK` rules, rejected invalid rows and Vietnamese text round-trip.

```bash
docker run -d --name ins3064-homework04-mysql-261005 --network none \
  --tmpfs /var/lib/mysql -e MYSQL_ALLOW_EMPTY_PASSWORD=yes mysql:8.4
python3 tests/test-university-db.py        # 9 tests, all pass
```

## Submission

- **GitHub:** this repository (as requested by the instructor).
- **LMS (from the assignment page):** upload `homework04.zip` and paste the unlisted YouTube video link by Sunday 23:59.
- **Video:** 1–2 minutes with voice, recorded by the student with OBS (see the assignment page for what to show).
