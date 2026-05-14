import streamlit as st
from auth import login, logout, check_login
from customer_module import show_customer_module
from table_module import show_table_module
from menu_module import show_menu_module
from reservation_module import show_reservation_module
from invoice_module import show_invoice_module
from report_module import show_report_module
from db_config import fetch_data

st.set_page_config(
    page_title="Restaurant Management System",
    page_icon="🍽️",
    layout="wide",
)

ROLE_MENUS = {
    "admin": ["Dashboard", "Customers", "Tables", "Menu", "Reservations", "Invoices", "Reports"],
    "manager": ["Dashboard", "Tables", "Menu", "Reports"],
    "cashier": ["Dashboard", "Customers", "Reservations", "Invoices"],
    "waiter": ["Dashboard", "Customers", "Tables", "Reservations", "Invoices"],
}


def _metric_value(df, default=0):
    if df.empty:
        return default
    value = df.iloc[0, 0]
    return default if value is None else value


def show_dashboard():
    st.title("Dashboard")
    st.write(f"Logged in as: **{st.session_state.get('employee_name')}**")
    st.write(f"Role: **{st.session_state.get('role', '').title()}**")

    col1, col2, col3, col4 = st.columns(4)

    customers = fetch_data("SELECT COUNT(*) AS total FROM customers;")
    tables = fetch_data("SELECT COUNT(*) AS total FROM restaurant_tables;")
    menu = fetch_data("SELECT COUNT(*) AS total FROM menu_items;")
    invoices = fetch_data("SELECT COUNT(*) AS total FROM invoices;")

    col1.metric("Customers", int(_metric_value(customers)))
    col2.metric("Tables", int(_metric_value(tables)))
    col3.metric("Menu Items", int(_metric_value(menu)))
    col4.metric("Invoices", int(_metric_value(invoices)))

    st.divider()
    st.subheader("Today Overview")
    today_revenue = fetch_data(
        """
        SELECT COALESCE(SUM(total_amount), 0) AS today_revenue
        FROM invoices
        WHERE DATE(invoice_datetime) = CURDATE() AND status = 'paid';
        """
    )
    today_reservations = fetch_data(
        """
        SELECT COUNT(*) AS today_reservations
        FROM reservations
        WHERE DATE(reservation_datetime) = CURDATE();
        """
    )

    c1, c2 = st.columns(2)
    c1.metric("Today's Revenue", f"{float(_metric_value(today_revenue)):,.0f} VND")
    c2.metric("Today's Reservations", int(_metric_value(today_reservations)))


def main():
    if not check_login():
        login()
        return

    role = st.session_state.get("role", "waiter")
    menu_items = ROLE_MENUS.get(role, ROLE_MENUS["waiter"])

    with st.sidebar:
        st.title("Navigation")
        selected = st.radio("Choose module", menu_items)
        st.divider()
        if st.button("Logout"):
            logout()

    if selected == "Dashboard":
        show_dashboard()
    elif selected == "Customers":
        show_customer_module()
    elif selected == "Tables":
        show_table_module()
    elif selected == "Menu":
        show_menu_module()
    elif selected == "Reservations":
        show_reservation_module()
    elif selected == "Invoices":
        show_invoice_module()
    elif selected == "Reports":
        show_report_module()


if __name__ == "__main__":
    main()
