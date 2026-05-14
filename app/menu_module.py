import streamlit as st
from db_config import fetch_data, execute_query


def show_menu_module():
    st.title("Menu Management")

    tab1, tab2, tab3, tab4 = st.tabs(["View Menu", "Add Dish", "Update Price", "Update Availability"])

    with tab1:
        st.subheader("Menu Items")
        category = st.text_input("Filter by category")
        if category:
            df = fetch_data(
                """
                SELECT dish_id,
                       dish_name,
                       category,
                       price,
                       CASE WHEN availability = TRUE THEN 'available' ELSE 'unavailable' END AS availability
                FROM menu_items
                WHERE category LIKE %s
                ORDER BY category, dish_name;
                """,
                (f"%{category}%",),
            )
        else:
            df = fetch_data(
                """
                SELECT dish_id,
                       dish_name,
                       category,
                       price,
                       CASE WHEN availability = TRUE THEN 'available' ELSE 'unavailable' END AS availability
                FROM menu_items
                ORDER BY category, dish_name;
                """
            )
        st.dataframe(df, use_container_width=True)

    with tab2:
        st.subheader("Add New Dish")
        with st.form("add_dish_form"):
            dish_name = st.text_input("Dish name")
            category = st.text_input("Category")
            price = st.number_input("Price", min_value=0.0, step=1000.0)
            availability_label = st.selectbox("Availability", ["available", "unavailable"])
            submitted = st.form_submit_button("Add Dish")

        if submitted:
            if not dish_name or not category:
                st.warning("Dish name and category are required.")
            else:
                availability = availability_label == "available"
                execute_query(
                    """
                    INSERT INTO menu_items (dish_name, category, price, availability)
                    VALUES (%s, %s, %s, %s);
                    """,
                    (dish_name, category, price, availability),
                    "Dish added successfully.",
                )
                st.rerun()

    with tab3:
        st.subheader("Update Dish Price")
        dishes = fetch_data("SELECT dish_id, dish_name, price FROM menu_items ORDER BY dish_id;")
        if dishes.empty:
            st.info("No menu items found.")
            return
        dish_id = st.selectbox(
            "Select dish",
            dishes["dish_id"].tolist(),
            format_func=lambda x: f"{x} - {dishes.loc[dishes['dish_id'] == x, 'dish_name'].iloc[0]}",
            key="price_dish",
        )
        current_price = float(dishes.loc[dishes["dish_id"] == dish_id, "price"].iloc[0])
        new_price = st.number_input("New price", min_value=0.0, step=1000.0, value=current_price)

        if st.button("Update Price"):
            execute_query(
                """
                UPDATE menu_items
                SET price = %s
                WHERE dish_id = %s;
                """,
                (new_price, int(dish_id)),
                "Dish price updated successfully.",
            )
            st.rerun()

    with tab4:
        st.subheader("Update Availability")
        dishes = fetch_data(
            """
            SELECT dish_id,
                   dish_name,
                   CASE WHEN availability = TRUE THEN 'available' ELSE 'unavailable' END AS availability
            FROM menu_items
            ORDER BY dish_id;
            """
        )
        if dishes.empty:
            st.info("No menu items found.")
            return
        dish_id = st.selectbox(
            "Select dish",
            dishes["dish_id"].tolist(),
            format_func=lambda x: f"{x} - {dishes.loc[dishes['dish_id'] == x, 'dish_name'].iloc[0]}",
            key="availability_dish",
        )
        availability_label = st.selectbox("Availability", ["available", "unavailable"])

        if st.button("Update Availability"):
            availability = availability_label == "available"
            execute_query(
                """
                UPDATE menu_items
                SET availability = %s
                WHERE dish_id = %s;
                """,
                (availability, int(dish_id)),
                "Dish availability updated successfully.",
            )
            st.rerun()
