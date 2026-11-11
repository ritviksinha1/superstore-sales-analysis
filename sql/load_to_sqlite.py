"""Load data/superstore.csv into a local SQLite database (superstore.db).

Run from the project root:
    python sql/load_to_sqlite.py

Then open superstore.db with any SQLite client (DB Browser for SQLite, VS Code
SQLite extension, or the sqlite3 command line) and run the queries in
sql/queries.sql.
"""
import sqlite3

import pandas as pd

CSV_PATH = "data/superstore.csv"
DB_PATH = "superstore.db"

df = pd.read_csv(CSV_PATH, encoding="latin-1")

# snake_case column names are easier to use in SQL (e.g. "Sub-Category" -> sub_category)
df.columns = [c.strip().lower().replace(" ", "_").replace("-", "_") for c in df.columns]

# store dates as ISO text (YYYY-MM-DD) so SQLite date functions work
for col in ["order_date", "ship_date"]:
    df[col] = pd.to_datetime(df[col], format="%m/%d/%Y").dt.strftime("%Y-%m-%d")

with sqlite3.connect(DB_PATH) as conn:
    df.to_sql("orders", conn, if_exists="replace", index=False)
    rows = conn.execute("SELECT COUNT(*) FROM orders").fetchone()[0]

print(f"Loaded {rows:,} rows into table 'orders' in {DB_PATH}")
