-- =============================================================================
-- Student    : Dang Minh Tam
-- Student ID : 24070614
-- Assignment : INS3064 - Homework 4: Introduction to MySQL (University database)
-- Date       : 2026-10-05
--
-- WARNING: this script DROPs and recreates the database `university_db`.
-- Run it only on a practice/homework MySQL server (MySQL 8.0.16+ for CHECK).
-- It is safe to run repeatedly: every run rebuilds the same schema and data.
-- =============================================================================

-- Read this file as UTF-8 so Vietnamese names are stored correctly on any client.
SET NAMES utf8mb4;

DROP DATABASE IF EXISTS university_db;
CREATE DATABASE university_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE university_db;

-- Drop tables child-first so foreign keys never block a drop
-- (redundant after DROP DATABASE, kept so the file also works on its own).
DROP TABLE IF EXISTS enrollments;
DROP TABLE IF EXISTS courses;
DROP TABLE IF EXISTS students;
DROP TABLE IF EXISTS instructors;
DROP TABLE IF EXISTS semesters;
DROP TABLE IF EXISTS departments;

-- -----------------------------------------------------------------------------
-- departments: academic departments (parent of instructors, students, courses)
-- -----------------------------------------------------------------------------
CREATE TABLE departments (
    department_id   INT          NOT NULL AUTO_INCREMENT,           -- surrogate key
    department_code VARCHAR(10)  NOT NULL,                          -- short code, e.g. CS
    department_name VARCHAR(100) NOT NULL,
    description     TEXT NULL,                                      -- free-text, optional
    created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP, -- row creation time
    PRIMARY KEY (department_id),
    UNIQUE KEY uq_departments_code (department_code),              -- no duplicate codes
    UNIQUE KEY uq_departments_name (department_name)               -- no duplicate names
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- instructors: teaching staff, each belongs to one department
-- -----------------------------------------------------------------------------
CREATE TABLE instructors (
    instructor_id   INT          NOT NULL AUTO_INCREMENT,
    instructor_name VARCHAR(100) NOT NULL,
    email           VARCHAR(100) NOT NULL,
    hire_date       DATE         NOT NULL,
    department_id   INT          NOT NULL,
    PRIMARY KEY (instructor_id),
    UNIQUE KEY uq_instructors_email (email),                       -- one account per email
    -- RESTRICT: a department with instructors cannot be deleted by accident.
    -- CASCADE on update: if a department id changes, instructors follow it.
    CONSTRAINT fk_instructors_department FOREIGN KEY (department_id)
        REFERENCES departments (department_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- students: enrolled students; department_id is the student's major
-- -----------------------------------------------------------------------------
CREATE TABLE students (
    student_id    INT          NOT NULL AUTO_INCREMENT,
    student_code  VARCHAR(10)  NOT NULL,                           -- student number, e.g. 25000001
    student_name  VARCHAR(100) NOT NULL,
    email         VARCHAR(100) NOT NULL,
    gender        ENUM('Male', 'Female', 'Other') NOT NULL,        -- fixed set of values
    birth_date    DATE         NOT NULL,
    gpa           DECIMAL(3,2) NOT NULL DEFAULT 0.00,              -- 0.00 - 4.00 fits DECIMAL(3,2)
    department_id INT          NOT NULL,                           -- major
    PRIMARY KEY (student_id),
    UNIQUE KEY uq_students_code (student_code),
    UNIQUE KEY uq_students_email (email),
    CONSTRAINT chk_students_gpa CHECK (gpa BETWEEN 0.00 AND 4.00), -- valid GPA range
    CONSTRAINT fk_students_department FOREIGN KEY (department_id)
        REFERENCES departments (department_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- courses: course catalogue; owned by a department, taught by one instructor
-- -----------------------------------------------------------------------------
CREATE TABLE courses (
    course_id     INT          NOT NULL AUTO_INCREMENT,
    course_code   VARCHAR(10)  NOT NULL,                           -- e.g. INS3064
    course_name   VARCHAR(150) NOT NULL,
    description   TEXT NULL,
    credits       INT          NOT NULL DEFAULT 3,
    department_id INT          NOT NULL,
    instructor_id INT NULL,                                        -- NULL = not yet assigned
    PRIMARY KEY (course_id),
    UNIQUE KEY uq_courses_code (course_code),
    CONSTRAINT chk_courses_credits CHECK (credits > 0),            -- at least one credit
    CONSTRAINT fk_courses_department FOREIGN KEY (department_id)
        REFERENCES departments (department_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    -- SET NULL: if an instructor leaves, the course stays and becomes unassigned.
    CONSTRAINT fk_courses_instructor FOREIGN KEY (instructor_id)
        REFERENCES instructors (instructor_id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- semesters: academic terms in which courses are taken
-- -----------------------------------------------------------------------------
CREATE TABLE semesters (
    semester_id   INT         NOT NULL AUTO_INCREMENT,
    semester_name VARCHAR(50) NOT NULL,                            -- e.g. Fall 2025
    start_date    DATE        NOT NULL,
    end_date      DATE        NOT NULL,
    PRIMARY KEY (semester_id),
    UNIQUE KEY uq_semesters_name (semester_name),
    CONSTRAINT chk_semesters_dates CHECK (end_date > start_date)   -- term must end after it starts
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- enrollments: junction table (student x course x semester) with optional grade
-- -----------------------------------------------------------------------------
CREATE TABLE enrollments (
    enrollment_id   INT          NOT NULL AUTO_INCREMENT,
    student_id      INT          NOT NULL,
    course_id       INT          NOT NULL,
    semester_id     INT          NOT NULL,
    enrollment_date DATE         NOT NULL,
    status          ENUM('Enrolled', 'Completed', 'Dropped') NOT NULL DEFAULT 'Enrolled',
    grade           DECIMAL(3,2) NULL,                             -- NULL until graded (0.00 - 4.00)
    PRIMARY KEY (enrollment_id),
    -- A student cannot register for the same course twice in one semester.
    UNIQUE KEY uq_enrollments_registration (student_id, course_id, semester_id),
    CONSTRAINT chk_enrollments_grade CHECK (grade IS NULL OR grade BETWEEN 0.00 AND 4.00),
    -- CASCADE: deleting a student also removes their registrations.
    CONSTRAINT fk_enrollments_student FOREIGN KEY (student_id)
        REFERENCES students (student_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    -- RESTRICT: courses and semesters that have registrations cannot be deleted.
    CONSTRAINT fk_enrollments_course FOREIGN KEY (course_id)
        REFERENCES courses (course_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_enrollments_semester FOREIGN KEY (semester_id)
        REFERENCES semesters (semester_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- =============================================================================
-- Sample data (parents first so foreign keys are always satisfied)
-- =============================================================================

INSERT INTO departments (department_code, department_name, description) VALUES
('CS', 'Computer Science',       'Algorithms, programming, systems and artificial intelligence.'),
('IS', 'Information Systems',    'Business information systems, databases and web development.'),
('SE', 'Software Engineering',   'Requirements, design, testing and maintenance of software.'),
('DS', 'Data Science',           'Statistics, machine learning and large-scale data analysis.'),
('BA', 'Business Administration','Management, marketing, finance and entrepreneurship.');

INSERT INTO instructors (instructor_name, email, hire_date, department_id) VALUES
('Nguyễn Văn Hùng',  'hung.nv@university.example.vn', '2012-08-15', 1),
('Trần Thị Mai Lan', 'lan.ttm@university.example.vn', '2015-02-01', 2),
('Lê Quang Minh',    'minh.lq@university.example.vn', '2018-09-03', 3),
('Phạm Thu Hà',      'ha.pt@university.example.vn',   '2019-01-10', 4),
('Hoàng Đức Anh',    'anh.hd@university.example.vn',  '2020-06-22', 5);

INSERT INTO students (student_code, student_name, email, gender, birth_date, gpa, department_id) VALUES
('25000001', 'Nguyễn Thị Hương', 'huong.nt@student.example.vn', 'Female', '2006-03-12', 3.60, 1),
('25000002', 'Trần Quốc Bảo',    'bao.tq@student.example.vn',   'Male',   '2006-07-25', 3.25, 2),
('25000003', 'Lê Hoàng Phúc',    'phuc.lh@student.example.vn',  'Male',   '2005-11-02', 2.90, 3),
('25000004', 'Phạm Ngọc Anh',    'anh.pn@student.example.vn',   'Female', '2006-01-18', 3.85, 4),
('25000005', 'Vũ Thanh Tùng',    'tung.vt@student.example.vn',  'Male',   '2005-09-30', 3.10, 1),
('25000006', 'Đỗ Khánh Linh',    'linh.dk@student.example.vn',  'Female', '2006-05-08', 3.45, 5);

INSERT INTO courses (course_code, course_name, description, credits, department_id, instructor_id) VALUES
('INS3064', 'Multimedia Design and Web Development', 'HTML, CSS, JavaScript and MySQL basics for the web.', 3, 2, 2),
('CS2010',  'Data Structures and Algorithms',        'Lists, trees, graphs, sorting and complexity analysis.', 4, 1, 1),
('SE3020',  'Software Testing',                      'Unit, integration and acceptance testing techniques.',   3, 3, 3),
('DS3030',  'Machine Learning Fundamentals',         'Supervised and unsupervised learning with Python.',      4, 4, 4),
('BA2040',  'Principles of Marketing',               'Market analysis, branding and customer behaviour.',      3, 5, 5),
('CS3050',  'Database Systems',                      'Relational model, SQL, normalization and transactions.', 3, 1, 1);

INSERT INTO semesters (semester_name, start_date, end_date) VALUES
('Fall 2024',   '2024-09-02', '2025-01-12'),
('Spring 2025', '2025-02-10', '2025-06-08'),
('Fall 2025',   '2025-09-01', '2026-01-11'),
('Spring 2026', '2026-02-09', '2026-06-07'),
('Fall 2026',   '2026-09-07', '2027-01-10');

-- grade is NULL where the course is still in progress or not graded yet.
INSERT INTO enrollments (student_id, course_id, semester_id, enrollment_date, status, grade) VALUES
(1, 2, 1, '2024-08-20', 'Completed', 3.70),
(1, 6, 2, '2025-01-25', 'Completed', 3.50),
(2, 1, 3, '2025-08-18', 'Completed', 3.20),
(2, 6, 3, '2025-08-18', 'Completed', 3.00),
(3, 3, 3, '2025-08-19', 'Completed', 2.80),
(3, 1, 4, '2026-01-26', 'Enrolled',  NULL),
(4, 4, 2, '2025-01-27', 'Completed', 3.90),
(4, 2, 3, '2025-08-20', 'Completed', 3.80),
(5, 2, 1, '2024-08-21', 'Completed', 3.10),
(5, 3, 4, '2026-01-27', 'Enrolled',  NULL),
(6, 5, 3, '2025-08-22', 'Completed', 3.40),
(6, 1, 5, '2026-08-24', 'Dropped',   NULL);
