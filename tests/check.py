import json
import os
from datetime import UTC, datetime
from decimal import Decimal
from pathlib import Path
from typing import Any

import boto3
from botocore.exceptions import ClientError


class DynamoDBChecker:
    def __init__(self):
        self._load_env()
        self._table_name = self._required_env("DYNAMODB_TABLE_NAME")
        self._region = os.getenv("AWS_REGION")
        self._source = os.getenv("DYNAMODB_SOURCE_VALUE")
        self._client = boto3.client("dynamodb", region_name=self._region)
        self._resource = boto3.resource("dynamodb", region_name=self._region)
        self._table = self._resource.Table(self._table_name)
        self._key_schema = self._describe_key_schema()

    def check_and_insert(self, titles: list[str]) -> list[dict[str, Any]]:
        results = []

        for title in titles:
            normalized_title = self._normalize_title(title)
            if not normalized_title:
                continue

            key = self._build_key(normalized_title)
            item = self._build_item(key, normalized_title)
            inserted = self._put_if_absent(key, item)

            results.append(
                {
                    "title": normalized_title,
                    "exists": not inserted,
                    "inserted": inserted,
                    "key": key,
                }
            )

        return results

    def print(self) -> None:
        for item in self._scan_all_items():
            print(json.dumps(self._json_safe(item), ensure_ascii=False))

    def _put_if_absent(self, key: dict[str, Any], item: dict[str, Any]) -> bool:
        condition = " AND ".join(f"attribute_not_exists(#{name})" for name in key)
        expression_names = {f"#{name}": name for name in key}

        try:
            self._table.put_item(
                Item=item,
                ConditionExpression=condition,
                ExpressionAttributeNames=expression_names,
            )
            return True
        except ClientError as exc:
            error_code = exc.response.get("Error", {}).get("Code")
            if error_code == "ConditionalCheckFailedException":
                return False
            raise

    def _describe_key_schema(self) -> list[dict[str, str]]:
        table = self._client.describe_table(TableName=self._table_name)["Table"]
        return table["KeySchema"]

    def _build_key(self, title: str) -> dict[str, Any]:
        key = {}

        for key_part in self._key_schema:
            key_name = key_part["AttributeName"]
            key_type = key_part["KeyType"]

            if key_type == "HASH":
                key[key_name] = title
            elif key_type == "RANGE":
                key[key_name] = self._source

        return key

    def _build_item(self, key: dict[str, Any], title: str) -> dict[str, Any]:
        now = datetime.now(UTC).isoformat()
        return {
            **key,
            "title": title,
            "source": self._source,
            "created_at": now,
            "updated_at": now,
        }

    def _scan_all_items(self) -> list[dict[str, Any]]:
        items = []
        scan_kwargs: dict[str, Any] = {}

        while True:
            response = self._table.scan(**scan_kwargs)
            items.extend(response.get("Items", []))

            last_key = response.get("LastEvaluatedKey")
            if not last_key:
                return items

            scan_kwargs["ExclusiveStartKey"] = last_key

    def _normalize_title(self, title: str) -> str:
        return " ".join(title.split())

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

    def _json_safe(self, value: Any) -> Any:
        if isinstance(value, list):
            return [self._json_safe(item) for item in value]
        if isinstance(value, dict):
            return {key: self._json_safe(item) for key, item in value.items()}
        if isinstance(value, Decimal):
            return int(value) if value % 1 == 0 else float(value)
        return value
