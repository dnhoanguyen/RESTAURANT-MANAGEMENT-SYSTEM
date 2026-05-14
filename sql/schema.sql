-- =====================================================
-- schema.sql
-- Restaurant Management System
-- Database: restaurant_management
-- =====================================================

DROP DATABASE IF EXISTS restaurant_management;
CREATE DATABASE restaurant_management;
USE restaurant_management;

-- =====================================================
-- Table 1: customers
-- Stores customer information
-- =====================================================

CREATE TABLE customers (
    customer_id INT AUTO_INCREMENT,
    customer_name VARCHAR(100) NOT NULL,
    phone_number VARCHAR(20) UNIQUE,
    email VARCHAR(100) NULL,
    address VARCHAR(255) NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (customer_id)
);

-- =====================================================
-- Table 2: restaurant_tables
-- Stores restaurant table information and table status
-- =====================================================

CREATE TABLE restaurant_tables (
    table_id INT AUTO_INCREMENT,
    table_number VARCHAR(20) NOT NULL,
    capacity INT NOT NULL,
    status ENUM('available', 'reserved', 'occupied') DEFAULT 'available',
    location VARCHAR(50) NULL,

    PRIMARY KEY (table_id),
    UNIQUE (table_number),
    CHECK (capacity > 0)
);

-- =====================================================
-- Table 3: menu_items
-- Stores food and drink menu information
-- =====================================================

CREATE TABLE menu_items (
    dish_id INT AUTO_INCREMENT,
    dish_name VARCHAR(100) NOT NULL,
    category VARCHAR(50) NULL,
    price DECIMAL(10,2) NOT NULL,
    availability BOOLEAN DEFAULT TRUE,

    PRIMARY KEY (dish_id),
    CHECK (price >= 0)
);

-- =====================================================
-- Table 4: employees
-- Stores employee information and system roles
-- =====================================================

CREATE TABLE employees (
    employee_id INT AUTO_INCREMENT,
    employee_name VARCHAR(100) NOT NULL,
    role ENUM('admin', 'manager', 'cashier', 'waiter') NOT NULL,
    phone_number VARCHAR(20) NULL,
    username VARCHAR(50) UNIQUE,
    password VARCHAR(255) NOT NULL,

    PRIMARY KEY (employee_id)
);

-- =====================================================
-- Table 5: reservations
-- Stores table reservation information
-- =====================================================

CREATE TABLE reservations (
    reservation_id INT AUTO_INCREMENT,
    customer_id INT NOT NULL,
    table_id INT NOT NULL,
    reservation_datetime DATETIME NOT NULL,
    guest_count INT NOT NULL,
    status ENUM('pending', 'confirmed', 'cancelled', 'completed') DEFAULT 'pending',
    note VARCHAR(255) NULL,

    PRIMARY KEY (reservation_id),

    CONSTRAINT fk_reservations_customers
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_reservations_restaurant_tables
        FOREIGN KEY (table_id)
        REFERENCES restaurant_tables(table_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CHECK (guest_count > 0)
);

-- =====================================================
-- Table 6: invoices
-- Stores invoice and billing information
-- =====================================================

CREATE TABLE invoices (
    invoice_id INT AUTO_INCREMENT,
    customer_id INT NOT NULL,
    table_id INT NOT NULL,
    employee_id INT NOT NULL,
    invoice_datetime DATETIME DEFAULT CURRENT_TIMESTAMP,
    subtotal DECIMAL(10,2) DEFAULT 0,
    service_charge DECIMAL(10,2) DEFAULT 0,
    discount DECIMAL(10,2) DEFAULT 0,
    total_amount DECIMAL(10,2) DEFAULT 0,
    status ENUM('unpaid', 'paid', 'cancelled') DEFAULT 'unpaid',

    PRIMARY KEY (invoice_id),

    CONSTRAINT fk_invoices_customers
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_invoices_restaurant_tables
        FOREIGN KEY (table_id)
        REFERENCES restaurant_tables(table_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_invoices_employees
        FOREIGN KEY (employee_id)
        REFERENCES employees(employee_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CHECK (subtotal >= 0),
    CHECK (service_charge >= 0),
    CHECK (discount >= 0),
    CHECK (total_amount >= 0)
);

-- =====================================================
-- Table 7: invoice_items
-- Stores detailed dishes in each invoice
-- =====================================================

CREATE TABLE invoice_items (
    invoice_item_id INT AUTO_INCREMENT,
    invoice_id INT NOT NULL,
    dish_id INT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    line_total DECIMAL(10,2) DEFAULT 0,

    PRIMARY KEY (invoice_item_id),

    CONSTRAINT fk_invoice_items_invoices
        FOREIGN KEY (invoice_id)
        REFERENCES invoices(invoice_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT fk_invoice_items_menu_items
        FOREIGN KEY (dish_id)
        REFERENCES menu_items(dish_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CHECK (quantity > 0),
    CHECK (unit_price >= 0),
    CHECK (line_total >= 0)
);

-- =====================================================
-- Table 8: payments
-- Stores payment information for invoices
-- =====================================================

CREATE TABLE payments (
    payment_id INT AUTO_INCREMENT,
    invoice_id INT NOT NULL,
    payment_method ENUM('cash', 'card', 'bank_transfer', 'e_wallet') NOT NULL,
    amount_paid DECIMAL(10,2) NOT NULL,
    payment_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    payment_status ENUM('pending', 'completed', 'refunded') DEFAULT 'pending',

    PRIMARY KEY (payment_id),

    CONSTRAINT fk_payments_invoices
        FOREIGN KEY (invoice_id)
        REFERENCES invoices(invoice_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CHECK (amount_paid >= 0)
);


-- =====================================================
-- Check all created tables
-- =====================================================

SHOW TABLES;