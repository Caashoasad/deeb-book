
-- ==========================================
-- DEEB BOOK LIBRARY MANAGEMENT SYSTEM
-- Complete MySQL Database
-- ==========================================

CREATE DATABASE IF NOT EXISTS deeb_book
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE deeb_book;

-- ==========================================
-- 1. USERS TABLE
-- Admin, Librarian, and Member accounts
-- ==========================================

CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    role ENUM('admin', 'librarian', 'member')
        NOT NULL DEFAULT 'member',
    status ENUM('active', 'inactive')
        NOT NULL DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ==========================================
-- 2. MEMBERS TABLE
-- Library member information
-- ==========================================

CREATE TABLE members (
    member_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NULL UNIQUE,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE,
    phone VARCHAR(25),
    address VARCHAR(255),
    registration_date DATE NOT NULL,
    membership_status ENUM('active', 'inactive')
        NOT NULL DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_members_user
        FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ==========================================
-- 3. CATEGORIES TABLE
-- ==========================================

CREATE TABLE categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ==========================================
-- 4. BOOKS TABLE
-- ==========================================

CREATE TABLE books (
    book_id INT AUTO_INCREMENT PRIMARY KEY,
    isbn VARCHAR(20) UNIQUE,
    title VARCHAR(200) NOT NULL,
    author VARCHAR(150) NOT NULL,
    category_id INT,
    publisher VARCHAR(150),
    publication_year YEAR,
    cover_image VARCHAR(255),
    shelf_location VARCHAR(100),
    total_copies INT NOT NULL DEFAULT 1,
    available_copies INT NOT NULL DEFAULT 1,
    description TEXT,
    date_added TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_total_copies
        CHECK (total_copies >= 0),

    CONSTRAINT chk_available_copies
        CHECK (
            available_copies >= 0
            AND available_copies <= total_copies
        ),

    CONSTRAINT fk_books_category
        FOREIGN KEY (category_id)
        REFERENCES categories(category_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE,

    INDEX idx_books_title (title),
    INDEX idx_books_author (author)
) ENGINE=InnoDB;

-- ==========================================
-- 5. BORROWINGS TABLE
-- Book borrowing and return records
-- ==========================================

CREATE TABLE borrowings (
    borrowing_id INT AUTO_INCREMENT PRIMARY KEY,
    member_id INT NOT NULL,
    book_id INT NOT NULL,
    issued_by INT NULL,
    borrowing_date DATE NOT NULL,
    due_date DATE NOT NULL,
    return_date DATE NULL,
    status ENUM('borrowed', 'returned', 'overdue')
        NOT NULL DEFAULT 'borrowed',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_borrowing_dates
        CHECK (due_date >= borrowing_date),

    CONSTRAINT chk_return_date
        CHECK (
            return_date IS NULL
            OR return_date >= borrowing_date
        ),

    CONSTRAINT fk_borrowings_member
        FOREIGN KEY (member_id)
        REFERENCES members(member_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT fk_borrowings_book
        FOREIGN KEY (book_id)
        REFERENCES books(book_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT fk_borrowings_user
        FOREIGN KEY (issued_by)
        REFERENCES users(user_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE,

    INDEX idx_borrowings_member (member_id),
    INDEX idx_borrowings_book (book_id),
    INDEX idx_borrowings_due_date (due_date),
    INDEX idx_borrowings_status (status)
) ENGINE=InnoDB;

-- ==========================================
-- 6. FINES TABLE
-- Overdue fines and fine status
-- ==========================================

CREATE TABLE fines (
    fine_id INT AUTO_INCREMENT PRIMARY KEY,
    borrowing_id INT NOT NULL UNIQUE,
    fine_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    paid_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    fine_status ENUM('unpaid', 'partial', 'paid', 'waived')
        NOT NULL DEFAULT 'unpaid',
    reason VARCHAR(255),
    waived_by INT NULL,
    waived_at DATETIME NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_fine_amount
        CHECK (fine_amount >= 0),

    CONSTRAINT chk_paid_amount
        CHECK (
            paid_amount >= 0
            AND paid_amount <= fine_amount
        ),

    CONSTRAINT fk_fines_borrowing
        FOREIGN KEY (borrowing_id)
        REFERENCES borrowings(borrowing_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT fk_fines_waived_by
        FOREIGN KEY (waived_by)
        REFERENCES users(user_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ==========================================
-- 7. FINE PAYMENTS TABLE
-- Payment history for fines
-- ==========================================

CREATE TABLE fine_payments (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    fine_id INT NOT NULL,
    received_by INT NULL,
    amount DECIMAL(10,2) NOT NULL,
    payment_method ENUM(
        'cash',
        'mobile_money',
        'bank_transfer',
        'other'
    ) NOT NULL DEFAULT 'cash',
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    reference_number VARCHAR(100),
    notes TEXT,

    CONSTRAINT chk_payment_amount
        CHECK (amount > 0),

    CONSTRAINT fk_payments_fine
        FOREIGN KEY (fine_id)
        REFERENCES fines(fine_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT fk_payments_user
        FOREIGN KEY (received_by)
        REFERENCES users(user_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE,

    INDEX idx_payments_fine (fine_id)
) ENGINE=InnoDB;

-- ==========================================
-- 8. ACTIVITY LOGS TABLE
-- Record important system activities
-- ==========================================

CREATE TABLE activity_logs (
    log_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NULL,
    action VARCHAR(100) NOT NULL,
    description TEXT,
    ip_address VARCHAR(45),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_logs_user
        FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE,

    INDEX idx_logs_created_at (created_at),
    INDEX idx_logs_user (user_id)
) ENGINE=InnoDB;

-- ==========================================
-- SAMPLE DATA
-- ==========================================

INSERT INTO categories (category_name, description)
VALUES
('Computer Science', 'Programming and IT books'),
('Business', 'Business and management books'),
('Education', 'Learning and teaching materials'),
('Literature', 'Novels and literary works'),
('Science', 'Science and research books');

INSERT INTO books (
    isbn, title, author, category_id,
    publisher, publication_year, shelf_location,
    total_copies, available_copies, description
)
VALUES
(
    '9780131103627',
    'The C Programming Language',
    'Brian W. Kernighan and Dennis M. Ritchie',
    1, 'Prentice Hall', 1988, 'A-01', 5, 5,
    'A classic introduction to the C programming language.'
),
(
    '9780132350884',
    'Clean Code',
    'Robert C. Martin',
    1, 'Prentice Hall', 2008, 'A-02', 4, 4,
    'A guide to writing readable and maintainable code.'
),
(
    '9780134685991',
    'Effective Java',
    'Joshua Bloch',
    1, 'Addison-Wesley', 2018, 'A-03', 3, 3,
    'Best practices for Java programming.'
),
(
    '9780061120084',
    'To Kill a Mockingbird',
    'Harper Lee',
    4, 'Harper Perennial', 2006, 'D-01', 6, 6,
    'A classic novel about justice and morality.'
);

INSERT INTO members (
    full_name, email, phone, address, registration_date
)
VALUES
(
    'Ahmed Ali',
    'ahmed@example.com',
    '+252900000001',
    'Bosaso, Puntland',
    '2026-10-01'
),
(
    'Fatima Hassan',
    'fatima@example.com',
    '+252900000002',
    'Bosaso, Puntland',
    '2026-10-05'
);

-- ==========================================
-- VERIFY TABLES
-- ==========================================

SHOW TABLES;

SELECT * FROM categories;
SELECT * FROM books;
SELECT * FROM members;
