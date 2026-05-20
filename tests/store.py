import json
import os
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

import boto3


class S3Store:
    def __init__(self):
        self._load_env()
        self._bucket = self._required_env("DATA_LAKE_BUCKET")
        self._region = os.getenv("AWS_REGION")
        self._raw_prefix = os.getenv("RAW_PREFIX").strip("/")
        self._job_stage = os.getenv("JOB_STAGE")
        self._s3 = boto3.client("s3", region_name=self._region)

    def save(self, titles: list[str]) -> str:
        now = datetime.now(UTC)
        key = self._build_key(now)
        body = self._build_body(titles, now)

        self._s3.put_object(
            Bucket=self._bucket,
            Key=key,
            Body=json.dumps(body, ensure_ascii=False, indent=2).encode("utf-8"),
            ContentType="application/json; charset=utf-8",
        )

        return f"s3://{self._bucket}/{key}"

    def _load_env(self) -> None:
        dotenv_path = self._find_dotenv_file()
        if not dotenv_path:
            return

        for line in dotenv_path.read_text(encoding="utf-8").splitlines():
            stripped = line.strip()
            if not stripped or stripped.startswith("#") or "=" not in stripped:
                continue

            key, value = stripped.split("=", 1)
            key = key.strip()
            value = value.strip().strip('"').strip("'")

            if key and key not in os.environ:
                os.environ[key] = value

    def _find_dotenv_file(self) -> Path | None:
        explicit_path = os.getenv("DOTENV_PATH")
        if explicit_path:
            path = Path(explicit_path)
            return path if path.exists() else None

        candidates = [
            Path.cwd() / ".env",
            Path(__file__).resolve().parent / ".env",
            Path(__file__).resolve().parent.parent / ".env",
        ]

        for candidate in candidates:
            if candidate.exists():
                return candidate

        return None

    def _required_env(self, name: str) -> str:
        value = os.getenv(name)
        if not value:
            raise RuntimeError(f"Missing required environment variable: {name}")
        return value

    def _build_key(self, now: datetime) -> str:
        timestamp = now.strftime("%Y%m%dT%H%M%SZ")
        date_path = now.strftime("%Y/%m/%d")
        return f"{self._raw_prefix}/geeknews/{date_path}/titles-{timestamp}.json"

    def _build_body(self, titles: list[str], now: datetime) -> dict[str, Any]:
        return {
            "source": "https://news.hada.io/",
            "job_stage": self._job_stage,
            "created_at": now.isoformat(),
            "count": len(titles),
            "titles": titles,
        }
