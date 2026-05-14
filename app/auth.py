import pandas as pd
import streamlit as st
from db_config import get_connection


DEMO_ACCOUNTS = {
    "Admin": {"username": "admin", "password": "admin123", "role": "admin"},
    "Manager": {"username": "manager01", "password": "manager123", "role": "manager"},
    "Cashier": {"username": "cashier01", "password": "cashier123", "role": "cashier"},
    "Waiter": {"username": "waiter01", "password": "waiter123", "role": "waiter"},
}


def authenticate(username, password):
    query = """
        SELECT employee_id, employee_name, role
        FROM employees
        WHERE username = %s AND password = %s
        LIMIT 1;
    """

    conn = get_connection()
    if conn is None:
        return None

    try:
        cursor = conn.cursor(dictionary=True)
        cursor.execute(query, (username, password))
        return cursor.fetchone()
    finally:
        cursor.close()
        conn.close()


def login():
    st.title("Restaurant Management System")
    st.subheader("Login")

    st.info("Demo accounts for testing different roles")
    st.dataframe(pd.DataFrame(DEMO_ACCOUNTS).T, use_container_width=True)

    with st.form("login_form"):
        username = st.text_input("Username")
        password = st.text_input("Password", type="password")
        submitted = st.form_submit_button("Login")

    if submitted:
        user = authenticate(username, password)
        if user:
            st.session_state["logged_in"] = True
            st.session_state["employee_id"] = user["employee_id"]
            st.session_state["employee_name"] = user["employee_name"]
            st.session_state["role"] = user["role"].lower()
            st.success(f"Welcome, {user['employee_name']}!")
            st.rerun()
        else:
            st.error("Invalid username or password.")


def logout():
    for key in ["logged_in", "employee_id", "employee_name", "role"]:
        st.session_state.pop(key, None)
    st.rerun()


def check_login():
    return st.session_state.get("logged_in", False)
