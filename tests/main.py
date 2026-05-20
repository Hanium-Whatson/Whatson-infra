import json

from check import DynamoDBChecker
from crawl import GeekNewsCrawler
from sqs import SQSQueue
from store import S3Store


def handler(event, context):
    crawler = GeekNewsCrawler()
    store = S3Store()
    checker = DynamoDBChecker()
    queue = SQSQueue()

    titles = crawler.crawl()
    print(json.dumps({"step": "crawl", "count": len(titles), "titles": titles}, ensure_ascii=False))

    s3_uri = store.save(titles)
    print(json.dumps({"step": "s3", "s3_uri": s3_uri}, ensure_ascii=False))

    dynamodb_results = checker.check_and_insert(titles)
    print(
        json.dumps(
            {
                "step": "dynamodb",
                "results": dynamodb_results,
            },
            ensure_ascii=False,
            default=str,
        )
    )

    received_messages = queue.send_titles_and_print_received(titles)

    return {
        "statusCode": 200,
        "body": json.dumps(
            {
                "title_count": len(titles),
                "s3_uri": s3_uri,
                "dynamodb": dynamodb_results,
                "sqs_received": received_messages,
            },
            ensure_ascii=False,
            default=str,
        ),
    }


if __name__ == "__main__":
    print(json.dumps(handler({}, None), ensure_ascii=False, indent=2, default=str))
