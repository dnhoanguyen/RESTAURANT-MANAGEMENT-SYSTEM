# RESTAURANT-MANAGEMENT-SYSTEM

A database-driven Restaurant Management System built with **MySQL** and **Python Streamlit**.
The system supports customer management, table management, menu management, reservations, invoices, payments, reporting, and role-based access control.

## Demo Video

YouTube demo link: https://youtu.be/nlmHpWP_P0U

---

## 1. Project Overview

The Restaurant Management System is designed to support daily restaurant operations in a structured and reliable way. It helps restaurant staff manage customers, restaurant tables, menu items, reservations, invoices, payments, and business reports.

The project uses **MySQL** as the database management system and **Streamlit** as the web-based application interface. The database includes primary keys, foreign keys, constraints, indexes, views, stored procedures, user-defined functions, triggers, security roles, and backup/restore instructions.

---

## 2. Technologies Used

* MySQL
* MySQL Workbench
* Python
* Streamlit
* mysql-connector-python
* pandas

---

## 3. Main Features

* Customer management
* Restaurant table management
* Menu item management
* Reservation management
* Invoice management
* Payment processing
* Daily revenue report
* Top-selling dishes report
* Table usage statistics
* Customer visit summary
* Role-based login and access control

---

## 4. User Roles

| Role    | Application Access                                       |
| ------- | -------------------------------------------------------- |
| admin   | Can access all modules                                   |
| manager | Can access Tables, Menu, and Reports                     |
| cashier | Can access Customers, Reservations, and Invoices         |
| waiter  | Can access Customers, Tables, Reservations, and Invoices |

The waiter role can create invoices and add dishes during service.
Payment-related actions such as marking invoices as paid or cancelling unpaid invoices are handled by the cashier.

---

## 5. Project Structure

<pre>restaurant_management_system/
├── sql/
│   ├── schema.sql
│   ├── sample_data.sql
│   ├── advanced_objects.sql
│   ├── security_optimization.sql
│   └── queries_demo.sql
│
├── app/
│   ├── db_config.py
│   ├── app.py
│   ├── auth.py
│   ├── customer_module.py
│   ├── table_module.py
│   ├── menu_module.py
│   ├── reservation_module.py
│   ├── invoice_module.py
│   └── report_module.py
│
├── EER.png
├── EERDiagram.mwb
└── README.md
    
---

## 6. Database Design

The database contains 8 main tables:

| Table             | Description                                                |
| ----------------- | ---------------------------------------------------------- |
| customers         | Stores customer information                                |
| restaurant_tables | Stores restaurant table information                        |
| menu_items        | Stores dish information, price, category, and availability |
| employees         | Stores staff information and login accounts                |
| reservations      | Stores table booking information                           |
| invoices          | Stores invoice header information                          |
| invoice_items     | Stores dishes included in each invoice                     |
| payments          | Stores invoice payment records                             |

---

## 7. SQL Files

| File                      | Description                                                        |
| ------------------------- | ------------------------------------------------------------------ |
| schema.sql                | Creates the database schema, tables, keys, and constraints         |
| sample_data.sql           | Inserts sample data for testing and demonstration                  |
| advanced_objects.sql      | Creates indexes, views, stored procedures, functions, and triggers |
| security_optimization.sql | Creates roles, privileges, backup notes, and optimization checks   |
---

## 8. Correct SQL Execution Order

Run the SQL files in this order:

1. schema.sql
2. sample_data.sql
3. advanced_objects.sql
4. security_optimization.sql

This order is important because the tables must be created before inserting sample data. Advanced database objects should be created after the sample data is available, and security privileges should be created after all database objects already exist.

---

## 9. Backup and Restore

Backup command:

```bash
mysqldump -u root -p restaurant_management > restaurant_management_backup.sql
```

Restore command:

```bash
mysql -u root -p restaurant_management < restaurant_management_backup.sql
```

On macOS, backup to Desktop:

```bash
mysqldump -u root -p restaurant_management > ~/Desktop/restaurant_management_backup.sql
```

---

## 10. Sample Data

The sample data includes:

| Data Type         | Number of Records |
| ----------------- | ----------------: |
| Customers         |                11 |
| Restaurant tables |                 5 |
| Employees         |                 8 |
| Menu items        |                10 |
| Reservations      |                20 |
| Invoices          |                20 |
| Invoice items     |                40 |

The sample data is designed to be logically consistent:

* Completed reservations before or on May 13, 2026 have matching invoices.
* Cancelled reservations do not require invoices.
* Invoices before or on May 13, 2026 are either paid or cancelled.
* Invoices on May 14, 2026 can be unpaid.
* All invoice items reference valid menu items.
* All reservations and invoices reference valid customers and restaurant tables.

---

## 11. Streamlit Application

The Streamlit application is divided into separate modules:

| File                  | Purpose                                                  |
| --------------------- | -------------------------------------------------------- |
| db_config.py          | Handles MySQL connection and reusable database functions |
| auth.py               | Handles login, logout, and session state                 |
| app.py                | Main Streamlit application and role-based sidebar        |
| customer_module.py    | Customer management functions                            |
| table_module.py       | Table management functions                               |
| menu_module.py        | Menu management functions                                |
| reservation_module.py | Reservation management functions                         |
| invoice_module.py     | Invoice and payment functions                            |
| report_module.py      | Report display functions                                 |

---

## 12. Installation

Install the required Python packages:

```bash
pip install streamlit mysql-connector-python pandas
```

Optional: create a virtual environment before installing packages.

macOS / Linux:

```bash
python3 -m venv venv
source venv/bin/activate
pip install streamlit mysql-connector-python pandas
```

Windows:

```bash
python -m venv venv
venv\Scripts\activate
pip install streamlit mysql-connector-python pandas
```

---

## 13. Database Configuration

Before running the application, update the MySQL connection settings in:

app/db_config.py

Example:

```python
DB_CONFIG = {
    "host": "localhost",
    "user": "root",
    "password": "your_mysql_password",
    "database": "restaurant_management"
}
```

Make sure MySQL Server is running before starting the Streamlit application.

---

## 14. How to Run the Application

After running the SQL files and installing the required packages, start the app with:

```bash
streamlit run app/app.py
```

The application will open in your browser.

---

## 15. Demo Accounts

The system uses the employees table for login.

| Role    | Username  | Password   |
| ------- | --------- | ---------- |
| admin   | admin     | admin123   |
| manager | manager01 | manager123 |
| cashier | cashier01 | cashier123 |
| waiter  | waiter01  | waiter123  |

---

## 16. Main Workflows

### Reservation Workflow

1. Select a customer.
2. Select a table.
3. Choose reservation date and time.
4. Enter guest count and note.
5. Create reservation.
6. Update reservation status when needed.

Reservation statuses include:

* pending
* confirmed
* completed
* cancelled

### Invoice Workflow

1. Create an invoice for a customer and table.
2. Add dishes to the unpaid invoice.
3. The system calculates line total, subtotal, service charge, discount, and total amount.
4. Cashier marks the invoice as paid after payment.
5. Cashier can cancel unpaid invoices if needed.

Invoice statuses include:

* unpaid
* paid
* cancelled

---

## 17. Reports

The system provides the following reports:

* Daily revenue report
* Top-selling dishes report
* Table usage statistics
* Customer visit summary

These reports help managers monitor restaurant performance and support decision-making.

---

## 18. Notes and Limitations

* Passwords are stored as plain text for demonstration purposes.
* In a real system, password hashing should be applied.
* Paid invoices cannot be cancelled directly.
* A real system should use a refund process for paid invoice cancellation.
* The current system is designed for local demonstration and testing.
* MySQL Server must be running before the Streamlit application can connect to the database.

---

## 19. Future Improvements

Possible future improvements include:

* Online ordering
* QR-based table check-in
* Customer loyalty program
* Customer feedback and rating system
* Mobile application
* Password hashing
* Refund management for paid invoices
* More advanced revenue dashboards

