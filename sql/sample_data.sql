-- =====================================================
-- sample_data.sql
-- Restaurant Management System
-- Sample data for testing and demonstration
-- =====================================================

USE restaurant_management;

SET SQL_SAFE_UPDATES = 0;
SET FOREIGN_KEY_CHECKS = 0;

DELETE FROM payments;
DELETE FROM invoice_items;
DELETE FROM invoices;
DELETE FROM reservations;
DELETE FROM employees;
DELETE FROM menu_items;
DELETE FROM restaurant_tables;
DELETE FROM customers;

ALTER TABLE payments AUTO_INCREMENT = 1;
ALTER TABLE invoice_items AUTO_INCREMENT = 1;
ALTER TABLE invoices AUTO_INCREMENT = 1;
ALTER TABLE reservations AUTO_INCREMENT = 1;
ALTER TABLE employees AUTO_INCREMENT = 1;
ALTER TABLE menu_items AUTO_INCREMENT = 1;
ALTER TABLE restaurant_tables AUTO_INCREMENT = 1;
ALTER TABLE customers AUTO_INCREMENT = 1;

SET FOREIGN_KEY_CHECKS = 1;

-- =====================================================
-- Insert 10 customers + 1 Guest option
-- =====================================================

INSERT INTO customers (customer_name, phone_number, email, address)
VALUES
('Nguyen Minh Anh', '0901000001', 'minhanh@example.com', 'Ba Dinh, Ha Noi'),
('Tran Hoang Nam', '0901000002', 'hoangnam@example.com', 'Hoan Kiem, Ha Noi'),
('Le Thu Ha', '0901000003', 'thuha@example.com', 'Dong Da, Ha Noi'),
('Pham Gia Bao', '0901000004', 'giabao@example.com', 'Cau Giay, Ha Noi'),
('Hoang Lan Chi', '0901000005', 'lanchi@example.com', 'Hai Ba Trung, Ha Noi'),
('Do Quang Huy', '0901000006', 'quanghuy@example.com', 'Thanh Xuan, Ha Noi'),
('Bui Ngoc Mai', '0901000007', 'ngocmai@example.com', 'Tay Ho, Ha Noi'),
('Dang Tuan Kiet', '0901000008', 'tuankiet@example.com', 'Long Bien, Ha Noi'),
('Vu Phuong Linh', '0901000009', 'phuonglinh@example.com', 'Nam Tu Liem, Ha Noi'),
('Phan Duc Anh', '0901000010', 'ducanh@example.com', 'Bac Tu Liem, Ha Noi'),
('Guest', NULL, NULL, NULL);

-- =====================================================
-- Insert 5 restaurant tables
-- =====================================================

INSERT INTO restaurant_tables (table_number, capacity, status, location)
VALUES
('T01', 2, 'available', 'Indoor'),
('T02', 4, 'available', 'Indoor'),
('T03', 4, 'reserved', 'Indoor'),
('T04', 6, 'available', 'Outdoor'),
('T05', 8, 'occupied', 'VIP Room');

-- =====================================================
-- Insert employees
-- These rows are needed because invoices reference employees
-- =====================================================

INSERT INTO employees (employee_name, role, phone_number, username, password)
VALUES
('Admin User', 'admin', '0912000001', 'admin', 'admin123'),
('Nguyen Van Manager', 'manager', '0912000002', 'manager01', 'manager123'),
('Tran Thu Cashier', 'cashier', '0912000003', 'cashier01', 'cashier123'),
('Le Minh Cashier', 'cashier', '0912000004', 'cashier02', 'cashier123'),
('Pham Quang Waiter', 'waiter', '0912000005', 'waiter01', 'waiter123'),
('Hoang Lan Waiter', 'waiter', '0912000006', 'waiter02', 'waiter123'),
('Do Hai Waiter', 'waiter', '0912000007', 'waiter03', 'waiter123'),
('Bui Mai Waiter', 'waiter', '0912000008', 'waiter04', 'waiter123');

-- =====================================================
-- Insert 10 menu items
-- =====================================================

INSERT INTO menu_items (dish_name, category, price, availability)
VALUES
('Pho Bo', 'Main Dish', 65000.00, TRUE),
('Bun Cha', 'Main Dish', 70000.00, TRUE),
('Com Tam Suon', 'Main Dish', 75000.00, TRUE),
('Mi Xao Bo', 'Main Dish', 80000.00, TRUE),
('Lau Thai', 'Hot Pot', 250000.00, TRUE),
('Bo Luc Lac', 'Main Dish', 150000.00, TRUE),
('Nem Ran', 'Appetizer', 60000.00, TRUE),
('Tra Dao', 'Drink', 35000.00, TRUE),
('Nuoc Cam', 'Drink', 40000.00, TRUE),
('Tiramisu', 'Dessert', 65000.00, TRUE);

-- =====================================================
-- Insert reservations from 2026-05-07 to 2026-05-20
-- Past reservations until 2026-05-13 are only completed or cancelled
-- Completed reservations until 2026-05-13 have matching invoices
-- =====================================================

INSERT INTO reservations (customer_id, table_id, reservation_datetime, guest_count, status, note)
VALUES
(1, 1, '2026-05-07 12:00:00', 2, 'completed', NULL),
(2, 2, '2026-05-07 18:30:00', 4, 'completed', NULL),

(3, 3, '2026-05-08 19:00:00', 4, 'cancelled', 'Customer cancelled'),

(4, 4, '2026-05-09 18:30:00', 5, 'completed', 'Family dinner'),
(11, 5, '2026-05-09 20:00:00', 2, 'completed', NULL),

(5, 1, '2026-05-10 12:30:00', 2, 'cancelled', 'Customer cancelled'),
(6, 2, '2026-05-10 19:00:00', 4, 'completed', NULL),

(7, 3, '2026-05-11 18:00:00', 4, 'completed', NULL),

(8, 4, '2026-05-12 18:30:00', 6, 'completed', NULL),
(9, 5, '2026-05-12 20:00:00', 8, 'cancelled', 'Customer cancelled'),

(10, 1, '2026-05-13 12:00:00', 2, 'completed', NULL),
(1, 2, '2026-05-13 19:00:00', 4, 'cancelled', 'Customer cancelled'),

(2, 3, '2026-05-14 12:30:00', 4, 'confirmed', NULL),
(11, 4, '2026-05-14 19:00:00', 3, 'pending', NULL),

(3, 5, '2026-05-15 18:30:00', 6, 'confirmed', NULL),
(4, 1, '2026-05-16 19:00:00', 2, 'pending', NULL),
(5, 2, '2026-05-17 18:00:00', 4, 'confirmed', NULL),
(6, 3, '2026-05-18 19:30:00', 4, 'pending', NULL),
(7, 4, '2026-05-19 18:30:00', 6, 'confirmed', NULL),
(8, 5, '2026-05-20 19:00:00', 8, 'pending', NULL);

-- =====================================================
-- Insert 20 invoices from 2026-05-07 to 2026-05-14
-- Completed reservations until 2026-05-13 have matching invoices
-- Invoices until 2026-05-13 are paid or cancelled
-- Invoices on 2026-05-14 can be unpaid
-- =====================================================

INSERT INTO invoices (
    customer_id, table_id, employee_id, invoice_datetime,
    subtotal, service_charge, discount, total_amount, status
)
VALUES
(1, 1, 3, '2026-05-07 13:00:00', 0, 0, 0, 0, 'paid'),
(2, 2, 3, '2026-05-07 20:00:00', 0, 0, 10000, 0, 'paid'),
(11, 3, 4, '2026-05-07 21:00:00', 0, 0, 0, 0, 'paid'),

(11, 1, 3, '2026-05-08 12:30:00', 0, 0, 0, 0, 'paid'),
(4, 2, 4, '2026-05-08 18:30:00', 0, 0, 0, 0, 'cancelled'),

(4, 4, 3, '2026-05-09 20:00:00', 0, 0, 15000, 0, 'paid'),
(11, 5, 4, '2026-05-09 21:00:00', 0, 0, 0, 0, 'paid'),
(2, 1, 3, '2026-05-09 21:30:00', 0, 0, 0, 0, 'paid'),

(6, 2, 3, '2026-05-10 20:30:00', 0, 0, 0, 0, 'paid'),
(3, 5, 4, '2026-05-10 21:00:00', 0, 0, 10000, 0, 'paid'),

(7, 3, 3, '2026-05-11 19:30:00', 0, 0, 0, 0, 'paid'),
(11, 4, 4, '2026-05-11 20:00:00', 0, 0, 0, 0, 'cancelled'),

(8, 4, 3, '2026-05-12 20:00:00', 0, 0, 20000, 0, 'paid'),
(10, 2, 4, '2026-05-12 21:00:00', 0, 0, 0, 0, 'paid'),

(10, 1, 3, '2026-05-13 13:00:00', 0, 0, 0, 0, 'paid'),
(5, 3, 4, '2026-05-13 19:30:00', 0, 0, 0, 0, 'cancelled'),

(2, 3, 3, '2026-05-14 13:30:00', 0, 0, 0, 0, 'unpaid'),
(11, 4, 4, '2026-05-14 20:00:00', 0, 0, 0, 0, 'unpaid'),
(7, 1, 3, '2026-05-14 20:30:00', 0, 0, 10000, 0, 'unpaid'),
(8, 5, 4, '2026-05-14 21:00:00', 0, 0, 0, 0, 'unpaid');

-- =====================================================
-- Insert 40 invoice items
-- There are 2 items for each invoice
-- All dish_id values are between 1 and 10
-- =====================================================

INSERT INTO invoice_items (invoice_id, dish_id, quantity, unit_price, line_total)
VALUES
(1, 1, 2, 65000.00, 130000.00),
(1, 8, 2, 35000.00, 70000.00),

(2, 2, 2, 70000.00, 140000.00),
(2, 9, 2, 40000.00, 80000.00),

(3, 3, 1, 75000.00, 75000.00),
(3, 8, 2, 35000.00, 70000.00),

(4, 4, 1, 80000.00, 80000.00),
(4, 9, 1, 40000.00, 40000.00),

(5, 5, 1, 250000.00, 250000.00),
(5, 7, 2, 60000.00, 120000.00),

(6, 6, 2, 150000.00, 300000.00),
(6, 8, 3, 35000.00, 105000.00),

(7, 1, 1, 65000.00, 65000.00),
(7, 10, 2, 65000.00, 130000.00),

(8, 2, 1, 70000.00, 70000.00),
(8, 9, 2, 40000.00, 80000.00),

(9, 3, 2, 75000.00, 150000.00),
(9, 8, 2, 35000.00, 70000.00),

(10, 5, 1, 250000.00, 250000.00),
(10, 10, 1, 65000.00, 65000.00),

(11, 6, 1, 150000.00, 150000.00),
(11, 9, 2, 40000.00, 80000.00),

(12, 4, 1, 80000.00, 80000.00),
(12, 8, 2, 35000.00, 70000.00),

(13, 5, 1, 250000.00, 250000.00),
(13, 7, 3, 60000.00, 180000.00),

(14, 6, 1, 150000.00, 150000.00),
(14, 10, 2, 65000.00, 130000.00),

(15, 1, 2, 65000.00, 130000.00),
(15, 9, 2, 40000.00, 80000.00),

(16, 2, 1, 70000.00, 70000.00),
(16, 8, 1, 35000.00, 35000.00),

(17, 3, 2, 75000.00, 150000.00),
(17, 9, 2, 40000.00, 80000.00),

(18, 4, 1, 80000.00, 80000.00),
(18, 8, 3, 35000.00, 105000.00),

(19, 5, 1, 250000.00, 250000.00),
(19, 10, 2, 65000.00, 130000.00),

(20, 6, 1, 150000.00, 150000.00),
(20, 9, 2, 40000.00, 80000.00);

-- =====================================================
-- Update invoice totals based on invoice_items
-- Formula:
-- subtotal = SUM(line_total)
-- service_charge = subtotal * 5%
-- total_amount = subtotal + service_charge - discount
-- =====================================================

UPDATE invoices i
SET 
    i.subtotal = (
        SELECT COALESCE(SUM(ii.line_total), 0)
        FROM invoice_items ii
        WHERE ii.invoice_id = i.invoice_id
    ),
    i.service_charge = (
        SELECT COALESCE(SUM(ii.line_total), 0) * 0.05
        FROM invoice_items ii
        WHERE ii.invoice_id = i.invoice_id
    ),
    i.total_amount = (
        SELECT COALESCE(SUM(ii.line_total), 0) * 1.05 - i.discount
        FROM invoice_items ii
        WHERE ii.invoice_id = i.invoice_id
    );

-- =====================================================
-- Insert payments for paid invoices
-- amount_paid is taken from invoice total_amount
-- =====================================================

INSERT INTO payments (invoice_id, payment_method, amount_paid, payment_date, payment_status)
SELECT 
    invoice_id,
    CASE 
        WHEN invoice_id % 4 = 0 THEN 'cash'
        WHEN invoice_id % 4 = 1 THEN 'card'
        WHEN invoice_id % 4 = 2 THEN 'bank_transfer'
        ELSE 'e_wallet'
    END AS payment_method,
    total_amount,
    invoice_datetime,
    'completed'
FROM invoices
WHERE status = 'paid';

-- =====================================================
-- Insert pending payments for unpaid invoices
-- =====================================================

INSERT INTO payments (invoice_id, payment_method, amount_paid, payment_date, payment_status)
SELECT 
    invoice_id,
    'cash',
    0,
    invoice_datetime,
    'pending'
FROM invoices
WHERE status = 'unpaid';

-- =====================================================
-- Quick check
-- =====================================================

SELECT 'customers' AS table_name, COUNT(*) AS total_rows FROM customers
UNION ALL
SELECT 'restaurant_tables', COUNT(*) FROM restaurant_tables
UNION ALL
SELECT 'employees', COUNT(*) FROM employees
UNION ALL
SELECT 'menu_items', COUNT(*) FROM menu_items
UNION ALL
SELECT 'reservations', COUNT(*) FROM reservations
UNION ALL
SELECT 'invoices', COUNT(*) FROM invoices
UNION ALL
SELECT 'invoice_items', COUNT(*) FROM invoice_items
UNION ALL
SELECT 'payments', COUNT(*) FROM payments;