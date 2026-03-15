import sqlite3
from contextlib import contextmanager
from pathlib import Path
from threading import Lock

BASE_DIR = Path(__file__).resolve().parents[1]
DB_PATH = BASE_DIR / "data" / "cloud_cost_advisor.db"

_db_lock = Lock()


def init_db() -> None:
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    with get_connection() as conn:
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS workloads (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                owner_team TEXT NOT NULL,
                provider TEXT NOT NULL,
                monthly_cost_usd REAL NOT NULL,
                cpu_utilization_pct REAL NOT NULL,
                memory_utilization_pct REAL NOT NULL,
                criticality TEXT NOT NULL,
                auto_shutdown_enabled INTEGER NOT NULL,
                created_at TEXT NOT NULL DEFAULT (datetime('now')),
                updated_at TEXT NOT NULL DEFAULT (datetime('now'))
            )
            """
        )
        conn.execute(
            """
            CREATE TRIGGER IF NOT EXISTS workloads_updated_at
            AFTER UPDATE ON workloads
            BEGIN
                UPDATE workloads
                SET updated_at = datetime('now')
                WHERE id = NEW.id;
            END;
            """
        )


@contextmanager
def get_connection() -> sqlite3.Connection:
    with _db_lock:
        conn = sqlite3.connect(DB_PATH)
        conn.row_factory = sqlite3.Row
        try:
            yield conn
            conn.commit()
        finally:
            conn.close()
