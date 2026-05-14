import streamlit as st
from db_config import fetch_data, execute_query


TABLE_STATUSES = ["available", "reserved", "occupied"]


def show_table_module():
    st.title("Table Management")

    tab1, tab2, tab3 = st.tabs(["All Tables", "Available Tables", "Update Status"])

    with tab1:
        st.subheader("All Restaurant Tables")
        df = fetch_data(
            """
            SELECT table_id, table_number, capacity, status, location
            FROM restaurant_tables
            ORDER BY table_id;
            """
        )
        st.dataframe(df, use_container_width=True)

    with tab2:
        st.subheader("Available Tables")
        df = fetch_data(
            """
            SELECT table_id, table_number, capacity, status, location
            FROM restaurant_tables
            WHERE status = 'available'
            ORDER BY capacity, table_number;
            """
        )
        st.dataframe(df, use_container_width=True)

    with tab3:
        st.subheader("Update Table Status")
        tables = fetch_data(
            """
            SELECT table_id, table_number, capacity, status, location
            FROM restaurant_tables
            ORDER BY table_id;
            """
        )

        if tables.empty:
            st.info("No tables found.")
            return

        table_id = st.selectbox(
            "Select table",
            tables["table_id"].tolist(),
            format_func=lambda x: f"Table {tables.loc[tables['table_id'] == x, 'table_number'].iloc[0]}",
        )
        current_status = tables.loc[tables["table_id"] == table_id, "status"].iloc[0]
        status = st.selectbox(
            "New status",
            TABLE_STATUSES,
            index=TABLE_STATUSES.index(current_status) if current_status in TABLE_STATUSES else 0,
        )

        if st.button("Update Table Status"):
            execute_query(
                """
                UPDATE restaurant_tables
                SET status = %s
                WHERE table_id = %s;
                """,
                (status, int(table_id)),
                "Table status updated successfully.",
            )
            st.rerun()
