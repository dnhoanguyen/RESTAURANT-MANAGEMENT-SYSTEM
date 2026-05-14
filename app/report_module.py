import streamlit as st
from db_config import fetch_data


def show_report_module():
    st.title("Reports")

    tab1, tab2, tab3, tab4 = st.tabs([
        "Daily Revenue",
        "Top-selling Dishes",
        "Table Usage",
        "Customer Visit Summary",
    ])

    with tab1:
        st.subheader("Daily Revenue Report")
        start_date = st.date_input("Start date", key="revenue_start")
        end_date = st.date_input("End date", key="revenue_end")

        df = fetch_data(
            """
            SELECT revenue_date,
                   total_invoices,
                   total_subtotal,
                   total_service_charge,
                   total_discount,
                   total_revenue
            FROM vw_daily_revenue
            WHERE revenue_date BETWEEN %s AND %s
            ORDER BY revenue_date;
            """,
            (start_date, end_date),
        )
        st.dataframe(df, use_container_width=True)
        if not df.empty:
            st.bar_chart(df.set_index("revenue_date")["total_revenue"])

    with tab2:
        st.subheader("Top-selling Dishes")
        limit = st.slider("Number of dishes", min_value=5, max_value=30, value=10)
        df = fetch_data(
            """
            SELECT dish_id,
                   dish_name,
                   category,
                   total_quantity_sold,
                   total_revenue
            FROM vw_top_selling_dishes
            LIMIT %s;
            """,
            (int(limit),),
        )
        st.dataframe(df, use_container_width=True)
        if not df.empty:
            st.bar_chart(df.set_index("dish_name")["total_quantity_sold"])

    with tab3:
        st.subheader("Table Usage Statistics")
        df = fetch_data(
            """
            SELECT t.table_id,
                   t.table_number,
                   t.capacity,
                   t.status,
                   t.location,
                   COUNT(r.reservation_id) AS reservation_count,
                   COUNT(i.invoice_id) AS invoice_count,
                   COALESCE(SUM(CASE WHEN i.status = 'paid' THEN i.total_amount ELSE 0 END), 0) AS revenue_generated
            FROM restaurant_tables t
            LEFT JOIN reservations r ON t.table_id = r.table_id
            LEFT JOIN invoices i ON t.table_id = i.table_id
            GROUP BY t.table_id, t.table_number, t.capacity, t.status, t.location
            ORDER BY reservation_count DESC, revenue_generated DESC;
            """
        )
        st.dataframe(df, use_container_width=True)

    with tab4:
        st.subheader("Customer Visit Summary")
        df = fetch_data(
            """
            SELECT customer_id,
                   customer_name,
                   phone_number,
                   total_visits,
                   total_spending
            FROM vw_customer_visit_summary
            ORDER BY total_spending DESC, total_visits DESC;
            """
        )
        st.dataframe(df, use_container_width=True)
