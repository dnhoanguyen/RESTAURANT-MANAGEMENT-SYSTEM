import mysql.connector
from mysql.connector import Error
import streamlit as st

DB_CONFIG = {
    "host": "localhost",
    "user": "root",
    "password": "317946hn",  # change this to your MySQL password if needed
    "database": "restaurant_management",
    "port": 3306,
}


def get_connection():
    """Create and return a MySQL connection."""
    try:
        return mysql.connector.connect(**DB_CONFIG)
    except Error as err:
        st.error(f"Database connection failed: {err}")
        return None


def fetch_data(query, params=None):
    """Run a SELECT query and return a pandas DataFrame."""
    import pandas as pd

    conn = get_connection()
    if conn is None:
        return pd.DataFrame()

    try:
        return pd.read_sql(query, conn, params=params)
    except Exception as err:
        st.error(f"Query failed: {err}")
        return pd.DataFrame()
    finally:
        conn.close()


def execute_query(query, params=None, success_message=None):
    """Run INSERT / UPDATE / DELETE query."""
    conn = get_connection()
    if conn is None:
        return False

    try:
        cursor = conn.cursor()
        cursor.execute(query, params or ())
        conn.commit()
        if success_message:
            st.success(success_message)
        return True
    except Error as err:
        conn.rollback()
        st.error(f"Execution failed: {err}")
        return False
    finally:
        cursor.close()
        conn.close()


def call_procedure(proc_name, args=None, success_message=None):
    """Call a stored procedure from MySQL."""
    conn = get_connection()
    if conn is None:
        return False

    try:
        cursor = conn.cursor()
        cursor.callproc(proc_name, args or [])
        conn.commit()
        if success_message:
            st.success(success_message)
        return True
    except Error as err:
        conn.rollback()
        st.error(f"Procedure failed: {err}")
        return False
    finally:
        cursor.close()
        conn.close()
