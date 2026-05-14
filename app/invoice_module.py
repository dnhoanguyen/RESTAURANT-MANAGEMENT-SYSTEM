import streamlit as st
from db_config import fetch_data, execute_query, get_connection, call_procedure


def update_invoice_total(invoice_id):
    return call_procedure("sp_update_invoice_total", [int(invoice_id)])

def cancel_invoice(invoice_id):
    """
    Cancel an unpaid invoice.
    If the invoice has pending payment records, remove them because cancelled invoices should not have pending payments.
    Paid invoices are not cancelled here to avoid conflicting with completed payments.
    """
    conn = get_connection()
    if conn is None:
        return False

    try:
        cursor = conn.cursor()

        cursor.execute(
            """
            SELECT status
            FROM invoices
            WHERE invoice_id = %s;
            """,
            (int(invoice_id),),
        )
        result = cursor.fetchone()

        if result is None:
            st.error("Invoice not found.")
            return False

        current_status = result[0]

        if current_status == "paid":
            st.error("Paid invoices cannot be cancelled. A refund process should be used instead.")
            return False

        if current_status == "cancelled":
            st.warning("This invoice is already cancelled.")
            return False

        cursor.execute(
            """
            UPDATE invoices
            SET status = 'cancelled'
            WHERE invoice_id = %s;
            """,
            (int(invoice_id),),
        )

        cursor.execute(
            """
            DELETE FROM payments
            WHERE invoice_id = %s
              AND payment_status = 'pending';
            """,
            (int(invoice_id),),
        )

        conn.commit()
        st.success("Invoice cancelled successfully.")
        return True

    except Exception as err:
        conn.rollback()
        st.error(f"Cancel invoice failed: {err}")
        return False

    finally:
        cursor.close()
        conn.close()
        
def show_invoice_module():
    st.title("Invoice Management")

    role = st.session_state.get("role")

    if role == "waiter":
        tab1, tab2, tab3, tab4 = st.tabs([
            "View Invoices",
            "Create Invoice",
            "Add Dish",
            "Invoice Details",
        ])
    else:
        tab1, tab2, tab3, tab4, tab5, tab6 = st.tabs([
            "View Invoices",
            "Create Invoice",
            "Add Dish",
            "Invoice Details",
            "Mark as Paid",
            "Cancel Invoice",
        ])
    

    with tab1:
        st.subheader("All Invoices")
        df = fetch_data(
            """
            SELECT i.invoice_id,
                   i.invoice_datetime,
                   c.customer_name,
                   t.table_number,
                   e.employee_name,
                   i.subtotal,
                   i.service_charge,
                   i.discount,
                   i.total_amount,
                   i.status
            FROM invoices i
            JOIN customers c ON i.customer_id = c.customer_id
            JOIN restaurant_tables t ON i.table_id = t.table_id
            JOIN employees e ON i.employee_id = e.employee_id
            ORDER BY i.invoice_datetime DESC, i.invoice_id DESC;
            """
        )
        st.dataframe(df, use_container_width=True)

    with tab2:
        st.subheader("Create Invoice")
        customers = fetch_data("SELECT customer_id, customer_name FROM customers ORDER BY customer_id;")
        tables = fetch_data("SELECT table_id, table_number, status FROM restaurant_tables ORDER BY table_number;")

        if customers.empty or tables.empty:
            st.warning("Customers and tables must exist before creating an invoice.")
            return

        with st.form("create_invoice_form"):
            customer_id = st.selectbox(
                "Customer",
                customers["customer_id"].tolist(),
                format_func=lambda x: f"{x} - {customers.loc[customers['customer_id'] == x, 'customer_name'].iloc[0]}",
            )
            table_id = st.selectbox(
                "Table",
                tables["table_id"].tolist(),
                format_func=lambda x: f"Table {tables.loc[tables['table_id'] == x, 'table_number'].iloc[0]} | {tables.loc[tables['table_id'] == x, 'status'].iloc[0]}",
            )
            discount = st.number_input("Discount", min_value=0.0, step=1000.0, value=0.0)
            submitted = st.form_submit_button("Create Invoice")

        if submitted:
            employee_id = st.session_state.get("employee_id")
            ok = call_procedure(
                "sp_create_invoice",
                [int(customer_id), int(table_id), int(employee_id), float(discount)],
                "Invoice created successfully.",
            )
            if ok:
                st.rerun()

    with tab3:
        st.subheader("Add Dish to Invoice")
        invoices = fetch_data("SELECT invoice_id, status FROM invoices WHERE status = 'unpaid' ORDER BY invoice_id DESC;")
        dishes = fetch_data(
            """
            SELECT dish_id,
                   dish_name,
                   price,
                   CASE WHEN availability = TRUE THEN 'available' ELSE 'unavailable' END AS availability
            FROM menu_items
            ORDER BY dish_name;
            """
        )

        if invoices.empty or dishes.empty:
            st.warning("Invoices and menu items must exist before adding dishes.")
            return

        with st.form("add_invoice_item_form"):
            invoice_id = st.selectbox(
                "Invoice",
                invoices["invoice_id"].tolist(),
                format_func=lambda x: f"Invoice #{x} | {invoices.loc[invoices['invoice_id'] == x, 'status'].iloc[0]}",
            )
            dish_id = st.selectbox(
                "Dish",
                dishes["dish_id"].tolist(),
                format_func=lambda x: f"{dishes.loc[dishes['dish_id'] == x, 'dish_name'].iloc[0]} | {float(dishes.loc[dishes['dish_id'] == x, 'price'].iloc[0]):,.0f} VND | {dishes.loc[dishes['dish_id'] == x, 'availability'].iloc[0]}",
            )
            quantity = st.number_input("Quantity", min_value=1, step=1)
            submitted = st.form_submit_button("Add Dish")

        if submitted:
            ok = call_procedure(
                "sp_add_invoice_item",
                [int(invoice_id), int(dish_id), int(quantity)],
                "Dish added to invoice successfully.",
            )
            if ok:
                st.rerun()

    with tab4:
        st.subheader("Invoice Details")
        invoices = fetch_data("SELECT invoice_id FROM invoices ORDER BY invoice_id DESC;")
        if invoices.empty:
            st.info("No invoices found.")
            return

        invoice_id = st.selectbox("Select invoice", invoices["invoice_id"].tolist(), key="invoice_detail")
        header = fetch_data(
            """
            SELECT i.invoice_id,
                   i.invoice_datetime,
                   c.customer_name,
                   t.table_number,
                   e.employee_name,
                   i.subtotal,
                   i.service_charge,
                   i.discount,
                   i.total_amount,
                   i.status
            FROM invoices i
            JOIN customers c ON i.customer_id = c.customer_id
            JOIN restaurant_tables t ON i.table_id = t.table_id
            JOIN employees e ON i.employee_id = e.employee_id
            WHERE i.invoice_id = %s;
            """,
            (int(invoice_id),),
        )
        details = fetch_data(
            """
            SELECT m.dish_name, ii.quantity, ii.unit_price, ii.line_total
            FROM invoice_items ii
            JOIN menu_items m ON ii.dish_id = m.dish_id
            WHERE ii.invoice_id = %s
            ORDER BY m.dish_name;
            """,
            (int(invoice_id),),
        )
        st.write("Invoice Header")
        st.dataframe(header, use_container_width=True)
        st.write("Invoice Items")
        st.dataframe(details, use_container_width=True)

    if role != "waiter":
        with tab5:
            st.subheader("Mark Invoice as Paid")
            unpaid = fetch_data(
                """
                SELECT invoice_id, total_amount, status
                FROM invoices
                WHERE status = 'unpaid'
                ORDER BY invoice_id DESC;
                """
            )
            if unpaid.empty:
                st.info("No unpaid invoices found.")
                return

            with st.form("pay_invoice_form"):
                invoice_id = st.selectbox(
                   "Unpaid invoice",
                    unpaid["invoice_id"].tolist(),
                    format_func=lambda x: f"Invoice #{x} | {float(unpaid.loc[unpaid['invoice_id'] == x, 'total_amount'].iloc[0]):,.0f} VND",
                )
                payment_method = st.selectbox("Payment method", ["cash", "card", "bank_transfer", "e_wallet"])
                submitted = st.form_submit_button("Confirm Payment")

            if submitted:
                ok = call_procedure(
                    "sp_pay_invoice",
                    [int(invoice_id), payment_method],
                    "Invoice marked as paid successfully.",
                )
                if ok:
                    st.rerun()

        with tab6:
            st.subheader("Cancel Invoice")

            cancellable = fetch_data(
                """
                SELECT i.invoice_id,
                       i.invoice_datetime,
                       c.customer_name,
                       t.table_number,
                       i.total_amount,
                       i.status
                FROM invoices i
                JOIN customers c ON i.customer_id = c.customer_id
                JOIN restaurant_tables t ON i.table_id = t.table_id
                WHERE i.status = 'unpaid'
                ORDER BY i.invoice_datetime DESC, i.invoice_id DESC;
                """
            )

            if cancellable.empty:
                st.info("No unpaid invoices available for cancellation.")
                return

            with st.form("cancel_invoice_form"):
                invoice_id = st.selectbox(
                    "Unpaid invoice",
                    cancellable["invoice_id"].tolist(),
                    format_func=lambda x: (
                        f"Invoice #{x} | "
                        f"{cancellable.loc[cancellable['invoice_id'] == x, 'customer_name'].iloc[0]} | "
                        f"Table {cancellable.loc[cancellable['invoice_id'] == x, 'table_number'].iloc[0]} | "
                        f"{float(cancellable.loc[cancellable['invoice_id'] == x, 'total_amount'].iloc[0]):,.0f} VND"
                    ),
                )

                st.warning("This action will change the invoice status to cancelled.")
                submitted = st.form_submit_button("Cancel Invoice")

            if submitted:
                ok = cancel_invoice(invoice_id)
                if ok:
                    st.rerun()