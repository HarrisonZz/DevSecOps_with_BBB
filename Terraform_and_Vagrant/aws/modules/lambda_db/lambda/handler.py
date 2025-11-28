import os
import re
import time
import requests
import psycopg
from datetime import datetime, timedelta, timezone
import socket

def handler(event, context):

    conn = psycopg.connect(
        host=os.environ["DB_HOST"],
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASSWORD"],
        dbname=os.environ["DB_NAME"],
        connect_timeout=5
    )
    with conn.cursor() as cur:
        
        # for slef test Aurora content
        # cur.execute("SELECT * FROM web_app_logs ORDER BY timestamp DESC LIMIT 5;")
        # rows = cur.fetchall()
        # for r in rows:
        #     print(r)
        # return
        
        end_time = datetime.now(timezone.utc)
        start_time = end_time - timedelta(minutes=5)

        query = {
            "query": {
                "bool": {
                    "must": [
                        {
                            "range": {
                                "@timestamp": {
                                    "gte": start_time.isoformat(),
                                    "lte": end_time.isoformat()
                                }
                            }
                        },
                        {
                            "match": {
                                "message": "duration"
                            }
                        }
                    ]
                }
            },
            "sort": [
                {
                    "@timestamp": {
                        "order": "asc"
                    }
                }
            ],
            "size": 1000,
            "_source": ["@timestamp", "log_level", "message", "path"]
        }

        resp = requests.get(
            "https://www.hrscyj.uk/es/app-logs-*/_search",
            headers={"Content-Type": "application/json"},
            json=query,
            timeout=30,
            verify=False  # 因為 Cloudflare Tunnel + 自簽證書
        )

        print(resp.json())
        hits = resp.json().get("hits", {}).get("hits", [])

        cur.execute("""
            CREATE TABLE IF NOT EXISTS web_app_logs (
                id SERIAL PRIMARY KEY,                -- 自動流水號
                timestamp TIMESTAMPTZ NOT NULL,       -- 來自 ES 的 log 時間（UTC）
                level VARCHAR(16),                    -- log level，例如 info / warn / error
                pod_name VARCHAR(64),                     
                duration_ms TEXT,                         -- 原始 log 訊息
                Cache       TEXT,
                created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP  -- Lambda 寫入時間
            );
        """)    
        
        inserted = 0
        for hit in hits:
            src = hit["_source"]
            msg = src.get("message")

            duration_match = re.search(r"duration=([\d\.]+)ms", msg)
            cache_match = re.search(r"cache=(\w+)", msg)

            duration_ms = duration_match.group(1) if duration_match else None
            cache = cache_match.group(1) if cache_match else None

            cur.execute("""
                INSERT INTO web_app_logs (timestamp, level, pod_name, duration_ms, cache)
                VALUES (%s, %s, %s, %s, %s)
            """, (
                src.get("@timestamp"),
                src.get("log_level"),
                src.get("path"),
                duration_ms,
                cache
            ))
            inserted += 1

        conn.commit()

    conn.close()

    print(f"[INFO] Inserted {inserted} records into Aurora")
    return {"status": "ok", "inserted": inserted}