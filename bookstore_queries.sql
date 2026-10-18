-- ============================================================
-- Name:       Dang Minh Tam
-- Student ID: 24070614
-- Assignment: Homework 7 - Advanced SQL (Online Bookstore)
-- Date:       2026-10-18
--
-- Runs against bookstore_db from Homework 6 (import bookstore_db.sql first).
-- Revenue everywhere = SUM(order_items.subtotal) of orders that are NOT 'cancelled'.
-- ============================================================

USE bookstore_db;

-- ------------------------------------------------------------
-- Query 1: JOIN - books with their authors
-- Description: List every book together with each of its authors, one row per
-- (book, author) pair, so a book with two authors appears twice.
-- ------------------------------------------------------------
SELECT b.title        AS book_title,
       b.isbn         AS isbn,
       a.author_name  AS author_name,
       a.nationality  AS author_nationality
FROM books AS b
INNER JOIN book_authors AS ba ON ba.book_id = b.book_id
INNER JOIN authors      AS a  ON a.author_id = ba.author_id
ORDER BY b.title, a.author_name;

/* Expected output (10 rows):
+----------------------------------------+---------------+----------------------+--------------------+
| book_title                             | isbn          | author_name          | author_nationality |
+----------------------------------------+---------------+----------------------+--------------------+
| Cho Tôi Xin Một Vé Đi Tuổi Thơ         | 9786041200012 | Nguyễn Nhật Ánh      | Vietnamese         |
| Clean Code                             | 9780132350884 | Robert C. Martin     | American           |
| Dế Mèn Phiêu Lưu Ký                    | 9786042100014 | Tô Hoài              | Vietnamese         |
| Đắc Nhân Tâm                           | 9786045800010 | Dale Carnegie        | American           |
| Homo Deus: Lược Sử Tương Lai           | 9786047710010 | Yuval Noah Harari    | Israeli            |
| Mắt Biếc                               | 9786041190016 | Nguyễn Nhật Ánh      | Vietnamese         |
| Nhà Giả Kim                            | 9786043150018 | Paulo Coelho         | Brazilian          |
| Sapiens: Lược Sử Loài Người            | 9786047700011 | Yuval Noah Harari    | Israeli            |
| The Pragmatic Programmer               | 9780135957059 | Andrew Hunt          | American           |
| The Pragmatic Programmer               | 9780135957059 | David Thomas         | British            |
+----------------------------------------+---------------+----------------------+--------------------+
*/

-- ------------------------------------------------------------
-- Query 2: JOIN - order details
-- Description: Show every order line: who ordered, when, which book, how many
-- and the line total, newest orders first.
-- ------------------------------------------------------------
SELECT o.order_id                AS order_id,
       c.full_name               AS customer_name,
       DATE(o.order_date)        AS order_date,
       o.status                  AS order_status,
       b.title                   AS book_title,
       oi.quantity               AS quantity,
       oi.unit_price             AS unit_price,
       oi.subtotal               AS line_total
FROM orders AS o
INNER JOIN customers   AS c  ON c.customer_id = o.customer_id
INNER JOIN order_items AS oi ON oi.order_id = o.order_id
INNER JOIN books       AS b  ON b.book_id = oi.book_id
ORDER BY o.order_date DESC, b.title;

/* Expected output (16 rows):
+----------+---------------------+------------+--------------+----------------------------------------+----------+------------+------------+
| order_id | customer_name       | order_date | order_status | book_title                             | quantity | unit_price | line_total |
+----------+---------------------+------------+--------------+----------------------------------------+----------+------------+------------+
|        9 | Nguyễn Văn An       | 2026-10-12 | pending      | Dế Mèn Phiêu Lưu Ký                    |        1 |   45000.00 |   45000.00 |
|        9 | Nguyễn Văn An       | 2026-10-12 | pending      | Nhà Giả Kim                            |        2 |   79000.00 |  158000.00 |
|        8 | Lê Hoàng Cường      | 2026-09-25 | shipped      | Đắc Nhân Tâm                           |        2 |   86000.00 |  172000.00 |
|        7 | Hoàng Minh Đức      | 2026-08-19 | cancelled    | Sapiens: Lược Sử Loài Người            |        2 |  299000.00 |  598000.00 |
|        6 | Trần Thị Bình       | 2026-07-08 | delivered    | Clean Code                             |        1 |  590000.00 |  590000.00 |
|        6 | Trần Thị Bình       | 2026-07-08 | delivered    | Nhà Giả Kim                            |        1 |   75000.00 |   75000.00 |
|        5 | Phạm Thu Dung       | 2026-05-10 | delivered    | Mắt Biếc                               |        1 |  110000.00 |  110000.00 |
|        5 | Phạm Thu Dung       | 2026-05-10 | delivered    | Nhà Giả Kim                            |        2 |   79000.00 |  158000.00 |
|        4 | Lê Hoàng Cường      | 2026-03-22 | delivered    | Cho Tôi Xin Một Vé Đi Tuổi Thơ         |        3 |   80000.00 |  240000.00 |
|        4 | Lê Hoàng Cường      | 2026-03-22 | delivered    | Dế Mèn Phiêu Lưu Ký                    |        2 |   45000.00 |   90000.00 |
|        3 | Nguyễn Văn An       | 2026-02-03 | delivered    | Clean Code                             |        1 |  590000.00 |  590000.00 |
|        3 | Nguyễn Văn An       | 2026-02-03 | delivered    | The Pragmatic Programmer               |        1 |  650000.00 |  650000.00 |
|        2 | Trần Thị Bình       | 2026-01-15 | delivered    | Đắc Nhân Tâm                           |        1 |   86000.00 |   86000.00 |
|        2 | Trần Thị Bình       | 2026-01-15 | delivered    | Sapiens: Lược Sử Loài Người            |        1 |  299000.00 |  299000.00 |
|        1 | Nguyễn Văn An       | 2025-12-20 | delivered    | Mắt Biếc                               |        2 |  110000.00 |  220000.00 |
|        1 | Nguyễn Văn An       | 2025-12-20 | delivered    | Nhà Giả Kim                            |        1 |   79000.00 |   79000.00 |
+----------+---------------------+------------+--------------+----------------------------------------+----------+------------+------------+
*/

-- ------------------------------------------------------------
-- Query 3: JOIN (5 tables) - books with publisher and categories
-- Description: One row per book with its publisher and all of its categories.
-- A sub-genre is shown with its parent genre, e.g. "Literature > Novel".
-- ------------------------------------------------------------
SELECT b.title           AS book_title,
       p.publisher_name  AS publisher,
       GROUP_CONCAT(CONCAT_WS(' > ', parent.category_name, c.category_name)
                    ORDER BY c.category_name SEPARATOR ', ') AS categories
FROM books AS b
INNER JOIN publishers      AS p      ON p.publisher_id = b.publisher_id
INNER JOIN book_categories AS bc     ON bc.book_id = b.book_id
INNER JOIN categories      AS c      ON c.category_id = bc.category_id
LEFT JOIN  categories      AS parent ON parent.category_id = c.parent_category_id
GROUP BY b.book_id, b.title, p.publisher_name
ORDER BY b.title;

/* Expected output (9 rows):
+----------------------------------------+-------------------+------------------------------------+
| book_title                             | publisher         | categories                         |
+----------------------------------------+-------------------+------------------------------------+
| Cho Tôi Xin Một Vé Đi Tuổi Thơ         | NXB Trẻ           | Children, Literature > Novel       |
| Clean Code                             | Pearson Education | Computing                          |
| Dế Mèn Phiêu Lưu Ký                    | NXB Kim Đồng      | Children, Literature               |
| Đắc Nhân Tâm                           | First News        | Self-help                          |
| Homo Deus: Lược Sử Tương Lai           | Omega Plus        | Non-fiction                        |
| Mắt Biếc                               | NXB Trẻ           | Literature > Novel                 |
| Nhà Giả Kim                            | Nhã Nam           | Literature > Novel                 |
| Sapiens: Lược Sử Loài Người            | Omega Plus        | Non-fiction > History, Non-fiction |
| The Pragmatic Programmer               | Pearson Education | Computing                          |
+----------------------------------------+-------------------+------------------------------------+
*/

-- ------------------------------------------------------------
-- Query 4: GROUP BY - sales by book
-- Description: Units sold and revenue for each book that has been sold
-- (cancelled orders excluded), highest revenue first.
-- ------------------------------------------------------------
SELECT b.title                     AS book_title,
       SUM(oi.quantity)            AS units_sold,
       COUNT(DISTINCT oi.order_id) AS order_count,
       SUM(oi.subtotal)            AS revenue
FROM books AS b
INNER JOIN order_items AS oi ON oi.book_id = b.book_id
INNER JOIN orders      AS o  ON o.order_id = oi.order_id
WHERE o.status <> 'cancelled'
GROUP BY b.book_id, b.title
ORDER BY revenue DESC, b.title;

/* Expected output (8 rows):
+----------------------------------------+------------+-------------+------------+
| book_title                             | units_sold | order_count | revenue    |
+----------------------------------------+------------+-------------+------------+
| Clean Code                             |          2 |           2 | 1180000.00 |
| The Pragmatic Programmer               |          1 |           1 |  650000.00 |
| Nhà Giả Kim                            |          6 |           4 |  470000.00 |
| Mắt Biếc                               |          3 |           2 |  330000.00 |
| Sapiens: Lược Sử Loài Người            |          1 |           1 |  299000.00 |
| Đắc Nhân Tâm                           |          3 |           2 |  258000.00 |
| Cho Tôi Xin Một Vé Đi Tuổi Thơ         |          3 |           1 |  240000.00 |
| Dế Mèn Phiêu Lưu Ký                    |          3 |           2 |  135000.00 |
+----------------------------------------+------------+-------------+------------+
*/

-- ------------------------------------------------------------
-- Query 5: GROUP BY + LEFT JOIN - customer order summary
-- Description: Every customer with their number of orders, total amount spent
-- (cancelled orders not counted) and last order date. LEFT JOIN keeps
-- customers who never ordered; they show 0 orders, 0 spent and NULL date.
-- ------------------------------------------------------------
SELECT c.full_name                       AS customer_name,
       c.email                           AS email,
       COUNT(o.order_id)                 AS order_count,
       COALESCE(SUM(CASE WHEN o.status <> 'cancelled'
                         THEN o.total_amount END), 0) AS total_spent,
       DATE(MAX(o.order_date))           AS last_order_date
FROM customers AS c
LEFT JOIN orders AS o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.full_name, c.email
ORDER BY total_spent DESC, c.full_name;

/* Expected output (6 rows):
+---------------------+-----------------------+-------------+-------------+-----------------+
| customer_name       | email                 | order_count | total_spent | last_order_date |
+---------------------+-----------------------+-------------+-------------+-----------------+
| Nguyễn Văn An       | an.nguyen@example.com |           3 |  1742000.00 | 2026-10-12      |
| Trần Thị Bình       | binh.tran@example.com |           2 |  1050000.00 | 2026-07-08      |
| Lê Hoàng Cường      | cuong.le@example.com  |           2 |   502000.00 | 2026-09-25      |
| Phạm Thu Dung       | dung.pham@example.com |           1 |   268000.00 | 2026-05-10      |
| Hoàng Minh Đức      | duc.hoang@example.com |           1 |        0.00 | 2026-08-19      |
| Vũ Ngọc Hà          | ha.vu@example.com     |           0 |        0.00 | NULL            |
+---------------------+-----------------------+-------------+-------------+-----------------+
*/

-- ------------------------------------------------------------
-- Query 6: Subquery - books priced above the average
-- Description: Books whose price is higher than the average price of all books.
-- The same scalar subquery also shows the average and the difference.
-- ------------------------------------------------------------
SELECT b.title                                                   AS book_title,
       b.price                                                   AS price,
       ROUND((SELECT AVG(price) FROM books), 2)                  AS average_price,
       ROUND(b.price - (SELECT AVG(price) FROM books), 2)        AS above_average_by
FROM books AS b
WHERE b.price > (SELECT AVG(price) FROM books)
ORDER BY b.price DESC;

/* Expected output (4 rows):
+--------------------------------------+-----------+---------------+------------------+
| book_title                           | price     | average_price | above_average_by |
+--------------------------------------+-----------+---------------+------------------+
| The Pragmatic Programmer             | 650000.00 |     246444.44 |        403555.56 |
| Clean Code                           | 590000.00 |     246444.44 |        343555.56 |
| Sapiens: Lược Sử Loài Người          | 299000.00 |     246444.44 |         52555.56 |
| Homo Deus: Lược Sử Tương Lai         | 279000.00 |     246444.44 |         32555.56 |
+--------------------------------------+-----------+---------------+------------------+
*/

-- ------------------------------------------------------------
-- Query 7: Subquery - best-selling author(s)
-- Description: The author(s) with the most units sold (cancelled orders
-- excluded). The HAVING compares with the MAX from a nested subquery instead
-- of using LIMIT 1, so every author tied for first place is returned.
-- ------------------------------------------------------------
SELECT a.author_name      AS author_name,
       SUM(oi.quantity)   AS units_sold,
       SUM(oi.subtotal)   AS revenue
FROM authors AS a
INNER JOIN book_authors AS ba ON ba.author_id = a.author_id
INNER JOIN order_items  AS oi ON oi.book_id = ba.book_id
INNER JOIN orders       AS o  ON o.order_id = oi.order_id
WHERE o.status <> 'cancelled'
GROUP BY a.author_id, a.author_name
HAVING SUM(oi.quantity) = (
    SELECT MAX(author_totals.units)
    FROM (
        SELECT SUM(oi2.quantity) AS units
        FROM book_authors AS ba2
        INNER JOIN order_items AS oi2 ON oi2.book_id = ba2.book_id
        INNER JOIN orders      AS o2  ON o2.order_id = oi2.order_id
        WHERE o2.status <> 'cancelled'
        GROUP BY ba2.author_id
    ) AS author_totals
)
ORDER BY a.author_name;

/* Expected output (2 rows):
+----------------------+------------+-----------+
| author_name          | units_sold | revenue   |
+----------------------+------------+-----------+
| Nguyễn Nhật Ánh      |          6 | 570000.00 |
| Paulo Coelho         |          6 | 470000.00 |
+----------------------+------------+-----------+
*/

-- ------------------------------------------------------------
-- Query 8: HAVING - customers with more than 2 positive reviews
-- Description: Customers who wrote more than 2 reviews rated 3 or higher.
-- WHERE removes low ratings before grouping; HAVING filters the groups.
-- ------------------------------------------------------------
SELECT c.full_name             AS customer_name,
       COUNT(r.review_id)      AS positive_reviews,
       ROUND(AVG(r.rating), 2) AS average_rating
FROM customers AS c
INNER JOIN reviews AS r ON r.customer_id = c.customer_id
WHERE r.rating >= 3
GROUP BY c.customer_id, c.full_name
HAVING COUNT(r.review_id) > 2
ORDER BY positive_reviews DESC, c.full_name;

/* Expected output (1 row):
+------------------+------------------+----------------+
| customer_name    | positive_reviews | average_rating |
+------------------+------------------+----------------+
| Nguyễn Văn An    |                3 |           4.67 |
+------------------+------------------+----------------+
*/

-- ------------------------------------------------------------
-- Query 9: VIEW - v_book_sales_summary
-- Description: A view with one row per book: title, ISBN, publisher, total
-- quantity sold, total revenue, average rating and number of reviews.
-- Sales and reviews are aggregated in separate derived tables before joining,
-- so one does not multiply the other. Missing sales show 0; a book without
-- reviews shows NULL average rating and 0 reviews.
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW v_book_sales_summary AS
SELECT b.title                              AS title,
       b.isbn                               AS isbn,
       p.publisher_name                     AS publisher,
       COALESCE(sales.total_quantity, 0)    AS total_quantity,
       COALESCE(sales.total_revenue, 0)     AS total_revenue,
       ratings.average_rating               AS average_rating,
       COALESCE(ratings.review_count, 0)    AS review_count
FROM books AS b
INNER JOIN publishers AS p ON p.publisher_id = b.publisher_id
LEFT JOIN (
    SELECT oi.book_id,
           SUM(oi.quantity) AS total_quantity,
           SUM(oi.subtotal) AS total_revenue
    FROM order_items AS oi
    INNER JOIN orders AS o ON o.order_id = oi.order_id
    WHERE o.status <> 'cancelled'
    GROUP BY oi.book_id
) AS sales ON sales.book_id = b.book_id
LEFT JOIN (
    SELECT r.book_id,
           ROUND(AVG(r.rating), 2) AS average_rating,
           COUNT(*)                AS review_count
    FROM reviews AS r
    GROUP BY r.book_id
) AS ratings ON ratings.book_id = b.book_id;

SELECT title, isbn, publisher, total_quantity, total_revenue, average_rating, review_count
FROM v_book_sales_summary
ORDER BY total_revenue DESC, title;

/* Expected output (9 rows):
+----------------------------------------+---------------+-------------------+----------------+---------------+----------------+--------------+
| title                                  | isbn          | publisher         | total_quantity | total_revenue | average_rating | review_count |
+----------------------------------------+---------------+-------------------+----------------+---------------+----------------+--------------+
| Clean Code                             | 9780132350884 | Pearson Education |              2 |    1180000.00 |           2.00 |            1 |
| The Pragmatic Programmer               | 9780135957059 | Pearson Education |              1 |     650000.00 |           5.00 |            1 |
| Nhà Giả Kim                            | 9786043150018 | Nhã Nam           |              6 |     470000.00 |           4.50 |            2 |
| Mắt Biếc                               | 9786041190016 | NXB Trẻ           |              3 |     330000.00 |           5.00 |            1 |
| Sapiens: Lược Sử Loài Người            | 9786047700011 | Omega Plus        |              1 |     299000.00 |           5.00 |            1 |
| Đắc Nhân Tâm                           | 9786045800010 | First News        |              3 |     258000.00 |           3.00 |            2 |
| Cho Tôi Xin Một Vé Đi Tuổi Thơ         | 9786041200012 | NXB Trẻ           |              3 |     240000.00 |           5.00 |            1 |
| Dế Mèn Phiêu Lưu Ký                    | 9786042100014 | NXB Kim Đồng      |              3 |     135000.00 |           4.00 |            1 |
| Homo Deus: Lược Sử Tương Lai           | 9786047710010 | Omega Plus        |              0 |          0.00 |           NULL |            0 |
+----------------------------------------+---------------+-------------------+----------------+---------------+----------------+--------------+
*/

-- ------------------------------------------------------------
-- Query 10: Combined - monthly revenue report for the current year
-- Description: Revenue, orders and units for each of the 12 months of the
-- current year (YEAR(CURDATE())), plus a running total. Months with no sales
-- still appear with 0. Techniques: UNION ALL (month list), subquery (derived
-- tables), JOIN, GROUP BY, date functions and a window function.
-- ------------------------------------------------------------
SELECT m.month_no                                                   AS month_no,
       MONTHNAME(MAKEDATE(YEAR(CURDATE()), 1) + INTERVAL (m.month_no - 1) MONTH)
                                                                    AS month_name,
       COALESCE(s.order_count, 0)                                   AS order_count,
       COALESCE(s.units_sold, 0)                                    AS units_sold,
       COALESCE(s.revenue, 0)                                       AS revenue,
       SUM(COALESCE(s.revenue, 0)) OVER (ORDER BY m.month_no)       AS running_total
FROM (
    SELECT 1 AS month_no UNION ALL SELECT 2  UNION ALL SELECT 3  UNION ALL SELECT 4
    UNION ALL SELECT 5   UNION ALL SELECT 6  UNION ALL SELECT 7  UNION ALL SELECT 8
    UNION ALL SELECT 9   UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12
) AS m
LEFT JOIN (
    SELECT MONTH(o.order_date)          AS month_no,
           COUNT(DISTINCT o.order_id)   AS order_count,
           SUM(oi.quantity)             AS units_sold,
           SUM(oi.subtotal)             AS revenue
    FROM orders AS o
    INNER JOIN order_items AS oi ON oi.order_id = o.order_id
    WHERE o.status <> 'cancelled'
      AND YEAR(o.order_date) = YEAR(CURDATE())
    GROUP BY MONTH(o.order_date)
) AS s ON s.month_no = m.month_no
ORDER BY m.month_no;

/* Expected output (12 rows, when run in 2026; other years show only zeros):
+----------+------------+-------------+------------+------------+---------------+
| month_no | month_name | order_count | units_sold | revenue    | running_total |
+----------+------------+-------------+------------+------------+---------------+
|        1 | January    |           1 |          2 |  385000.00 |     385000.00 |
|        2 | February   |           1 |          2 | 1240000.00 |    1625000.00 |
|        3 | March      |           1 |          5 |  330000.00 |    1955000.00 |
|        4 | April      |           0 |          0 |       0.00 |    1955000.00 |
|        5 | May        |           1 |          3 |  268000.00 |    2223000.00 |
|        6 | June       |           0 |          0 |       0.00 |    2223000.00 |
|        7 | July       |           1 |          2 |  665000.00 |    2888000.00 |
|        8 | August     |           0 |          0 |       0.00 |    2888000.00 |
|        9 | September  |           1 |          2 |  172000.00 |    3060000.00 |
|       10 | October    |           1 |          3 |  203000.00 |    3263000.00 |
|       11 | November   |           0 |          0 |       0.00 |    3263000.00 |
|       12 | December   |           0 |          0 |       0.00 |    3263000.00 |
+----------+------------+-------------+------------+------------+---------------+
*/
