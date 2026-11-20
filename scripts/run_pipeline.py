
import os
from pathlib import Path

import psycopg


PROJECT_DIR = Path(__file__).resolve().parents[1]
SQL_DIR = PROJECT_DIR / "sql"


def execute_sql_file(conn, file_name):
    file_path = SQL_DIR / file_name

    print(f"\nВыполнение {file_name}...")

    sql_script = file_path.read_text(encoding="utf-8")

    with conn.cursor() as cursor:
        cursor.execute(sql_script, prepare=False)

    print(f"Работа {file_name} завершена успешно")


def main():
    database_url = os.getenv("DATABASE_URL")

    if not database_url:
        raise ValueError("DATABASE_URL is not set")

    conninfo = database_url.replace(
        "postgresql+psycopg://",
        "postgresql://",
        1
    )

    print("Starting Olist ETL pipeline")

    # загружаем csv 
    import subprocess
    import sys

    subprocess.run(
        [sys.executable, str(PROJECT_DIR / "scripts" / "load_data.py")],
        check=True
    )

    # raw в staging
    with psycopg.connect(conninfo) as conn:
        
        execute_sql_file(conn, "3_staging.sql")
        execute_sql_file(conn, "4_quality_check.sql")
        execute_sql_file(conn, "5_dwh.sql")
        execute_sql_file(conn, "6_mart.sql")

    print("\nПостроение Olist ETL завершено")


if __name__ == "__main__":
    main()
