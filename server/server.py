from flask import Flask, jsonify, request
from flask_cors import CORS
import sqlite3
import os

app = Flask(__name__)
CORS(app)

DB_PATH = "groups.db"

def get_conn():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row  # dict-like rows
    return conn

def init_db():
    # Create table if it doesn't exist and seed initial data
    with get_conn() as conn:
        conn.execute("""
            CREATE TABLE IF NOT EXISTS groups (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL UNIQUE
            );
        """)
        # Seed some default groups
        conn.executemany(
            "INSERT OR IGNORE INTO groups (name) VALUES (?);",
            [("football haifa",), ("basketball akko",)]
        )

@app.route('/groups', methods=['GET'])
def get_groups():
    with get_conn() as conn:
        rows = conn.execute("SELECT name FROM groups ORDER BY name;").fetchall()
    groups = [row["name"] for row in rows]
    return jsonify(groups), 200

# Optional: add new groups via POST
@app.route('/groups', methods=['POST'])
def add_group():
    data = request.get_json(silent=True) or {}
    name = (data.get("name") or "").strip()
    if not name:
        return jsonify({"error": "Missing 'name'"}), 400

    try:
        with get_conn() as conn:
            conn.execute("INSERT INTO groups (name) VALUES (?);", (name,))
        return jsonify({"ok": True, "name": name}), 201
    except sqlite3.IntegrityError:
        return jsonify({"error": "Group already exists"}), 409

if __name__ == '__main__':
    init_db()
    app.run(host='0.0.0.0', port=5000, debug=True)