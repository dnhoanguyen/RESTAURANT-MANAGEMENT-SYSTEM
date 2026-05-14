-- =====================================================
-- security_backup_optimization.sql
-- Restaurant Management System
-- Security, backup notes, and optimization checks
-- =====================================================

USE restaurant_management;

-- =====================================================
-- 1. SECURITY: CREATE USER ROLES
-- Purpose: define different access levels for restaurant staff
-- =====================================================

DROP ROLE IF EXISTS 'admin_role';
DROP ROLE IF EXISTS 'manager_role';
DROP ROLE IF EXISTS 'cashier_role';
DROP ROLE IF EXISTS 'waiter_role';

CREATE ROLE 'admin_role';
CREATE ROLE 'manager_role';
CREATE ROLE 'cashier_role';
CREATE ROLE 'waiter_role';

-- =====================================================
-- 2. GRANT PRIVILEGES TO ROLES
-- =====================================================

-- Admin can fully manage the whole database.
GRANT ALL PRIVILEGES
ON restaurant_management.*
TO 'admin_role';

-- Manager can view reports and summary information.
GRANT SELECT
ON restaurant_management.vw_daily_bookings
TO 'manager_role';

GRANT SELECT
ON restaurant_management.vw_top_selling_dishes
TO 'manager_role';

GRANT SELECT
ON restaurant_management.vw_daily_revenue
TO 'manager_role';

GRANT SELECT
ON restaurant_management.vw_customer_visit_summary
TO 'manager_role';

GRANT SELECT
ON restaurant_management.vw_invoice_details
TO 'manager_role';

-- Cashier can manage invoices and payments.
GRANT SELECT, INSERT, UPDATE
ON restaurant_management.invoices
TO 'cashier_role';

GRANT SELECT, INSERT, UPDATE
ON restaurant_management.invoice_items
TO 'cashier_role';

GRANT SELECT, INSERT, UPDATE
ON restaurant_management.payments
TO 'cashier_role';

GRANT SELECT
ON restaurant_management.customers
TO 'cashier_role';

GRANT SELECT
ON restaurant_management.menu_items
TO 'cashier_role';

GRANT SELECT
ON restaurant_management.restaurant_tables
TO 'cashier_role';

-- Waiter can view menu and tables, and manage reservations.
GRANT SELECT
ON restaurant_management.menu_items
TO 'waiter_role';

GRANT SELECT
ON restaurant_management.restaurant_tables
TO 'waiter_role';

GRANT SELECT, INSERT, UPDATE
ON restaurant_management.reservations
TO 'waiter_role';

GRANT SELECT, INSERT
ON restaurant_management.customers
TO 'waiter_role';

-- =====================================================
-- 3. OPTIONAL: CREATE DEMO USERS
-- These users are used only for demonstration.
-- Change passwords in a real system.
-- =====================================================

DROP USER IF EXISTS 'restaurant_admin'@'localhost';
DROP USER IF EXISTS 'restaurant_manager'@'localhost';
DROP USER IF EXISTS 'restaurant_cashier'@'localhost';
DROP USER IF EXISTS 'restaurant_waiter'@'localhost';

CREATE USER 'restaurant_admin'@'localhost' IDENTIFIED BY 'Admin123!';
CREATE USER 'restaurant_manager'@'localhost' IDENTIFIED BY 'Manager123!';
CREATE USER 'restaurant_cashier'@'localhost' IDENTIFIED BY 'Cashier123!';
CREATE USER 'restaurant_waiter'@'localhost' IDENTIFIED BY 'Waiter123!';

GRANT 'admin_role' TO 'restaurant_admin'@'localhost';
GRANT 'manager_role' TO 'restaurant_manager'@'localhost';
GRANT 'cashier_role' TO 'restaurant_cashier'@'localhost';
GRANT 'waiter_role' TO 'restaurant_waiter'@'localhost';

SET DEFAULT ROLE 'admin_role' TO 'restaurant_admin'@'localhost';
SET DEFAULT ROLE 'manager_role' TO 'restaurant_manager'@'localhost';
SET DEFAULT ROLE 'cashier_role' TO 'restaurant_cashier'@'localhost';
SET DEFAULT ROLE 'waiter_role' TO 'restaurant_waiter'@'localhost';

FLUSH PRIVILEGES;

-- =====================================================
-- 4. CHECK ROLES AND GRANTS
-- =====================================================

SHOW GRANTS FOR 'admin_role';
SHOW GRANTS FOR 'manager_role';
SHOW GRANTS FOR 'cashier_role';
SHOW GRANTS FOR 'waiter_role';

SHOW GRANTS FOR 'restaurant_admin'@'localhost';
SHOW GRANTS FOR 'restaurant_manager'@'localhost';
SHOW GRANTS FOR 'restaurant_cashier'@'localhost';
SHOW GRANTS FOR 'restaurant_waiter'@'localhost';

-- =====================================================
-- 5. OPTIMIZATION CHECKS
-- Purpose: verify that indexes are used in common queries
-- =====================================================

EXPLAIN
SELECT *
FROM customers
WHERE phone_number = '0901000001';

EXPLAIN
SELECT *
FROM menu_items
WHERE dish_name = 'Pho Bo';

EXPLAIN
SELECT *
FROM reservations
WHERE reservation_datetime >= '2026-05-10 00:00:00'
  AND reservation_datetime < '2026-05-11 00:00:00';

EXPLAIN
SELECT *
FROM invoices
WHERE invoice_datetime >= '2026-05-10 00:00:00'
  AND invoice_datetime < '2026-05-11 00:00:00';

EXPLAIN
SELECT
    i.invoice_id,
    c.customer_name,
    i.total_amount,
    i.status
FROM invoices i
JOIN customers c
    ON i.customer_id = c.customer_id
WHERE i.status = 'paid';

-- =====================================================
-- 6. BACKUP AND RESTORE COMMANDS
-- Important:
-- The commands below are terminal commands, not SQL commands.
-- Do not run them inside MySQL Workbench query editor.
-- =====================================================

-- Backup command:
-- mysqldump -u root -p restaurant_management > restaurant_management_backup.sql

-- Restore command:
-- mysql -u root -p restaurant_management < restaurant_management_backup.sql