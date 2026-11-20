
import os
from pathlib import Path

import psycopg
from psycopg import sql
from dotenv import load_dotenv


PROJECT_DIR = Path(__file__).resolve().parents[1]
DATA_DIR = PROJECT_DIR / "data"

FILES = {
    "orders": "olist_orders_dataset.csv",
    "customers": "olist_customers_dataset.csv",
    "order_items": "olist_order_items_dataset.csv",
    "payments": "olist_order_payments_dataset.csv",
    "products": "olist_products_dataset.csv",
    "sellers": "olist_sellers_dataset.csv",
    "reviews": "olist_order_reviews_dataset.csv",
    "geolocation": "olist_geolocation_dataset.csv",
    "product_category_name_translation": (
        "product_category_name_translation.csv"
    ),
}


def load_csv(cursor, table_name, file_path):
    copy_query = sql.SQL(
        """
        COPY {}.{} 
        FROM STDIN
        WITH (FORMAT CSV, HEADER TRUE, ENCODING 'UTF8')
        """
    ).format(
        sql.Identifier("raw"),
        sql.Identifier(table_name)
    )

    with file_path.open("rb") as file:
        with cursor.copy(copy_query) as copy:
            while chunk := file.read(1024 * 1024):
                copy.write(chunk)


def main():
    load_dotenv(PROJECT_DIR / ".env")

    database_url = os.getenv("DATABASE_URL")

    if not database_url:
        raise ValueError("DATABASE_URL is not set in .env")

    conninfo = database_url.replace(
        "postgresql+psycopg://",
        "postgresql://",
        1
    )

    for file_name in FILES.values():
        file_path = DATA_DIR / file_name

        if not file_path.exists():
            raise FileNotFoundError(
                f"File not found: {file_path}"
            )

    with psycopg.connect(conninfo) as conn:
        with conn.cursor() as cursor:

            cursor.execute(
                """
                TRUNCATE TABLE
                    raw.orders,
                    raw.customers,
                    raw.order_items,
                    raw.payments,
                    raw.products,
                    raw.sellers,
                    raw.reviews,
                    raw.geolocation,
                    raw.product_category_name_translation
                """
            )

            for table_name, file_name in FILES.items():
                file_path = DATA_DIR / file_name

                load_csv(cursor, table_name, file_path)

                cursor.execute(
                    sql.SQL("SELECT COUNT(*) FROM {}.{}").format(
                        sql.Identifier("raw"),
                        sql.Identifier(table_name)
                    )
                )

                row_count = cursor.fetchone()[0]

                print(
                    f"Loaded raw.{table_name}: "
                    f"{row_count:,} rows"
                )

    print("\nЗагрузка RAW данных прошла успешно")


if __name__ == "__main__":
    main()
