# Olist: хранилище данных и ETL pipeline

## Описание проекта

Проект на открытом датасете [Brazilian E-Commerce (Olist)](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce).

Основной фокус — построение хранилища данных и ETL pipeline.

В проекте:
- загрузка CSV в PostgreSQL;
- преобразование данных с помощью SQL;
- проверки качества данных;
- хранилище по схеме «звезда»;
- витрины для аналитики;
- автоматизация ETL на Python;
- запуск через Docker Compose.

## Используемые технологии

- PostgreSQL
- SQL
- Python
- Psycopg 3
- Docker, Docker Compose
- Git

## Слои данных

```text
CSV -> raw -> staging -> dwh -> mart
```

- `raw` — исходные данные из CSV, все столбцы TEXT;
- `staging` — приведение типов и подготовка данных;
- `dwh` — факты и измерения;
- `mart` — витрины для аналитики.

## Модель данных

![Star Schema](images/star_schema.png)

### Fact tables

- `fact_orders` — один заказ: статус, даты, суммы товаров и доставки, оплата, оценка, срок доставки и опоздание;
- `fact_order_items` — одна позиция заказа.

### Dimension tables

- `dim_customers`
- `dim_products` — с английским названием категории;
- `dim_sellers`
- `dim_date` — календарь.

*покупатель — `customer_unique_id`, потому что `customer_id` в Olist свой у каждого заказа*

*товары, платежи и отзывы агрегируются до соединения с заказами, чтобы суммы не задваивались*

## Проверка качества данных

В `sql/4_quality_check.sql` проверяются:

- дубликаты и NULL;
- некорректные даты;
- отрицательные суммы и значения;
- заказы без товаров;
- нарушения ссылочной целостности;
- некорректные платежи и оценки.

Дополнительно проверяется совпадение количества заказов и выручки между слоями, а также витрин с DWH.

Проверки выводят проблемные записи, но не останавливают pipeline автоматически.

## Витрины

| Витрина | Одна строка | Назначение |
|---|---|---|
| `daily_sales` | день | динамика продаж |
| `daily_category_sales` | день × категория | продажи по категориям |

*обе витрины — materialized views*

## ETL pipeline

Основной скрипт — `scripts/run_pipeline.py`.

Порядок выполнения:

1. `load_data.py` загружает CSV в RAW через COPY;
2. `3_staging.sql` преобразует данные;
3. `4_quality_check.sql` выполняет проверки;
4. `5_dwh.sql` создаёт факты и измерения;
5. `6_mart.sql` создаёт витрины.

SQL-скрипты выполняются последовательно через Python и Psycopg.

При ошибке pipeline останавливается.

## Docker

В Docker Compose два сервиса:

- `db` — PostgreSQL 16;
- `pipeline` — Python с ETL-скриптами.

При первом запуске PostgreSQL создаёт базу и RAW-таблицы. После проверки готовности базы запускается pipeline.

Данные PostgreSQL сохраняются в Docker volume.

## Структура проекта

```text
olist_dwh/
├── data/
├── images/
│   ├── dashboard.png
│   └── star_schema.png
├── notebooks/
├── scripts/
│   ├── load_data.py
│   └── run_pipeline.py
├── sql/
│   ├── 1_create_database.sql
│   ├── 2_raw.sql
│   ├── 3_staging.sql
│   ├── 4_quality_check.sql
│   ├── 5_dwh.sql
│   └── 6_mart.sql
├── Dockerfile
├── docker-compose.yml
├── requirements.txt
├── requirements-docker.txt
├── .gitignore
└── README.md
```

## Как запустить

1. Клонировать репозиторий.
2. Создать файл `.env` и указать параметры подключения к PostgreSQL.
3. Из корневой папки проекта выполнить:

```bash
docker compose up --build
```

После запуска PostgreSQL автоматически выполняется ETL pipeline.

При успешном выполнении pipeline завершается с кодом `0`.

Остановить контейнеры:

```bash
docker compose down
```

Данные базы сохраняются в Docker volume.