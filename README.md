# INS3064 — Homework 4: University Database (MySQL)

Student: Dang Minh Tam · ID: 24070614

A MySQL database for a university course registration system: 6 tables, constraints and realistic sample data (Vietnamese names).

## Files

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
