---
title: "Homework 4 — University Database"
description: "Create, validate, document, and submit a rerunnable MySQL university database."
status: completed
priority: P2
effort: 2h
branch: homework-04
tags: [database, mysql, homework, docs]
created: 2026-10-05
---
# Homework 4 Implementation Plan

## Context and scope
- Student: Dang Minh Tam; ID: 24070614; assignment: Homework 4; date: 2026-10-05 (Asia/Bangkok).
- Confirmed requirements: https://hieutachi.github.io/VNU_IS_Ebook_INS3064/homework/session-04/homework.html
- Root: `/mnt/dunghd/24070614_INS3064_DangMinhTam`. Empty repository; no existing project rules or plans. Never modify `/mnt/dunghd/agent_platform`.
- Deliver only SQL, English documentation, and the submission ZIP; no app/frontend. Vietnamese sample names remain Vietnamese. Aim for readable SQL under 200 lines, without sacrificing requirements.
- Linux/bash; coordinator confirms MySQL 8.4 ready in `ins3064-homework04-mysql-261005` (`--network none`, tmpfs datadir, no exposed ports); `docker exec -i ins3064-homework04-mysql-261005 mysql -uroot` works. Local branch: `homework-04`; target remote empty.

## Architecture and data flow
- `university_db.sql` → MySQL client inside isolated Docker container → recreated `university_db` → six InnoDB/utf8mb4 tables → seeded rows → verification queries.
- Parent-first creation/insertion: departments → instructors/students → courses; semesters → enrollments after students/courses. Drop tables child-first.
- Each table: `INT AUTO_INCREMENT` primary key. Departments link to instructors, students, courses; courses also reference instructors; enrollments reference students, courses, semesters.
- Use primary keys `department_id`, `instructor_id`, `student_id`, `course_id`, `semester_id`, `enrollment_id`. All FKs: `ON UPDATE CASCADE`; department/course/semester parent deletions: `RESTRICT`; `courses.instructor_id`: `ON DELETE SET NULL`; `enrollments.student_id`: `ON DELETE CASCADE`. Explain choices in comments.
- Required fields/FKs: `NOT NULL` except nullable `courses.instructor_id`; unique department/course codes, student numbers and emails; unique semester name; registration uniqueness on `(student_id, course_id, semester_id)`.
- Use `VARCHAR` for names/codes, `TEXT` for course description, `INT` for IDs/credits, `DECIMAL(3,2)` for grade, `DATE` for birth/enrollment/semester dates, `ENUM` for enrollment status with a sensible default.
- Grade nullable (ungraded); both student GPA and grade checked from 0 through 4 inclusive; positive credits and semester end after start. Document chosen defaults/checks; avoid speculative constraints.
- Meaningful seed data → at least 5 rows in each of departments/instructors/students/courses/semesters and 10 enrollments, including Vietnamese names, graded/ungraded rows, and valid relationships.
- Validated SQL → ZIP with one root entry `university_db.sql` → LMS submission. GitHub stores project sources/docs; pushing does not submit to LMS. Student records their own real 1–2-minute demonstration separately.

## Phases, dependencies, and file ownership
All paths below are relative to the root. Acceptance-test authoring may parallel Phase 1 with exclusive `tests/*` ownership; test execution waits for SQL. Remaining phases sequential; no overlapping edits.
| Phase | Status / effort | Blockers | Owner / files |
|---|---|---|---|
| 1. Schema and seed | Pending / 40m | Confirmed requirements | Implementer: create `university_db.sql` |
| 2. Actual database validation | Pending / 40m | Execution: Phase 1; isolated MySQL ready | Tester: `tests/*` and validation commands; no implementation edits |
| 3. Documentation and package | Pending / 25m | Phase 2 passes | Docs owner: create `README.md`, `docs/video-script.md`; packager: create `homework04.zip` |
| 4. Review and publish | Pending / 15m | Phases 1–3; GitHub authentication | Reviewer: read-only; lead: plan status and Git operations |

## TODO checklist
- [ ] 1. Create SQL header with name, ID, assignment/date and destructive-reset warning; add table/constraint comments in English.
- [ ] 1. Include `DROP DATABASE IF EXISTS`, database creation/selection, and explicit `DROP TABLE IF EXISTS` statements; use dependency order rather than disabling FK checks.
- [ ] 1. Implement the six tables, constraints, declared referential actions, and deterministic seed rows; check syntax by importing on real MySQL immediately after edits.
- [ ] 2. Reuse coordinator's ready isolated MySQL 8.4 container; confirm readiness/version and isolation before tests. Keep root access limited to this disposable container; never expose its passwordless local connection.
- [ ] 2. Import the unchanged script twice with normal error handling (no `--force`); both imports must exit zero and yield identical seed contents/counts without accumulation.
- [ ] 2. Run the test matrix below; assert expected failures rather than merely printing errors. Roll back each mutation test and keep initial seed data intact.
- [ ] 2. If tests fail, return fixes to implementer, rerun the full matrix, and only then proceed; preserve genuine evidence, never claim unrun tests passed.
- [ ] 3. Write English README: prerequisites, Docker readiness/import/rerun/cleanup commands, destructive reset warning, schema and constraints, actual test results, ZIP command, and GitHub versus LMS instructions.
- [ ] 3. Write an English timed video script: identity (0–15s), tables/relationships (15–45s), real import/counts/constraint demonstration (45–100s), submission recap (100–120s). Do not fabricate a video or recording evidence.
- [ ] 3. Create `homework04.zip` containing only `university_db.sql`; inspect archive entries and compare extracted SQL byte-for-byte with tested source; smoke-import extracted SQL in the isolated database.
- [ ] 4. Obtain code review after tests pass; resolve correctness findings, rerun affected/full tests as appropriate, and rebuild ZIP after any SQL edit.
- [ ] 4. Inspect target remote and diff; use existing `homework-04` branch (do not commit on default `main`); stage only intended target-repository deliverables, no passwords/logs/runtime files. Commit and push as explicitly requested; verify remote branch SHA equals local HEAD. No force push.
- [ ] 4. Mark implementation completion honestly; student recording and LMS upload remain explicit manual actions unless genuinely completed. Remove only the named disposable container/resources.

## Test matrix and measurable acceptance
| Level | Coverage / passing condition |
|---|---|
| Static review (unit-equivalent) | Header, six tables, both DROP forms, all seven required types, explicit FK actions/comments; SQL remains readable; no separate application unit suite needed. |
| Integration: schema/data | Exactly six tables; required row minima; inspect PK/AUTO_INCREMENT, FK, UNIQUE, NOT NULL, DEFAULT, CHECK, InnoDB/utf8mb4 metadata; joined data has no orphans and Vietnamese names survive round-trip. |
| Integration: invalid inputs | Reject duplicate registration, duplicate unique values, orphan FK values, missing required values, GPA/grade below 0/above 4, nonpositive credits and reversed semester dates; accept NULL/0/4 grades and apply omitted defaults correctly. |
| Integration: FK actions | For each FK edge, update a referenced ID and verify cascading children; reject deletion of referenced departments/instructors; delete referenced student/course/semester and verify enrollment cascade. Use transactions and rollback. |
| End-to-end | Two clean imports succeed, deterministic data matches, ZIP has exactly one correct SQL entry and imports, README commands work, reviewed changes pushed to verified target remote. Recording/LMS submission tracked separately. |

## Risks, compatibility, and rollback
Risk scale: Low/Medium/High likelihood × impact; any High impact requires an explicit guard.
| Phase | Risk (likelihood × impact) | Mitigation and rollback |
|---|---|---|
| 1 | Accidental data destruction (Low × High) | Destructive reset prominently documented; execute only in disposable instance. No existing users/data/integrations to migrate; never run against a populated shared server. DDL is not transactionally reversible: recreate disposable database after failure. |
| 2 | Image pull/readiness failure or false-positive tests (Medium × Medium) | Bounded readiness/error checks, actual MySQL 8.4 and explicit assertions; report blocker rather than substitute SQLite/mocks. Roll back DML tests; remove only owned container/volume and retry. Never change host proxy settings. |
| 3 | Stale archive or fabricated recording (Medium × Medium) | Build ZIP from final tested SQL, compare bytes and test extraction. Rebuild affected docs/archive; require actual student recording, not generated evidence. |
| 4 | Wrong remote/secrets/premature publication (Low × High) | Inspect remote/staged files, keep ephemeral credentials out of Git, tests/review gate publication. Correct published changes with a normal revert/fix commit, never destructive reset/force push; rebuild archive if source changes. |

## Unresolved questions
None for implementation. Real student recording and LMS upload require student action; Docker image retrieval and GitHub authentication remain execution prerequisites.
