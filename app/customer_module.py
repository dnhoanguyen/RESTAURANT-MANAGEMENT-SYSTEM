import streamlit as st
from db_config import fetch_data, execute_query


def show_customer_module():
    st.title("Customer Management")

    tab1, tab2, tab3 = st.tabs(["View / Search", "Add Customer", "Update Customer"])

    with tab1:
        st.subheader("Search Customers")
        keyword = st.text_input("Search by name or phone")

        if keyword:
            df = fetch_data(
                """
                SELECT customer_id, customer_name, phone_number, email, address
                FROM customers
                WHERE customer_name LIKE %s OR phone_number LIKE %s
                ORDER BY customer_id;
                """,
                (f"%{keyword}%", f"%{keyword}%"),
            )
        else:
            df = fetch_data(
                """
                SELECT customer_id, customer_name, phone_number, email, address
                FROM customers
                ORDER BY customer_id;
                """
            )

        st.dataframe(df, use_container_width=True)

    with tab2:
        st.subheader("Add New Customer")
        with st.form("add_customer_form"):
            customer_name = st.text_input("Customer name")
            phone_number = st.text_input("Phone number")
            email = st.text_input("Email")
            address = st.text_area("Address")
            submitted = st.form_submit_button("Add Customer")

        if submitted:
            if not customer_name or not phone_number:
                st.warning("Customer name and phone number are required.")
            else:
                execute_query(
                    """
                    INSERT INTO customers (customer_name, phone_number, email, address)
                    VALUES (%s, %s, %s, %s);
                    """,
                    (customer_name, phone_number, email or None, address or None),
                    "Customer added successfully.",
                )
                st.rerun()

    with tab3:
        st.subheader("Update Customer")
        customers = fetch_data(
            """
            SELECT customer_id, customer_name, phone_number, email, address
            FROM customers
            ORDER BY customer_id;
            """
        )

        if customers.empty:
            st.info("No customers found.")
            return

        selected_id = st.selectbox(
            "Select customer",
            customers["customer_id"].tolist(),
            format_func=lambda x: f"{x} - {customers.loc[customers['customer_id'] == x, 'customer_name'].iloc[0]}",
        )
        row = customers[customers["customer_id"] == selected_id].iloc[0]

        with st.form("update_customer_form"):
            customer_name = st.text_input("Customer name", value=str(row.get("customer_name", "")))
            phone_number = st.text_input("Phone number", value=str(row.get("phone_number", "")))
            email = st.text_input("Email", value="" if row.get("email") is None else str(row.get("email")))
            address = st.text_area("Address", value="" if row.get("address") is None else str(row.get("address")))
            submitted = st.form_submit_button("Update Customer")

        if submitted:
            execute_query(
                """
                UPDATE customers
                SET customer_name = %s,
                    phone_number = %s,
                    email = %s,
                    address = %s
                WHERE customer_id = %s;
                """,
                (customer_name, phone_number, email or None, address or None, int(selected_id)),
                "Customer updated successfully.",
            )
            st.rerun()
