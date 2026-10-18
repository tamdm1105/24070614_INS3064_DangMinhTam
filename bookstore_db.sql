-- =============================================================================
-- Student    : Dang Minh Tam
-- Student ID : 24070614
-- Assignment : INS3064 - Homework 6: Database Design (Online Bookstore)
-- Date       : 2026-10-18
--
-- WARNING: this script DROPs and recreates the database `bookstore_db`.
-- Run it only on a practice/homework MySQL server (MySQL 8.0.16+ for CHECK).
-- It is safe to run repeatedly: every run rebuilds the same schema and data.
-- =============================================================================

-- =============================================================================
-- NORMALIZATION (3NF)
--
-- 1NF - every column holds one atomic value and there are no repeating groups:
--   a book with two authors or three categories gets two/three rows in the
--   junction tables book_authors / book_categories, never a list in one column.
--
-- 2NF - no non-key column depends on only part of a composite key:
--   book_authors (book_id, author_id) and book_categories (book_id, category_id)
--   have composite keys and no other columns. Every other table has a single
--   surrogate key, so partial dependencies are impossible.
--
-- 3NF - no non-key column depends on another non-key column:
--   * books stores only publisher_id; the publisher's name/address/website live
--     once in publishers (no book -> publisher -> address transitive chain).
--   * orders stores only customer_id; the customer's name/email live in customers.
--   * order_items stores only book_id; the title/ISBN live in books.
--
-- Columns that look repeated but are NOT redundant (they record a fact at a
-- point in time and must not change when the source row changes later):
--   * order_items.unit_price   - price actually charged, books.price may change.
--   * orders.shipping_address  - where this order went, the customer may move.
--   * orders.total_amount      - amount charged for the order (kept for history).
--   * order_items.subtotal     - a GENERATED column (quantity * unit_price), so
--                                MySQL computes it and it can never disagree.
-- =============================================================================

-- Read this file as UTF-8 so Vietnamese text is stored correctly on any client.
SET NAMES utf8mb4;

DROP DATABASE IF EXISTS bookstore_db;
CREATE DATABASE bookstore_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE bookstore_db;

-- Drop tables child-first so foreign keys never block a drop
-- (redundant after DROP DATABASE, kept so the file also works on its own).
DROP TABLE IF EXISTS reviews;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS book_categories;
DROP TABLE IF EXISTS book_authors;
DROP TABLE IF EXISTS books;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS publishers;
DROP TABLE IF EXISTS authors;

-- -----------------------------------------------------------------------------
-- authors: people who write books (M:N with books via book_authors)
-- -----------------------------------------------------------------------------
CREATE TABLE authors (
    author_id   INT          NOT NULL AUTO_INCREMENT,               -- surrogate key
    author_name VARCHAR(100) NOT NULL,
    nationality VARCHAR(50)  NULL,                                  -- optional
    birth_date  DATE         NULL,                                  -- optional
    biography   TEXT         NULL,                                  -- free text, optional
    created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (author_id)
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- publishers: publishing houses (1:N with books)
-- -----------------------------------------------------------------------------
CREATE TABLE publishers (
    publisher_id   INT          NOT NULL AUTO_INCREMENT,
    publisher_name VARCHAR(100) NOT NULL,
    address        VARCHAR(255) NULL,
    website        VARCHAR(255) NULL,
    created_at     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (publisher_id),
    UNIQUE KEY uq_publishers_name (publisher_name)
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- categories: genres; parent_category_id makes sub-genres (self reference)
-- -----------------------------------------------------------------------------
CREATE TABLE categories (
    category_id        INT          NOT NULL AUTO_INCREMENT,
    category_name      VARCHAR(100) NOT NULL,
    description        TEXT         NULL,
    parent_category_id INT          NULL,                           -- NULL = top-level genre
    PRIMARY KEY (category_id),
    UNIQUE KEY uq_categories_name (category_name),
    -- SET NULL: deleting a parent genre turns its sub-genres into top-level genres.
    CONSTRAINT fk_categories_parent FOREIGN KEY (parent_category_id)
        REFERENCES categories (category_id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- books: the catalogue; every book has exactly one publisher
-- -----------------------------------------------------------------------------
CREATE TABLE books (
    book_id          INT           NOT NULL AUTO_INCREMENT,
    isbn             VARCHAR(13)   NOT NULL,                        -- ISBN-13, digits only
    title            VARCHAR(255)  NOT NULL,
    publisher_id     INT           NOT NULL,
    price            DECIMAL(10,2) NOT NULL,                        -- current selling price (VND)
    stock_quantity   INT           NOT NULL DEFAULT 0,
    publication_date DATE          NULL,
    page_count       INT           NULL,
    language         VARCHAR(30)   NOT NULL DEFAULT 'Vietnamese',
    description      TEXT          NULL,
    created_at       DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (book_id),
    UNIQUE KEY uq_books_isbn (isbn),                               -- one row per edition
    CONSTRAINT chk_books_isbn  CHECK (isbn REGEXP '^[0-9]{13}$'),
    CONSTRAINT chk_books_price CHECK (price > 0),
    CONSTRAINT chk_books_stock CHECK (stock_quantity >= 0),
    CONSTRAINT chk_books_pages CHECK (page_count IS NULL OR page_count > 0),
    -- RESTRICT: a publisher that still has books cannot be deleted.
    CONSTRAINT fk_books_publisher FOREIGN KEY (publisher_id)
        REFERENCES publishers (publisher_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- book_authors: junction table, books <-> authors (M:N)
-- -----------------------------------------------------------------------------
CREATE TABLE book_authors (
    book_id   INT NOT NULL,
    author_id INT NOT NULL,
    PRIMARY KEY (book_id, author_id),                              -- composite key, no duplicate pair
    -- CASCADE: deleting a book removes its author links (dependent rows).
    CONSTRAINT fk_book_authors_book FOREIGN KEY (book_id)
        REFERENCES books (book_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    -- RESTRICT: an author who still has books in the catalogue cannot be deleted.
    CONSTRAINT fk_book_authors_author FOREIGN KEY (author_id)
        REFERENCES authors (author_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- book_categories: junction table, books <-> categories (M:N)
-- -----------------------------------------------------------------------------
CREATE TABLE book_categories (
    book_id     INT NOT NULL,
    category_id INT NOT NULL,
    PRIMARY KEY (book_id, category_id),
    -- CASCADE on both sides: the link is only a tag and means nothing on its own.
    CONSTRAINT fk_book_categories_book FOREIGN KEY (book_id)
        REFERENCES books (book_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_book_categories_category FOREIGN KEY (category_id)
        REFERENCES categories (category_id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- customers: registered shoppers (passwords are stored only as hashes)
-- -----------------------------------------------------------------------------
CREATE TABLE customers (
    customer_id   INT          NOT NULL AUTO_INCREMENT,
    full_name     VARCHAR(100) NOT NULL,
    email         VARCHAR(100) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,                            -- bcrypt hash, never plain text
    phone         VARCHAR(20)  NULL,
    address       VARCHAR(255) NULL,                                -- default address
    created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (customer_id),
    UNIQUE KEY uq_customers_email (email),                         -- one account per email
    CONSTRAINT chk_customers_email CHECK (email LIKE '%_@_%._%')
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- orders: one checkout by one customer (1:N customers -> orders)
-- -----------------------------------------------------------------------------
CREATE TABLE orders (
    order_id         INT           NOT NULL AUTO_INCREMENT,
    customer_id      INT           NOT NULL,
    order_date       DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status           ENUM('pending', 'processing', 'shipped', 'delivered', 'cancelled')
                                   NOT NULL DEFAULT 'pending',
    total_amount     DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    shipping_address VARCHAR(255)  NOT NULL,                        -- snapshot for this order
    PRIMARY KEY (order_id),
    CONSTRAINT chk_orders_total CHECK (total_amount >= 0),
    -- RESTRICT: a customer with order history cannot be deleted (sales records stay).
    CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id)
        REFERENCES customers (customer_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- order_items: lines of an order; links orders <-> books (M:N)
-- -----------------------------------------------------------------------------
CREATE TABLE order_items (
    order_item_id INT           NOT NULL AUTO_INCREMENT,
    order_id      INT           NOT NULL,
    book_id       INT           NOT NULL,
    quantity      INT           NOT NULL DEFAULT 1,
    unit_price    DECIMAL(10,2) NOT NULL,                           -- price at purchase time
    subtotal      DECIMAL(12,2) AS (quantity * unit_price) STORED,  -- computed by MySQL
    PRIMARY KEY (order_item_id),
    UNIQUE KEY uq_order_items_order_book (order_id, book_id),      -- one line per book per order
    CONSTRAINT chk_order_items_quantity CHECK (quantity > 0),
    CONSTRAINT chk_order_items_price    CHECK (unit_price > 0),
    -- CASCADE: deleting an order deletes its items.
    CONSTRAINT fk_order_items_order FOREIGN KEY (order_id)
        REFERENCES orders (order_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    -- RESTRICT: a book that has been sold cannot be deleted.
    CONSTRAINT fk_order_items_book FOREIGN KEY (book_id)
        REFERENCES books (book_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- reviews: a customer rates a book 1-5 (1:N from both customers and books)
-- -----------------------------------------------------------------------------
CREATE TABLE reviews (
    review_id   INT      NOT NULL AUTO_INCREMENT,
    book_id     INT      NOT NULL,
    customer_id INT      NOT NULL,
    rating      INT      NOT NULL,
    comment     TEXT     NULL,
    review_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (review_id),
    UNIQUE KEY uq_reviews_book_customer (book_id, customer_id),    -- one review per book per customer
    CONSTRAINT chk_reviews_rating CHECK (rating BETWEEN 1 AND 5),
    -- CASCADE on both sides: a review has no meaning without its book or customer.
    CONSTRAINT fk_reviews_book FOREIGN KEY (book_id)
        REFERENCES books (book_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_reviews_customer FOREIGN KEY (customer_id)
        REFERENCES customers (customer_id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- =============================================================================
-- SAMPLE DATA (parents first, explicit ids so foreign keys are easy to follow)
-- =============================================================================

INSERT INTO authors (author_id, author_name, nationality, birth_date, biography) VALUES
(1, 'Nguyễn Nhật Ánh',   'Vietnamese', '1955-05-07', 'Nhà văn nổi tiếng với các tác phẩm về tuổi học trò.'),
(2, 'Tô Hoài',           'Vietnamese', '1920-09-27', 'Tác giả của Dế Mèn Phiêu Lưu Ký.'),
(3, 'Paulo Coelho',      'Brazilian',  '1947-08-24', 'Novelist best known for The Alchemist.'),
(4, 'Yuval Noah Harari', 'Israeli',    '1976-02-24', 'Historian and author of Sapiens and Homo Deus.'),
(5, 'Dale Carnegie',     'American',   '1888-11-24', 'Writer and lecturer on self-improvement.'),
(6, 'Andrew Hunt',       'American',   NULL,         'Co-author of The Pragmatic Programmer.'),
(7, 'David Thomas',      'British',    NULL,         'Co-author of The Pragmatic Programmer.'),
(8, 'Robert C. Martin',  'American',   '1952-12-05', 'Software engineer known as Uncle Bob.');

INSERT INTO publishers (publisher_id, publisher_name, address, website) VALUES
(1, 'NXB Trẻ',           '161B Lý Chính Thắng, Quận 3, TP. Hồ Chí Minh', 'https://www.nxbtre.com.vn'),
(2, 'NXB Kim Đồng',      '55 Quang Trung, Hai Bà Trưng, Hà Nội',        'https://nxbkimdong.com.vn'),
(3, 'Nhã Nam',           '59 Đỗ Quang, Cầu Giấy, Hà Nội',               'https://nhanam.vn'),
(4, 'Omega Plus',        'Thanh Xuân, Hà Nội',                          'https://omegaplus.vn'),
(5, 'First News',        '11H Nguyễn Thị Minh Khai, Quận 1, TP. Hồ Chí Minh', 'https://firstnews.com.vn'),
(6, 'Pearson Education', '221 River Street, Hoboken, NJ, USA',          'https://www.pearson.com');

INSERT INTO categories (category_id, category_name, description, parent_category_id) VALUES
(1, 'Literature',  'Fiction and literary works',              NULL),
(2, 'Children',    'Books for children and young readers',    NULL),
(3, 'Novel',       'Long-form fiction (sub-genre of Literature)', 1),
(4, 'Self-help',   'Personal development and life skills',    NULL),
(5, 'Non-fiction', 'Factual books',                           NULL),
(6, 'History',     'History of people and civilizations (sub-genre of Non-fiction)', 5),
(7, 'Computing',   'Software engineering and programming',    NULL);

INSERT INTO books (book_id, isbn, title, publisher_id, price, stock_quantity, publication_date, page_count, language) VALUES
(1, '9786041190016', 'Mắt Biếc',                          1, 110000.00, 40, '2019-06-01', 300, 'Vietnamese'),
(2, '9786041200012', 'Cho Tôi Xin Một Vé Đi Tuổi Thơ',    1,  80000.00, 35, '2018-03-15', 220, 'Vietnamese'),
(3, '9786042100014', 'Dế Mèn Phiêu Lưu Ký',               2,  45000.00, 60, '2020-05-20', 144, 'Vietnamese'),
(4, '9786043150018', 'Nhà Giả Kim',                       3,  79000.00, 25, '2020-01-10', 228, 'Vietnamese'),
(5, '9786047700011', 'Sapiens: Lược Sử Loài Người',       4, 299000.00, 15, '2021-08-01', 560, 'Vietnamese'),
(6, '9786047710010', 'Homo Deus: Lược Sử Tương Lai',      4, 279000.00, 10, '2022-02-01', 520, 'Vietnamese'),
(7, '9786045800010', 'Đắc Nhân Tâm',                      5,  86000.00, 80, '2016-09-01', 320, 'Vietnamese'),
(8, '9780135957059', 'The Pragmatic Programmer',          6, 650000.00,  5, '2019-09-13', 352, 'English'),
(9, '9780132350884', 'Clean Code',                        6, 590000.00,  0, '2008-08-01', 464, 'English');

-- Book 8 has two authors: one book, two rows (M:N).
INSERT INTO book_authors (book_id, author_id) VALUES
(1, 1), (2, 1), (3, 2), (4, 3), (5, 4), (6, 4), (7, 5), (8, 6), (8, 7), (9, 8);

-- Books 2, 3 and 5 belong to two categories each (M:N).
INSERT INTO book_categories (book_id, category_id) VALUES
(1, 3), (2, 3), (2, 2), (3, 2), (3, 1), (4, 3), (5, 5), (5, 6), (6, 5), (7, 4), (8, 7), (9, 7);

-- Sample bcrypt-format hashes only (not real passwords).
INSERT INTO customers (customer_id, full_name, email, password_hash, phone, address) VALUES
(1, 'Nguyễn Văn An',   'an.nguyen@example.com',   '$2y$10$Q9mXz1vKp3Lr7TnB2cYd5eWf8gHj0kLm4nOp6qRs9tUv1wXy3zA5b', '0901234561', '12 Trần Duy Hưng, Cầu Giấy, Hà Nội'),
(2, 'Trần Thị Bình',   'binh.tran@example.com',   '$2y$10$R1nYa2wLq4Ms8UoC3dZe6fXg9hIk1lMn5oPq7rSt0uVw2xYz4aB6c', '0901234562', '45 Lê Lợi, Quận 1, TP. Hồ Chí Minh'),
(3, 'Lê Hoàng Cường',  'cuong.le@example.com',    '$2y$10$S2oZb3xMr5Nt9VpD4eAf7gYh0iJl2mNo6pQr8sTu1vWx3yZa5bC7d', '0901234563', '78 Bạch Đằng, Hải Châu, Đà Nẵng'),
(4, 'Phạm Thu Dung',   'dung.pham@example.com',   '$2y$10$T3pAc4yNs6Ou0WqE5fBg8hZi1jKm3nOp7qRs9tUv2wXy4zAb6cD8e', '0901234564', '23 Lạch Tray, Ngô Quyền, Hải Phòng'),
(5, 'Hoàng Minh Đức',  'duc.hoang@example.com',   '$2y$10$U4qBd5zOt7Pv1XrF6gCh9iAj2kLn4oPq8rSt0uVw3xYz5aBc7dE9f', '0901234565', '9 Hòa Bình, Ninh Kiều, Cần Thơ'),
(6, 'Vũ Ngọc Hà',      'ha.vu@example.com',       '$2y$10$V5rCe6aPu8Qw2YsG7hDi0jBk3lMo5pQr9sTu1vWx4yZa6bCd8eF0g', NULL,         '3 Lê Lợi, TP. Huế');

-- total_amount = sum of the order's item subtotals. Customer 6 has no orders.
INSERT INTO orders (order_id, customer_id, order_date, status, total_amount, shipping_address) VALUES
(1, 1, '2025-12-20 09:15:00', 'delivered',   299000.00, '12 Trần Duy Hưng, Cầu Giấy, Hà Nội'),
(2, 2, '2026-01-15 14:30:00', 'delivered',   385000.00, '45 Lê Lợi, Quận 1, TP. Hồ Chí Minh'),
(3, 1, '2026-02-03 20:05:00', 'delivered',  1240000.00, '144 Xuân Thủy, Cầu Giấy, Hà Nội'),
(4, 3, '2026-03-22 10:45:00', 'delivered',   330000.00, '78 Bạch Đằng, Hải Châu, Đà Nẵng'),
(5, 4, '2026-05-10 16:20:00', 'delivered',   268000.00, '23 Lạch Tray, Ngô Quyền, Hải Phòng'),
(6, 2, '2026-07-08 11:00:00', 'delivered',   665000.00, '45 Lê Lợi, Quận 1, TP. Hồ Chí Minh'),
(7, 5, '2026-08-19 08:40:00', 'cancelled',   598000.00, '9 Hòa Bình, Ninh Kiều, Cần Thơ'),
(8, 3, '2026-09-25 19:10:00', 'shipped',     172000.00, '78 Bạch Đằng, Hải Châu, Đà Nẵng'),
(9, 1, '2026-10-12 21:30:00', 'pending',     203000.00, '12 Trần Duy Hưng, Cầu Giấy, Hà Nội');

-- 16 items. Order 6 bought book 4 on sale (75,000 instead of 79,000).
INSERT INTO order_items (order_id, book_id, quantity, unit_price) VALUES
(1, 1, 2, 110000.00), (1, 4, 1,  79000.00),
(2, 7, 1,  86000.00), (2, 5, 1, 299000.00),
(3, 8, 1, 650000.00), (3, 9, 1, 590000.00),
(4, 2, 3,  80000.00), (4, 3, 2,  45000.00),
(5, 4, 2,  79000.00), (5, 1, 1, 110000.00),
(6, 4, 1,  75000.00), (6, 9, 1, 590000.00),
(7, 5, 2, 299000.00),
(8, 7, 2,  86000.00),
(9, 3, 1,  45000.00), (9, 4, 2,  79000.00);

-- Customers only review books they bought. Book 6 has no reviews yet.
INSERT INTO reviews (book_id, customer_id, rating, comment, review_date) VALUES
(1, 1, 5, 'Truyện rất cảm động, đọc lại nhiều lần vẫn thích.',  '2025-12-28 20:00:00'),
(4, 1, 4, 'Sách hay, bản dịch dễ đọc.',                          '2025-12-30 21:15:00'),
(8, 1, 5, 'Must-read for every developer.',                      '2026-02-20 22:00:00'),
(9, 1, 2, 'Useful ideas but some examples feel dated.',          '2026-02-25 22:30:00'),
(7, 2, 4, 'Nhiều bài học giao tiếp thực tế.',                    '2026-01-25 09:00:00'),
(5, 2, 5, 'Góc nhìn mới về lịch sử loài người.',                 '2026-02-10 10:30:00'),
(2, 3, 5, 'Gợi lại nhiều kỷ niệm tuổi thơ.',                     '2026-04-01 18:00:00'),
(3, 3, 4, 'Con tôi rất thích đọc.',                              '2026-04-02 18:30:00'),
(7, 3, 2, 'Nội dung hơi lặp lại.',                               '2026-10-05 19:00:00'),
(4, 4, 5, 'Một cuốn sách truyền cảm hứng.',                      '2026-05-20 15:45:00');
