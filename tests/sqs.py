import json
import os
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

import boto3


class SQSQueue:
    def __init__(self):
        self._load_env()
        self._region = os.getenv("AWS_REGION") or os.getenv("AWS_DEFAULT_REGION")
        self._queue_url = self._resolve_queue_url()
        self._job_stage = os.getenv("JOB_STAGE", "crawl")
        self._source = os.getenv("DYNAMODB_SOURCE_VALUE", "geeknews")
        self._sqs = boto3.client("sqs", region_name=self._region)

    def send_titles(self, titles: list[str]) -> str:
        body = self._build_message_body(titles)
        params: dict[str, Any] = {
            "QueueUrl": self._queue_url,
            "MessageBody": json.dumps(body, ensure_ascii=False),
        }

        if self._queue_url.endswith(".fifo"):
            params["MessageGroupId"] = self._source
            params["MessageDeduplicationId"] = f"{self._source}-{int(datetime.now(UTC).timestamp())}"

        response = self._sqs.send_message(**params)
        return response["MessageId"]

    def receive_and_print(self) -> list[dict[str, Any]]:
        response = self._sqs.receive_message(
            QueueUrl=self._queue_url,
            MaxNumberOfMessages=1,
            WaitTimeSeconds=5,
            VisibilityTimeout=900,
        )

        messages = response.get("Messages", [])
        parsed_messages = []

        for message in messages:
            parsed_body = json.loads(message["Body"])
            parsed_messages.append(parsed_body)
            print(json.dumps(parsed_body, ensure_ascii=False, indent=2))

            self._sqs.delete_message(
                QueueUrl=self._queue_url,
                ReceiptHandle=message["ReceiptHandle"],
            )

        return parsed_messages

    def send_titles_and_print_received(self, titles: list[str]) -> list[dict[str, Any]]:
        message_id = self.send_titles(titles)
        print(f"sent_message_id={message_id}")
        return self.receive_and_print()

    def _build_message_body(self, titles: list[str]) -> dict[str, Any]:
        normalized_titles = [self._normalize_title(title) for title in titles]
        normalized_titles = [title for title in normalized_titles if title]

        return {
            "source": self._source,
            "job_stage": self._job_stage,
            "created_at": datetime.now(UTC).isoformat(),
            "count": len(normalized_titles),
            "titles": normalized_titles,
        }

    def _resolve_queue_url(self) -> str:
        queue_url = os.getenv("SQS_QUEUE_URL") or os.getenv("DLQ_QUEUE_URL")
        if queue_url:
            return queue_url

        queue_name = os.getenv("SQS_QUEUE_NAME") or os.getenv("DLQ_QUEUE_NAME")
        if not queue_name:
            raise RuntimeError(
                "Missing SQS queue config. Set SQS_QUEUE_URL, DLQ_QUEUE_URL, "
                "SQS_QUEUE_NAME, or DLQ_QUEUE_NAME."
            )

        sqs = boto3.client("sqs", region_name=self._region)
        return sqs.get_queue_url(QueueName=queue_name)["QueueUrl"]

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
