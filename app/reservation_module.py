import datetime as dt
import streamlit as st
from db_config import fetch_data, execute_query, call_procedure


RESERVATION_STATUSES = ["pending", "confirmed", "completed", "cancelled"]

def format_time_value(value):
    if value is None:
        return ""

    if hasattr(value, "total_seconds"):
        total_seconds = int(value.total_seconds())
        hours = total_seconds // 3600
        minutes = (total_seconds % 3600) // 60
        seconds = total_seconds % 60
        return f"{hours:02d}:{minutes:02d}:{seconds:02d}"

    return str(value)

def show_reservation_module():
    st.title("Reservation Management")

    tab1, tab2, tab3 = st.tabs(["View by Date", "Create Reservation", "Update Status"])

    with tab1:
        st.subheader("Reservations by Date")
        selected_date = st.date_input("Reservation date")
        df = fetch_data(
            """
            SELECT r.reservation_id,
                   DATE(r.reservation_datetime) AS reservation_date,
                   TIME(r.reservation_datetime) AS reservation_time,
                   c.phone_number,
                   t.table_number,
                   r.guest_count,
                   r.status,
                   r.note
            FROM reservations r
            JOIN customers c ON r.customer_id = c.customer_id
            JOIN restaurant_tables t ON r.table_id = t.table_id
            WHERE DATE(r.reservation_datetime) = %s
            ORDER BY r.reservation_datetime;
            """,
            (selected_date,),
        )
        if not df.empty and "reservation_time" in df.columns:
            df["reservation_time"] = df["reservation_time"].apply(format_time_value)
        st.dataframe(df, use_container_width=True)

    with tab2:
        st.subheader("Create Reservation")
        customers = fetch_data("SELECT customer_id, customer_name, phone_number FROM customers ORDER BY customer_id;")
        tables = fetch_data("SELECT table_id, table_number, capacity, status FROM restaurant_tables ORDER BY table_number;")

        if customers.empty or tables.empty:
            st.warning("Customers and tables must exist before creating a reservation.")
            return

        with st.form("create_reservation_form"):
            customer_id = st.selectbox(
                "Customer",
                customers["customer_id"].tolist(),
                format_func=lambda x: f"{customers.loc[customers['customer_id'] == x, 'customer_name'].iloc[0]} - {customers.loc[customers['customer_id'] == x, 'phone_number'].iloc[0]}",
            )
            table_id = st.selectbox(
                "Table",
                tables["table_id"].tolist(),
                format_func=lambda x: f"Table {tables.loc[tables['table_id'] == x, 'table_number'].iloc[0]} | Capacity {tables.loc[tables['table_id'] == x, 'capacity'].iloc[0]} | {tables.loc[tables['table_id'] == x, 'status'].iloc[0]}",
            )
            reservation_date = st.date_input("Reservation date")
            reservation_time = st.time_input("Reservation time")
            guest_count = st.number_input("Guest count", min_value=1, step=1)
            note = st.text_area("Note")
            submitted = st.form_submit_button("Create Reservation")

        if submitted:
            reservation_datetime = dt.datetime.combine(reservation_date, reservation_time)
            ok = call_procedure(
                "sp_create_reservation",
                [int(customer_id), int(table_id), reservation_datetime, int(guest_count), note or None],
                "Reservation created successfully.",
            )
            if ok:
                st.rerun()

    with tab3:
        st.subheader("Update Reservation Status")
        reservations = fetch_data(
            """
            SELECT r.reservation_id,
                   DATE(r.reservation_datetime) AS reservation_date,
                   TIME(r.reservation_datetime) AS reservation_time,
                   c.customer_name,
                   r.status
            FROM reservations r
            JOIN customers c ON r.customer_id = c.customer_id
            ORDER BY r.reservation_datetime DESC;
            """
        )
        if not reservations.empty and "reservation_time" in reservations.columns:
            reservations["reservation_time"] = reservations["reservation_time"].apply(format_time_value)
        if reservations.empty:
            st.info("No reservations found.")
            return
        reservation_id = st.selectbox(
            "Select reservation",
            reservations["reservation_id"].tolist(),
            format_func=lambda x: f"{x} - {reservations.loc[reservations['reservation_id'] == x, 'customer_name'].iloc[0]} - {reservations.loc[reservations['reservation_id'] == x, 'reservation_date'].iloc[0]} {reservations.loc[reservations['reservation_id'] == x, 'reservation_time'].iloc[0]}",
        )
        current_status = reservations.loc[reservations["reservation_id"] == reservation_id, "status"].iloc[0]
        status = st.selectbox(
            "New status",
            RESERVATION_STATUSES,
            index=RESERVATION_STATUSES.index(current_status) if current_status in RESERVATION_STATUSES else 0,
        )
        if st.button("Update Reservation"):
            execute_query(
                """
                UPDATE reservations
                SET status = %s
                WHERE reservation_id = %s;
                """,
                (status, int(reservation_id)),
                "Reservation status updated successfully.",
            )
            st.rerun()