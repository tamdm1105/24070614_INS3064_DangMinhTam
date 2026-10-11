-- ============================================================
-- Name:       Dang Minh Tam
-- Student ID: 24070614
-- Assignment: Homework 5 - Introduction to SQL
-- Date:       2026-10-11
-- ============================================================

USE university_db;

-- ------------------------------------------------------------
-- Query 1: Basic SELECT - all semesters
-- Description: Retrieve every column and every row from the semesters table.
-- Expected output: 5 rows.
-- ------------------------------------------------------------
SELECT *
FROM semesters;

-- Expected output (5 rows):
-- +-------------+---------------+------------+------------+
-- | semester_id | semester_name | start_date | end_date   |
-- +-------------+---------------+------------+------------+
-- |           1 | Fall 2024     | 2024-09-02 | 2025-01-12 |
-- |           2 | Spring 2025   | 2025-02-10 | 2025-06-08 |
-- |           3 | Fall 2025     | 2025-09-01 | 2026-01-11 |
-- |           4 | Spring 2026   | 2026-02-09 | 2026-06-07 |
-- |           5 | Fall 2026     | 2026-09-07 | 2027-01-10 |
-- +-------------+---------------+------------+------------+

-- ------------------------------------------------------------
-- Query 2: WHERE with a comparison operator
-- Description: List the courses worth 4 or more credits.
-- Expected output: 2 rows.
-- ------------------------------------------------------------
SELECT course_code, course_name, credits
FROM courses
WHERE credits >= 4;

-- Expected output (2 rows):
-- +-------------+--------------------------------+---------+
-- | course_code | course_name                    | credits |
-- +-------------+--------------------------------+---------+
-- | CS2010      | Data Structures and Algorithms |       4 |
-- | DS3030      | Machine Learning Fundamentals  |       4 |
-- +-------------+--------------------------------+---------+

-- ------------------------------------------------------------
-- Query 3: WHERE with AND / OR
-- Description: Find female students with a GPA of at least 3.5, or any student with a GPA below 3.0.
-- Expected output: 3 rows.
-- ------------------------------------------------------------
SELECT student_code, student_name, gender, gpa
FROM students
WHERE (gender = 'Female' AND gpa >= 3.5)
   OR gpa < 3.0;

-- Expected output (3 rows):
-- +--------------+------------------------+--------+------+
-- | student_code | student_name           | gender | gpa  |
-- +--------------+------------------------+--------+------+
-- | 25000001     | Nguyễn Thị Hương       | Female | 3.60 |
-- | 25000003     | Lê Hoàng Phúc          | Male   | 2.90 |
-- | 25000004     | Phạm Ngọc Anh          | Female | 3.85 |
-- +--------------+------------------------+--------+------+

-- ------------------------------------------------------------
-- Query 4: ORDER BY on two columns
-- Description: List all students sorted by GPA from highest to lowest, then by name A-Z.
-- Expected output: 6 rows.
-- ------------------------------------------------------------
SELECT student_code, student_name, gpa
FROM students
ORDER BY gpa DESC, student_name ASC;

-- Expected output (6 rows):
-- +--------------+------------------------+------+
-- | student_code | student_name           | gpa  |
-- +--------------+------------------------+------+
-- | 25000004     | Phạm Ngọc Anh          | 3.85 |
-- | 25000001     | Nguyễn Thị Hương       | 3.60 |
-- | 25000006     | Đỗ Khánh Linh          | 3.45 |
-- | 25000002     | Trần Quốc Bảo          | 3.25 |
-- | 25000005     | Vũ Thanh Tùng          | 3.10 |
-- | 25000003     | Lê Hoàng Phúc          | 2.90 |
-- +--------------+------------------------+------+

-- ------------------------------------------------------------
-- Query 5: LIMIT - top 3 students
-- Description: Show the three students with the highest GPA.
-- Expected output: 3 rows.
-- ------------------------------------------------------------
SELECT student_name, gpa
FROM students
ORDER BY gpa DESC
LIMIT 3;

-- Expected output (3 rows):
-- +------------------------+------+
-- | student_name           | gpa  |
-- +------------------------+------+
-- | Phạm Ngọc Anh          | 3.85 |
-- | Nguyễn Thị Hương       | 3.60 |
-- | Đỗ Khánh Linh          | 3.45 |
-- +------------------------+------+

-- ------------------------------------------------------------
-- Query 6: LIKE pattern search
-- Description: Find courses whose name contains the word 'Data'.
-- Expected output: 2 rows.
-- ------------------------------------------------------------
SELECT course_code, course_name
FROM courses
WHERE course_name LIKE '%Data%';

-- Expected output (2 rows):
-- +-------------+--------------------------------+
-- | course_code | course_name                    |
-- +-------------+--------------------------------+
-- | CS2010      | Data Structures and Algorithms |
-- | CS3050      | Database Systems               |
-- +-------------+--------------------------------+

-- ------------------------------------------------------------
-- Query 7: Aggregate functions (COUNT / AVG / SUM)
-- Description: Summarise all enrollments: total number, average grade and number of completed ones.
-- Expected output: 1 row.
-- ------------------------------------------------------------
SELECT COUNT(*) AS total_enrollments,
       ROUND(AVG(grade), 2) AS average_grade,
       SUM(CASE WHEN status = 'Completed' THEN 1 ELSE 0 END) AS completed_count
FROM enrollments;

-- Expected output (1 row):
-- +-------------------+---------------+-----------------+
-- | total_enrollments | average_grade | completed_count |
-- +-------------------+---------------+-----------------+
-- |                12 |          3.38 |               9 |
-- +-------------------+---------------+-----------------+

-- ------------------------------------------------------------
-- Query 8: GROUP BY with HAVING
-- Description: Count enrollments and average grade per course, keeping only courses with at least 2 enrollments.
-- Expected output: 4 rows.
-- ------------------------------------------------------------
SELECT c.course_code,
       COUNT(*) AS enrollment_count,
       ROUND(AVG(e.grade), 2) AS avg_grade
FROM enrollments e
JOIN courses c ON e.course_id = c.course_id
GROUP BY c.course_id, c.course_code
HAVING COUNT(*) >= 2
ORDER BY enrollment_count DESC, c.course_code;

-- Expected output (4 rows):
-- +-------------+------------------+-----------+
-- | course_code | enrollment_count | avg_grade |
-- +-------------+------------------+-----------+
-- | CS2010      |                3 |      3.53 |
-- | INS3064     |                3 |      3.20 |
-- | CS3050      |                2 |      3.25 |
-- | SE3020      |                2 |      2.80 |
-- +-------------+------------------+-----------+

-- ------------------------------------------------------------
-- Query 9: JOIN of two tables
-- Description: Show each student together with the name of their major department (foreign key students.department_id).
-- Expected output: 6 rows.
-- ------------------------------------------------------------
SELECT s.student_code, s.student_name, d.department_name AS major
FROM students s
JOIN departments d ON s.department_id = d.department_id
ORDER BY s.student_code;

-- Expected output (6 rows):
-- +--------------+------------------------+-------------------------+
-- | student_code | student_name           | major                   |
-- +--------------+------------------------+-------------------------+
-- | 25000001     | Nguyễn Thị Hương       | Computer Science        |
-- | 25000002     | Trần Quốc Bảo          | Information Systems     |
-- | 25000003     | Lê Hoàng Phúc          | Software Engineering    |
-- | 25000004     | Phạm Ngọc Anh          | Data Science            |
-- | 25000005     | Vũ Thanh Tùng          | Computer Science        |
-- | 25000006     | Đỗ Khánh Linh          | Business Administration |
-- +--------------+------------------------+-------------------------+

-- ------------------------------------------------------------
-- Query 10: JOIN of four tables
-- Description: Show every registration with the student, course, semester, status and grade.
-- Expected output: 12 rows.
-- ------------------------------------------------------------
SELECT s.student_name, c.course_code, c.course_name,
       sem.semester_name AS semester, e.status, e.grade
FROM enrollments e
JOIN students s ON e.student_id = s.student_id
JOIN courses c ON e.course_id = c.course_id
JOIN semesters sem ON e.semester_id = sem.semester_id
ORDER BY e.enrollment_id;

-- Expected output (12 rows):
-- +------------------------+-------------+---------------------------------------+-------------+-----------+-------+
-- | student_name           | course_code | course_name                           | semester    | status    | grade |
-- +------------------------+-------------+---------------------------------------+-------------+-----------+-------+
-- | Nguyễn Thị Hương       | CS2010      | Data Structures and Algorithms        | Fall 2024   | Completed |  3.70 |
-- | Nguyễn Thị Hương       | CS3050      | Database Systems                      | Spring 2025 | Completed |  3.50 |
-- | Trần Quốc Bảo          | INS3064     | Multimedia Design and Web Development | Fall 2025   | Completed |  3.20 |
-- | Trần Quốc Bảo          | CS3050      | Database Systems                      | Fall 2025   | Completed |  3.00 |
-- | Lê Hoàng Phúc          | SE3020      | Software Testing                      | Fall 2025   | Completed |  2.80 |
-- | Lê Hoàng Phúc          | INS3064     | Multimedia Design and Web Development | Spring 2026 | Enrolled  |  NULL |
-- | Phạm Ngọc Anh          | DS3030      | Machine Learning Fundamentals         | Spring 2025 | Completed |  3.90 |
-- | Phạm Ngọc Anh          | CS2010      | Data Structures and Algorithms        | Fall 2025   | Completed |  3.80 |
-- | Vũ Thanh Tùng          | CS2010      | Data Structures and Algorithms        | Fall 2024   | Completed |  3.10 |
-- | Vũ Thanh Tùng          | SE3020      | Software Testing                      | Spring 2026 | Enrolled  |  NULL |
-- | Đỗ Khánh Linh          | BA2040      | Principles of Marketing               | Fall 2025   | Completed |  3.40 |
-- | Đỗ Khánh Linh          | INS3064     | Multimedia Design and Web Development | Fall 2026   | Dropped   |  NULL |
-- +------------------------+-------------+---------------------------------------+-------------+-----------+-------+
