-- =====================================================
-- advanced_objects.sql
-- Restaurant Management System
-- Includes indexes, views, stored procedures, functions, and triggers
-- =====================================================

USE restaurant_management;

-- =====================================================
-- 1. INDEXES
-- Purpose: improve performance for common searches, filters, and joins
-- =====================================================

CREATE INDEX idx_customers_phone_number
ON customers(phone_number);

CREATE INDEX idx_menu_items_dish_name
ON menu_items(dish_name);

CREATE INDEX idx_menu_items_category
ON menu_items(category);

CREATE INDEX idx_restaurant_tables_status
ON restaurant_tables(status);

CREATE INDEX idx_reservations_datetime
ON reservations(reservation_datetime);

CREATE INDEX idx_reservations_customer_id
ON reservations(customer_id);

CREATE INDEX idx_reservations_table_id
ON reservations(table_id);

CREATE INDEX idx_invoices_datetime
ON invoices(invoice_datetime);

CREATE INDEX idx_invoices_status
ON invoices(status);

CREATE INDEX idx_invoices_customer_id
ON invoices(customer_id);

CREATE INDEX idx_invoices_table_id
ON invoices(table_id);

CREATE INDEX idx_invoices_employee_id
ON invoices(employee_id);

CREATE INDEX idx_invoice_items_invoice_id
ON invoice_items(invoice_id);

CREATE INDEX idx_invoice_items_dish_id
ON invoice_items(dish_id);

CREATE INDEX idx_payments_invoice_id
ON payments(invoice_id);

CREATE INDEX idx_payments_status
ON payments(payment_status);

-- =====================================================
-- 2. VIEWS
-- Purpose: simplify reporting and repeated queries
-- =====================================================

DROP VIEW IF EXISTS vw_table_availability;
DROP VIEW IF EXISTS vw_daily_bookings;
DROP VIEW IF EXISTS vw_invoice_details;
DROP VIEW IF EXISTS vw_top_selling_dishes;
DROP VIEW IF EXISTS vw_daily_revenue;
DROP VIEW IF EXISTS vw_customer_visit_summary;

-- -----------------------------------------------------
-- View 1: available tables
-- Shows tables that are currently available
-- -----------------------------------------------------

CREATE OR REPLACE VIEW vw_table_availability AS
SELECT
    table_id,
    table_number,
    capacity,
    status,
    location
FROM restaurant_tables
WHERE status = 'available';

-- -----------------------------------------------------
-- View 2: daily bookings
-- Counts reservations by date
-- -----------------------------------------------------

CREATE OR REPLACE VIEW vw_daily_bookings AS
SELECT
    DATE(reservation_datetime) AS booking_date,
    COUNT(*) AS total_bookings,
    SUM(guest_count) AS total_guests
FROM reservations
GROUP BY DATE(reservation_datetime);

-- -----------------------------------------------------
-- View 3: invoice details
-- Shows invoice information with customer, table, and employee details
-- -----------------------------------------------------

CREATE OR REPLACE VIEW vw_invoice_details AS
SELECT
    i.invoice_id,
    i.invoice_datetime,
    c.customer_id,
    c.customer_name,
    rt.table_number,
    e.employee_name,
    e.role AS employee_role,
    i.subtotal,
    i.service_charge,
    i.discount,
    i.total_amount,
    i.status
FROM invoices i
JOIN customers c
    ON i.customer_id = c.customer_id
JOIN restaurant_tables rt
    ON i.table_id = rt.table_id
JOIN employees e
    ON i.employee_id = e.employee_id;

-- -----------------------------------------------------
-- View 4: top-selling dishes
-- Reports dish sales quantity and revenue
-- -----------------------------------------------------

CREATE OR REPLACE VIEW vw_top_selling_dishes AS
SELECT
    m.dish_id,
    m.dish_name,
    m.category,
    SUM(ii.quantity) AS total_quantity_sold,
    SUM(ii.line_total) AS total_revenue
FROM invoice_items ii
JOIN menu_items m
    ON ii.dish_id = m.dish_id
JOIN invoices i
    ON ii.invoice_id = i.invoice_id
WHERE i.status <> 'cancelled'
GROUP BY
    m.dish_id,
    m.dish_name,
    m.category
ORDER BY total_quantity_sold DESC;

-- -----------------------------------------------------
-- View 5: daily revenue
-- Reports total revenue by date
-- -----------------------------------------------------

CREATE OR REPLACE VIEW vw_daily_revenue AS
SELECT
    DATE(invoice_datetime) AS revenue_date,
    COUNT(invoice_id) AS total_invoices,
    SUM(subtotal) AS total_subtotal,
    SUM(service_charge) AS total_service_charge,
    SUM(discount) AS total_discount,
    SUM(total_amount) AS total_revenue
FROM invoices
WHERE status = 'paid'
GROUP BY DATE(invoice_datetime);

-- -----------------------------------------------------
-- View 6: customer visit summary
-- Reports customer visit count and total spending
-- -----------------------------------------------------

CREATE OR REPLACE VIEW vw_customer_visit_summary AS
SELECT
    c.customer_id,
    c.customer_name,
    c.phone_number,
    COUNT(i.invoice_id) AS total_visits,
    COALESCE(SUM(i.total_amount), 0) AS total_spending
FROM customers c
LEFT JOIN invoices i
    ON c.customer_id = i.customer_id
    AND i.status = 'paid'
GROUP BY
    c.customer_id,
    c.customer_name,
    c.phone_number;

-- =====================================================
-- 3. USER DEFINED FUNCTIONS
-- Purpose: reuse business rules for billing
-- =====================================================

DROP FUNCTION IF EXISTS fn_calculate_service_charge;
DROP FUNCTION IF EXISTS fn_calculate_total_amount;
DROP FUNCTION IF EXISTS fn_calculate_line_total;

DELIMITER //

-- -----------------------------------------------------
-- Function 1: calculate service charge
-- Service charge is 5% of subtotal
-- -----------------------------------------------------

CREATE FUNCTION fn_calculate_service_charge (
    p_subtotal DECIMAL(10,2)
)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    RETURN ROUND(p_subtotal * 0.05, 2);
END //

-- -----------------------------------------------------
-- Function 2: calculate total amount
-- Total amount = subtotal + service charge - discount
-- -----------------------------------------------------

CREATE FUNCTION fn_calculate_total_amount (
    p_subtotal DECIMAL(10,2),
    p_discount DECIMAL(10,2)
)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    RETURN ROUND(p_subtotal + fn_calculate_service_charge(p_subtotal) - p_discount, 2);
END //

-- -----------------------------------------------------
-- Function 3: calculate line total
-- Line total = quantity * unit price
-- -----------------------------------------------------

CREATE FUNCTION fn_calculate_line_total (
    p_quantity INT,
    p_unit_price DECIMAL(10,2)
)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    RETURN ROUND(p_quantity * p_unit_price, 2);
END //

DELIMITER ;

-- =====================================================
-- 4. STORED PROCEDURES
-- Purpose: automate common business operations
-- =====================================================

DROP PROCEDURE IF EXISTS sp_update_invoice_total;
DROP PROCEDURE IF EXISTS sp_create_reservation;
DROP PROCEDURE IF EXISTS sp_create_invoice;
DROP PROCEDURE IF EXISTS sp_add_invoice_item;
DROP PROCEDURE IF EXISTS sp_pay_invoice;

DELIMITER //

-- -----------------------------------------------------
-- Procedure 1: update invoice total
-- Recalculates subtotal, service charge, and total amount
-- -----------------------------------------------------

CREATE PROCEDURE sp_update_invoice_total (
    IN p_invoice_id INT
)
BEGIN
    DECLARE v_subtotal DECIMAL(10,2);
    DECLARE v_discount DECIMAL(10,2);

    SELECT COALESCE(SUM(line_total), 0)
    INTO v_subtotal
    FROM invoice_items
    WHERE invoice_id = p_invoice_id;

    SELECT discount
    INTO v_discount
    FROM invoices
    WHERE invoice_id = p_invoice_id;

    UPDATE invoices
    SET
        subtotal = v_subtotal,
        service_charge = fn_calculate_service_charge(v_subtotal),
        total_amount = fn_calculate_total_amount(v_subtotal, v_discount)
    WHERE invoice_id = p_invoice_id;
END //

-- -----------------------------------------------------
-- Procedure 2: create reservation
-- Creates a reservation and updates table status
-- -----------------------------------------------------

CREATE PROCEDURE sp_create_reservation (
    IN p_customer_id INT,
    IN p_table_id INT,
    IN p_reservation_datetime DATETIME,
    IN p_guest_count INT,
    IN p_note VARCHAR(255)
)
BEGIN
    DECLARE v_table_status VARCHAR(20);
    DECLARE v_capacity INT;

    SELECT status, capacity
    INTO v_table_status, v_capacity
    FROM restaurant_tables
    WHERE table_id = p_table_id;

    IF v_table_status IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'table does not exist';
    END IF;

    IF v_table_status <> 'available' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'table is not available';
    END IF;

    IF p_guest_count > v_capacity THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'guest count exceeds table capacity';
    END IF;

    INSERT INTO reservations (
        customer_id,
        table_id,
        reservation_datetime,
        guest_count,
        status,
        note
    )
    VALUES (
        p_customer_id,
        p_table_id,
        p_reservation_datetime,
        p_guest_count,
        'confirmed',
        p_note
    );

    UPDATE restaurant_tables
    SET status = 'reserved'
    WHERE table_id = p_table_id;
END //

-- -----------------------------------------------------
-- Procedure 3: create invoice
-- Creates a new unpaid invoice
-- -----------------------------------------------------

CREATE PROCEDURE sp_create_invoice (
    IN p_customer_id INT,
    IN p_table_id INT,
    IN p_employee_id INT,
    IN p_discount DECIMAL(10,2)
)
BEGIN
    INSERT INTO invoices (
        customer_id,
        table_id,
        employee_id,
        invoice_datetime,
        subtotal,
        service_charge,
        discount,
        total_amount,
        status
    )
    VALUES (
        p_customer_id,
        p_table_id,
        p_employee_id,
        CURRENT_TIMESTAMP,
        0,
        0,
        p_discount,
        0,
        'unpaid'
    );

    UPDATE restaurant_tables
    SET status = 'occupied'
    WHERE table_id = p_table_id;
END //

-- -----------------------------------------------------
-- Procedure 4: add invoice item
-- Adds a dish to an invoice and updates invoice total
-- -----------------------------------------------------

CREATE PROCEDURE sp_add_invoice_item (
    IN p_invoice_id INT,
    IN p_dish_id INT,
    IN p_quantity INT
)
BEGIN
    DECLARE v_unit_price DECIMAL(10,2);

    SELECT price
    INTO v_unit_price
    FROM menu_items
    WHERE dish_id = p_dish_id
      AND availability = TRUE;

    IF v_unit_price IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'dish does not exist or is unavailable';
    END IF;

    INSERT INTO invoice_items (
        invoice_id,
        dish_id,
        quantity,
        unit_price,
        line_total
    )
    VALUES (
        p_invoice_id,
        p_dish_id,
        p_quantity,
        v_unit_price,
        fn_calculate_line_total(p_quantity, v_unit_price)
    );

    CALL sp_update_invoice_total(p_invoice_id);
END //

-- -----------------------------------------------------
-- Procedure 5: pay invoice
-- Inserts payment and updates invoice status
-- -----------------------------------------------------

CREATE PROCEDURE sp_pay_invoice (
    IN p_invoice_id INT,
    IN p_payment_method VARCHAR(30)
)
BEGIN
    DECLARE v_total_amount DECIMAL(10,2);

    SELECT total_amount
    INTO v_total_amount
    FROM invoices
    WHERE invoice_id = p_invoice_id
      AND status = 'unpaid';

    IF v_total_amount IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'invoice does not exist or is not unpaid';
    END IF;

    INSERT INTO payments (
        invoice_id,
        payment_method,
        amount_paid,
        payment_date,
        payment_status
    )
    VALUES (
        p_invoice_id,
        p_payment_method,
        v_total_amount,
        CURRENT_TIMESTAMP,
        'completed'
    );

    UPDATE invoices
    SET status = 'paid'
    WHERE invoice_id = p_invoice_id;
END //

DELIMITER ;

-- =====================================================
-- 5. TRIGGERS
-- Purpose: automatically maintain data consistency
-- =====================================================

DROP TRIGGER IF EXISTS trg_invoice_items_before_insert;
DROP TRIGGER IF EXISTS trg_invoice_items_before_update;
DROP TRIGGER IF EXISTS trg_invoice_items_after_insert;
DROP TRIGGER IF EXISTS trg_invoice_items_after_update;
DROP TRIGGER IF EXISTS trg_invoice_items_after_delete;
DROP TRIGGER IF EXISTS trg_reservations_after_insert;
DROP TRIGGER IF EXISTS trg_payments_after_insert;

DELIMITER //

-- -----------------------------------------------------
-- Trigger 1: calculate line total before inserting invoice item
-- -----------------------------------------------------

CREATE TRIGGER trg_invoice_items_before_insert
BEFORE INSERT ON invoice_items
FOR EACH ROW
BEGIN
    SET NEW.line_total = fn_calculate_line_total(NEW.quantity, NEW.unit_price);
END //

-- -----------------------------------------------------
-- Trigger 2: recalculate line total before updating invoice item
-- -----------------------------------------------------

CREATE TRIGGER trg_invoice_items_before_update
BEFORE UPDATE ON invoice_items
FOR EACH ROW
BEGIN
    SET NEW.line_total = fn_calculate_line_total(NEW.quantity, NEW.unit_price);
END //

-- -----------------------------------------------------
-- Trigger 3: update invoice total after inserting invoice item
-- -----------------------------------------------------

CREATE TRIGGER trg_invoice_items_after_insert
AFTER INSERT ON invoice_items
FOR EACH ROW
BEGIN
    CALL sp_update_invoice_total(NEW.invoice_id);
END //

-- -----------------------------------------------------
-- Trigger 4: update invoice total after updating invoice item
-- -----------------------------------------------------

CREATE TRIGGER trg_invoice_items_after_update
AFTER UPDATE ON invoice_items
FOR EACH ROW
BEGIN
    CALL sp_update_invoice_total(NEW.invoice_id);

    IF OLD.invoice_id <> NEW.invoice_id THEN
        CALL sp_update_invoice_total(OLD.invoice_id);
    END IF;
END //

-- -----------------------------------------------------
-- Trigger 5: update invoice total after deleting invoice item
-- -----------------------------------------------------

CREATE TRIGGER trg_invoice_items_after_delete
AFTER DELETE ON invoice_items
FOR EACH ROW
BEGIN
    CALL sp_update_invoice_total(OLD.invoice_id);
END //

-- -----------------------------------------------------
-- Trigger 6: update table status after confirmed reservation
-- -----------------------------------------------------

CREATE TRIGGER trg_reservations_after_insert
AFTER INSERT ON reservations
FOR EACH ROW
BEGIN
    IF NEW.status = 'confirmed' THEN
        UPDATE restaurant_tables
        SET status = 'reserved'
        WHERE table_id = NEW.table_id;
    END IF;
END //

-- -----------------------------------------------------
-- Trigger 7: update invoice status after completed payment
-- -----------------------------------------------------

CREATE TRIGGER trg_payments_after_insert
AFTER INSERT ON payments
FOR EACH ROW
BEGIN
    IF NEW.payment_status = 'completed' THEN
        UPDATE invoices
        SET status = 'paid'
        WHERE invoice_id = NEW.invoice_id;
    END IF;
END //

DELIMITER ;

-- =====================================================
-- 6. CHECK ADVANCED OBJECTS
-- These queries are for quick verification in MySQL Workbench
-- =====================================================

SHOW INDEX FROM customers;
SHOW INDEX FROM menu_items;
SHOW INDEX FROM reservations;
SHOW INDEX FROM invoices;
SHOW INDEX FROM invoice_items;
SHOW INDEX FROM payments;

SHOW FULL TABLES
WHERE TABLE_TYPE = 'VIEW';

SHOW PROCEDURE STATUS
WHERE Db = 'restaurant_management';

SHOW FUNCTION STATUS
WHERE Db = 'restaurant_management';

SHOW TRIGGERS;