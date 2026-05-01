import json
import logging
import os


logger = logging.getLogger()
logger.setLevel(logging.INFO)


def handler(event, context):
    payload = {
        "function_name": context.function_name if context else "local",
        "event": event,
        "environment": {
            "DATA_LAKE_BUCKET": os.getenv("DATA_LAKE_BUCKET", ""),
            "RAW_PREFIX": os.getenv("RAW_PREFIX", ""),
            "PROCESSED_PREFIX": os.getenv("PROCESSED_PREFIX", ""),
            "DATASET_PREFIX": os.getenv("DATASET_PREFIX", ""),
            "ARTIFACT_PREFIX": os.getenv("ARTIFACT_PREFIX", ""),
            "REDIS_ENDPOINT": os.getenv("REDIS_ENDPOINT", ""),
            "JOB_STAGE": os.getenv("JOB_STAGE", ""),
        },
    }
    logger.info(json.dumps(payload))
    return {
        "statusCode": 200,
        "body": json.dumps(
            {
                "message": "Placeholder training pipeline lambda executed.",
                "job_stage": os.getenv("JOB_STAGE", "unknown"),
            }
        ),
    }
